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

require File.expand_path('additional_tags/support', __dir__)

module RedmineMcp
  module Extensions
    module AdditionalTags
      extend RedmineMcp::ExtensionApi

      plugin_id :additional_tags

      H = RedmineMcp::Core::Helpers
      S = Support
      N = RedmineMcp::SchemaNormalizer
      ISSUE_ID = H::ISSUE_ID_SCHEMA.merge(
        description: 'Numeric issue ID. Call redmine_search_issues or redmine_list_issues when unknown.',
        examples: [1]
      ).freeze
      TAG_NAME = {
        type: 'string',
        minLength: 1,
        maxLength: 255,
        description: 'One tag name. Call redmine_additional_tags_list_issue_tags for names that already exist.'
      }.freeze
      TAGS = {
        type: 'array',
        maxItems: 50,
        uniqueItems: true,
        items: TAG_NAME,
        description: 'Tag names. Each entry is one tag, not a comma-separated list.'
      }.freeze
      TAG_SCHEMA = {
        type: 'object',
        additionalProperties: false,
        properties: {
          id: {type: 'integer', minimum: 1},
          name: {type: 'string'},
          count: {type: 'integer', minimum: 0}
        },
        required: %w[id name]
      }.freeze
      ISSUE_TAG_ROW = {
        type: 'object',
        additionalProperties: false,
        properties: {
          id: {type: 'integer', minimum: 1},
          url: {type: %w[string null]},
          subject: {type: 'string'},
          project: {
            type: %w[object null],
            additionalProperties: false,
            properties: {
              id: {type: 'integer', minimum: 1},
              identifier: {type: 'string'},
              name: {type: 'string'}
            },
            required: %w[id identifier name]
          },
          status: {
            type: %w[object null],
            additionalProperties: false,
            properties: {
              id: {type: 'integer', minimum: 1},
              name: {type: 'string'}
            },
            required: %w[id name]
          },
          tags: {type: 'array', items: {type: 'string'}}
        },
        required: %w[id subject tags]
      }.freeze
      NAMES_OUTPUT = N.envelope_output(
        type: 'object',
        additionalProperties: false,
        properties: {
          issue_id: {type: 'integer', minimum: 1},
          tags: {type: 'array', items: {type: 'string'}}
        },
        required: %w[issue_id tags]
      ).freeze
      TAG_SET_ANNOTATIONS = H::UPDATE_ANNOTATIONS.merge(idempotent_hint: true).freeze
      TAG_REMOVE_ANNOTATIONS = {
        read_only_hint: false,
        destructive_hint: true,
        idempotent_hint: true,
        open_world_hint: false
      }.freeze

      if mcp_extension_enabled?
        register_tool_once(
          name: 'list_issue_tags',
          title: 'List issue tags',
          description: "Returns issue tag names visible to the caller.\n\n" \
                       "Optional project limits the list to one project.\n" \
                       "Default limit 25, max 100. Each item has id, name, and count.\n" \
                       "Requires view_issue_tags. Issue tags must be enabled in Additional Tags settings.",
          permission: :view_issue_tags,
          annotations: H::READ_ONLY_ANNOTATIONS,
          input_schema: {
            properties: {
              project: H::PROJECT_SCHEMA
            }.merge(H::PAGINATION_INPUT)
          },
          output_schema: N.list_envelope_output(TAG_SCHEMA),
          handler: lambda { |args, context|
            return S.disabled_result unless S.enabled?

            user = context[:user]
            S.with_user(user) do
              project = nil
              if args[:project].present?
                project = H.find_project(user, args[:project])
                return H.error_result(:error_mcp_project_not_found) unless project
                return H.error_result(:error_mcp_permission_denied) unless user.allowed_to?(:view_issue_tags, project)
              end

              scope = S.list_scope(user, project)
              total = S.tag_count(scope)
              limit = H.clamp_limit(args[:limit])
              offset = H.clamp_offset(args[:offset])
              rows = scope.offset(offset).limit(limit).map { |tag| S.tag_payload(tag) }
              H.paginated_list(rows, total_count: total, limit: limit, offset: offset)
            end
          }
        )

        register_issue_tool(
          name: 'get_issue_tags',
          title: 'Get issue tags',
          description: "Returns the tag names on one issue.\n\n" \
                       "Does not return tag ids. Call redmine_additional_tags_list_issue_tags for the visible tag directory.\n" \
                       "Requires view_issue_tags.",
          permission: :view_issue_tags,
          module_name: :issue_tracking,
          annotations: H::READ_ONLY_ANNOTATIONS,
          input_schema: {
            properties: {issue_id: ISSUE_ID},
            required: ['issue_id']
          },
          output_schema: NAMES_OUTPUT
        ) do |issue, _args, context|
          next S.disabled_result unless S.enabled?

          S.with_user(context[:user]) do
            {issue_id: issue.id, tags: S.names(issue)}
          end
        end

        register_issue_tool(
          name: 'set_issue_tags',
          title: 'Set issue tags',
          description: "Replaces the tags on one issue.\n\n" \
                       "An empty tags array clears tags. It does not delete tag records used by other issues.\n" \
                       "A repeated call with the same names does not add another journal.\n" \
                       "Requires edit_issue_tags. A name that does not already exist also requires create_issue_tags.\n" \
                       "Call redmine_additional_tags_list_issue_tags when existing names are unknown.",
          permission: :edit_issue_tags,
          module_name: :issue_tracking,
          annotations: TAG_SET_ANNOTATIONS,
          input_schema: {
            properties: {
              issue_id: ISSUE_ID,
              tags: TAGS.merge(description: 'Tag names that replace the current list. Pass [] to clear tags.')
            },
            required: %w[issue_id tags]
          },
          output_schema: NAMES_OUTPUT
        ) do |issue, args, context|
          blocked = guard_write!
          next blocked if blocked
          next S.disabled_result unless S.enabled?

          S.with_user(context[:user]) do
            tags = write_tags!(issue, S.normalize(args[:tags]), 'replace', context[:user])
            next tags if tags.is_a?(Hash) && tags[:error]

            {issue_id: issue.id, tags: tags}
          end
        end

        register_issue_tool(
          name: 'add_issue_tags',
          title: 'Add issue tags',
          description: "Adds tag names to one issue without removing existing tags.\n\n" \
                       "tags must not be empty. Names already on the issue are ignored.\n" \
                       "A repeated call with the same names does not add another journal.\n" \
                       "Requires edit_issue_tags. A name that does not already exist also requires create_issue_tags.\n" \
                       "Call redmine_additional_tags_list_issue_tags when existing names are unknown.",
          permission: :edit_issue_tags,
          module_name: :issue_tracking,
          annotations: TAG_SET_ANNOTATIONS,
          input_schema: {
            properties: {
              issue_id: ISSUE_ID,
              tags: TAGS.merge(minItems: 1, description: 'Tag names to add. Each entry is one tag.')
            },
            required: %w[issue_id tags]
          },
          output_schema: NAMES_OUTPUT
        ) do |issue, args, context|
          blocked = guard_write!
          next blocked if blocked
          next S.disabled_result unless S.enabled?

          S.with_user(context[:user]) do
            tags = write_tags!(issue, S.normalize(args[:tags]), 'append', context[:user])
            next tags if tags.is_a?(Hash) && tags[:error]

            {issue_id: issue.id, tags: tags}
          end
        end

        register_issue_tool(
          name: 'remove_issue_tags',
          title: 'Remove issue tags',
          description: "Removes tag names from one issue.\n\n" \
                       "Does not delete the tag records. Names that are not on the issue are ignored.\n" \
                       "tags must not be empty. A repeated call does not add another journal.\n" \
                       "Requires edit_issue_tags. Does not require create_issue_tags.",
          permission: :edit_issue_tags,
          module_name: :issue_tracking,
          annotations: TAG_REMOVE_ANNOTATIONS,
          input_schema: {
            properties: {
              issue_id: ISSUE_ID,
              tags: TAGS.merge(minItems: 1, description: 'Tag names to remove from the issue.')
            },
            required: %w[issue_id tags]
          },
          output_schema: NAMES_OUTPUT
        ) do |issue, args, context|
          blocked = guard_write!
          next blocked if blocked
          next S.disabled_result unless S.enabled?

          S.with_user(context[:user]) do
            tags = write_tags!(issue, S.normalize(args[:tags]), 'remove', context[:user])
            next tags if tags.is_a?(Hash) && tags[:error]

            {issue_id: issue.id, tags: tags}
          end
        end

        register_tool_once(
          name: 'search_issues_by_tags',
          title: 'Search issues by tags',
          description: "Returns issues that carry the given tag names.\n\n" \
                       "match=all (default) requires every name. match=any requires one name.\n" \
                       "Each item is a summary. Use redmine_get_issue for full issue detail and redmine_additional_tags_get_issue_tags for the tag list.\n" \
                       "Default limit 25, max 100. Newest updated issues first.\n" \
                       "Requires view_issue_tags. Only issues in projects where the caller may view issue tags are returned.",
          permission: :view_issue_tags,
          annotations: H::READ_ONLY_ANNOTATIONS,
          input_schema: {
            properties: {
              tags: TAGS.merge(minItems: 1),
              match: {
                type: 'string',
                enum: %w[all any],
                description: 'all requires every tag. any requires one tag. Default: all.'
              },
              project: H::PROJECT_SCHEMA
            }.merge(H::PAGINATION_INPUT),
            required: ['tags']
          },
          output_schema: N.list_envelope_output(ISSUE_TAG_ROW),
          handler: lambda { |args, context|
            return S.disabled_result unless S.enabled?

            user = context[:user]
            S.with_user(user) do
              project = nil
              if args[:project].present?
                project = H.find_project(user, args[:project])
                return H.error_result(:error_mcp_project_not_found) unless project
                return H.error_result(:error_mcp_permission_denied) unless user.allowed_to?(:view_issue_tags, project)
              end

              names = S.normalize(args[:tags])
              return H.mcp_error(code: 'VALIDATION_ERROR', message: 'tags must not be empty', field: 'tags') if names.empty?

              match = args[:match].presence || 'all'
              scope = S.search_scope(user, names, match: match, project: project)
              total = scope.count
              limit = H.clamp_limit(args[:limit])
              offset = H.clamp_offset(args[:offset])
              rows = scope.reorder(updated_on: :desc, id: :desc).offset(offset).limit(limit).map { |issue| S.issue_row(issue) }
              H.paginated_list(rows, total_count: total, limit: limit, offset: offset)
            end
          }
        )
      end

      def self.write_tags!(issue, names, mode, user)
        if names.empty? && mode != 'replace'
          return H.mcp_error(code: 'VALIDATION_ERROR', message: 'tags must not be empty', field: 'tags')
        end

        S.apply!(issue, names, mode, user)
      end
    end
  end
end
