# frozen_string_literal: true

# Redmine MCP plugin
#
# Copyright (C) 2026 man smart-home
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

require File.expand_path('redmine_checklists/support', __dir__)

module RedmineMcp
  module Extensions
    module RedmineChecklists
      extend RedmineMcp::ExtensionApi

      plugin_id :redmine_checklists

      H = RedmineMcp::Core::Helpers
      S = Support
      N = RedmineMcp::SchemaNormalizer
      ISSUE_ID = H::ISSUE_ID_SCHEMA.merge(
        description: 'Numeric issue ID. Call redmine_search_issues or redmine_list_issues when unknown.',
        examples: [1]
      ).freeze
      CHECKLIST_ID = {
        type: 'integer',
        minimum: 1,
        description: 'Checklist item ID from redmine_checklists_list_issue_checklists.',
        examples: [1]
      }.freeze
      SUBJECT = {
        type: 'string',
        minLength: 1,
        maxLength: 1000,
        description: 'Checklist item text.'
      }.freeze
      IS_DONE = {
        type: 'boolean',
        description: 'true marks the item done; false marks it undone.'
      }.freeze
      IS_SECTION = {
        type: 'boolean',
        description: 'true marks the item as a section header. Section headers are excluded from the done count.'
      }.freeze
      POSITION = {
        type: 'integer',
        minimum: 1,
        description: '1-based position within the issue checklist. Omit on create to append.'
      }.freeze
      DATETIME = {
        oneOf: [
          {type: 'string', format: 'date-time'},
          {type: 'null'},
        ],
        description: 'Timestamp in ISO-8601, or null when unset.'
      }.freeze
      ITEM_SCHEMA = {
        type: 'object',
        additionalProperties: false,
        properties: {
          id: {type: 'integer', minimum: 1},
          issue_id: {type: 'integer', minimum: 1},
          subject: {type: 'string'},
          is_done: {type: 'boolean'},
          is_section: {type: 'boolean'},
          position: {type: 'integer'},
          created_at: DATETIME,
          updated_at: DATETIME
        },
        required: %w[id issue_id subject is_done is_section position created_at updated_at]
      }.freeze
      SUMMARY_SCHEMA = {
        type: 'object',
        additionalProperties: false,
        properties: {
          total: {type: 'integer', minimum: 0, description: 'Checklist items excluding section headers.'},
          done: {type: 'integer', minimum: 0, description: 'Done items excluding section headers.'}
        },
        required: %w[total done]
      }.freeze
      ITEM_OUTPUT = N.envelope_output(
        type: 'object',
        additionalProperties: false,
        properties: {
          issue_id: {type: 'integer', minimum: 1},
          checklist: ITEM_SCHEMA
        },
        required: %w[issue_id checklist]
      ).freeze
      LIST_OUTPUT = N.envelope_output(
        type: 'object',
        additionalProperties: false,
        properties: {
          issue_id: {type: 'integer', minimum: 1},
          summary: SUMMARY_SCHEMA,
          items: {type: 'array', items: ITEM_SCHEMA}
        },
        required: %w[issue_id summary items]
      ).freeze
      DELETED_OUTPUT = N.envelope_output(
        type: 'object',
        additionalProperties: false,
        properties: {
          deleted_checklist_id: {type: 'integer', minimum: 1},
          issue_id: {type: 'integer', minimum: 1}
        },
        required: %w[deleted_checklist_id issue_id]
      ).freeze
      SET_DONE_ANNOTATIONS = H::UPDATE_ANNOTATIONS.merge(idempotent_hint: true).freeze
      DELETE_CHECKLIST_ANNOTATIONS = H::DELETE_ANNOTATIONS.merge(idempotent_hint: false).freeze

      if mcp_extension_enabled?
        register_issue_tool(
          name: 'list_issue_checklists',
          title: 'List issue checklists',
          description: "Returns checklist items on one issue, ordered by position.\n\n" \
                       "Includes section headers. summary counts only non-section items and covers the whole checklist, not the page.\n" \
                       "Default limit 25, max 100.\nRequires view_checklists.",
          permission: :view_checklists,
          module_name: :issue_tracking,
          annotations: H::READ_ONLY_ANNOTATIONS,
          input_schema: {
            properties: {
              issue_id: ISSUE_ID
            }.merge(H::PAGINATION_INPUT),
            required: ['issue_id']
          },
          output_schema: LIST_OUTPUT
        ) do |issue, args, context|
          S.with_user(context[:user]) do
            limit = H.clamp_limit(args[:limit])
            offset = H.clamp_offset(args[:offset])
            scope = issue.checklists
            total = scope.count
            items = scope.offset(offset).limit(limit).map { |item| S.item_payload(item) }
            page = H.paginated_list(items, total_count: total, limit: limit, offset: offset)
            {
              ok: true,
              data: {issue_id: issue.id, summary: S.summary(issue), items: items},
              meta: page[:meta]
            }
          end
        end

        register_issue_tool(
          name: 'create_checklist',
          title: 'Create checklist item',
          description: "Adds one checklist item to an issue.\n\n" \
                       "Requires subject. is_done and is_section default to false. position defaults to the end.\n" \
                       "Returns the created item. Does not replace existing items.\n" \
                       "Requires edit_checklists. A repeated call adds another item.",
          permission: :edit_checklists,
          module_name: :issue_tracking,
          annotations: H::CREATE_ANNOTATIONS,
          input_schema: {
            properties: {
              issue_id: ISSUE_ID,
              subject: SUBJECT,
              is_done: IS_DONE,
              is_section: IS_SECTION,
              position: POSITION
            },
            required: %w[issue_id subject]
          },
          output_schema: ITEM_OUTPUT
        ) do |issue, args, context|
          blocked = guard_write!
          next blocked if blocked

          S.with_user(context[:user]) do
            item = S.create!(issue, args, context[:user])
            next item if item.is_a?(Hash) && item[:error]

            {issue_id: issue.id, checklist: S.item_payload(item)}
          end
        end

        register_tool_once(
          name: 'update_checklist',
          title: 'Update checklist item',
          description: "Updates one existing checklist item.\n\n" \
                       "Supply only fields that should change. Does not create or delete items.\n" \
                       "To toggle done without edit_checklists, use redmine_checklists_set_checklist_done.\n" \
                       "Optional expected_updated_at rejects a stale item with CONFLICT.\n" \
                       "Requires edit_checklists. Call redmine_checklists_list_issue_checklists when checklist_id is unknown.",
          permission: ->(user, _args, _project) { user.admin? || H.any_project_module_allows?(user, :edit_checklists, 'issue_tracking') },
          annotations: H::UPDATE_ANNOTATIONS.merge(idempotent_hint: true),
          input_schema: {
            properties: {
              checklist_id: CHECKLIST_ID,
              subject: SUBJECT,
              is_done: IS_DONE,
              is_section: IS_SECTION,
              position: POSITION,
              expected_updated_at: H::EXPECTED_UPDATED_AT_SCHEMA
            },
            required: ['checklist_id'],
            anyOf: [
              {required: ['subject']},
              {required: ['is_done']},
              {required: ['is_section']},
              {required: ['position']},
            ]
          },
          output_schema: ITEM_OUTPUT,
          handler: lambda { |args, context|
            blocked = RedmineChecklists.guard_write!
            return blocked if blocked

            user = context[:user]
            S.with_user(user) do
              item = S.find_visible_item(user, args[:checklist_id])
              return missing_checklist(args[:checklist_id]) unless item
              return H.error_result(:error_mcp_permission_denied) unless user.allowed_to?(:edit_checklists, item.issue.project)

              stale = S.stale_result(item, args[:expected_updated_at])
              return stale if stale

              updated = S.update!(item, args, user)
              return updated if updated.is_a?(Hash) && updated[:error]

              {issue_id: updated.issue_id, checklist: S.item_payload(updated)}
            end
          }
        )

        register_tool_once(
          name: 'set_checklist_done',
          title: 'Set checklist item done',
          description: "Marks one checklist item done or not done.\n\n" \
                       "Does not change subject, section, or position.\n" \
                       "A repeated call with the same is_done does not add another journal.\n" \
                       "Optional expected_updated_at rejects a stale item with CONFLICT.\n" \
                       "Requires done_checklists. Call redmine_checklists_list_issue_checklists when checklist_id is unknown.",
          permission: ->(user, _args, _project) { user.admin? || H.any_project_module_allows?(user, :done_checklists, 'issue_tracking') },
          annotations: SET_DONE_ANNOTATIONS,
          input_schema: {
            properties: {
              checklist_id: CHECKLIST_ID,
              is_done: IS_DONE,
              expected_updated_at: H::EXPECTED_UPDATED_AT_SCHEMA
            },
            required: %w[checklist_id is_done]
          },
          output_schema: ITEM_OUTPUT,
          handler: lambda { |args, context|
            blocked = RedmineChecklists.guard_write!
            return blocked if blocked

            user = context[:user]
            S.with_user(user) do
              item = S.find_visible_item(user, args[:checklist_id])
              return missing_checklist(args[:checklist_id]) unless item
              return H.error_result(:error_mcp_permission_denied) unless user.allowed_to?(:done_checklists, item.issue.project)

              stale = S.stale_result(item, args[:expected_updated_at])
              return stale if stale

              updated = S.set_done!(item, args[:is_done] == true, user)
              return updated if updated.is_a?(Hash) && updated[:error]

              {issue_id: updated.issue_id, checklist: S.item_payload(updated)}
            end
          }
        )

        register_tool_once(
          name: 'delete_checklist',
          title: 'Delete checklist item',
          description: "Permanently deletes one checklist item.\n\n" \
                       "Requires confirm_delete=true. This cannot be undone.\n" \
                       "Requires edit_checklists. Call redmine_checklists_list_issue_checklists when checklist_id is unknown.",
          permission: ->(user, _args, _project) { user.admin? || H.any_project_module_allows?(user, :edit_checklists, 'issue_tracking') },
          annotations: DELETE_CHECKLIST_ANNOTATIONS,
          input_schema: {
            properties: {
              checklist_id: CHECKLIST_ID,
              confirm_delete: {
                type: 'boolean',
                const: true,
                description: 'Must be true. Deletes the checklist item permanently.'
              }
            },
            required: %w[checklist_id confirm_delete]
          },
          output_schema: DELETED_OUTPUT,
          handler: lambda { |args, context|
            blocked = RedmineChecklists.guard_write!
            return blocked if blocked

            user = context[:user]
            S.with_user(user) do
              item = S.find_visible_item(user, args[:checklist_id])
              return missing_checklist(args[:checklist_id]) unless item
              return H.error_result(:error_mcp_permission_denied) unless user.allowed_to?(:edit_checklists, item.issue.project)
              unless args[:confirm_delete] == true
                return H.mcp_error(
                  code: 'INVALID_STATE',
                  message: 'Pass confirm_delete=true to delete the checklist item.',
                  field: 'confirm_delete'
                )
              end

              S.delete!(item, user)
            end
          }
        )
      end

      def self.missing_checklist(checklist_id)
        H.mcp_error(
          code: 'NOT_FOUND',
          message: "No visible checklist item with id #{checklist_id}. Call redmine_checklists_list_issue_checklists for ids on an issue."
        )
      end
    end
  end
end
