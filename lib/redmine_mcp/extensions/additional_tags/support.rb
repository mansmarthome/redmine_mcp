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

module RedmineMcp
  module Extensions
    module AdditionalTags
      # Reads and writes additional_tags issue tags. New names need
      # create_issue_tags; assigning only existing visible tags needs
      # edit_issue_tags. Removing tags creates nothing.
      module Support
        module_function

        def with_user(user)
          previous = User.current
          User.current = user
          yield
        ensure
          User.current = previous
        end

        def enabled?
          defined?(::AdditionalTags) && ::AdditionalTags.setting?(:active_issue_tags)
        end

        def disabled_result
          Core::Helpers.mcp_error(
            code: 'INVALID_STATE',
            message: 'Issue tags are disabled in Additional Tags settings.'
          )
        end

        def names(issue)
          issue.tag_list.to_a
        end

        def normalize(value)
          Array(value).map { |name| name.to_s.strip }.reject(&:blank?)
        end

        def tag_payload(tag)
          payload = {id: tag.id, name: tag.name}
          payload[:count] = tag.count.to_i if tag.respond_to?(:count) && !tag.count.nil?
          payload
        end

        def issue_row(issue)
          {
            id: issue.id,
            url: Core::Helpers.issue_url(issue),
            subject: issue.subject.to_s,
            project: Core::Helpers.serialize_project(issue.project),
            status: Core::Helpers.serialize_named_ref(issue.status),
            tags: names(issue)
          }
        end

        def allowed?(issue, user, tag_names)
          return issue.tags_allowed_for?(user, tag_names) if issue.respond_to?(:tags_allowed_for?)

          user.allowed_to?(:edit_issue_tags, issue.project) &&
            (tag_names.empty? || user.allowed_to?(:create_issue_tags, issue.project) || known_tags?(tag_names, user))
        end

        def known_tags?(names, user)
          return false if names.empty?

          if Issue.respond_to?(:allowed_tags?)
            method = Issue.method(:allowed_tags?)
            return method.parameters.any? { |_type, name| name == :user } ? method.call(names, user: user) : method.call(names)
          end
          return false unless Issue.respond_to?(:available_tags)

          known = Issue.available_tags(user: user).map(&:name)
          names.all? { |name| known.include?(name) }
        end

        def apply!(issue, names, mode, user)
          current = issue.tag_list.dup
          before_names = current.to_a
          before = current.to_s
          updated =
            case mode
            when 'append' then current.add(names)
            when 'remove' then current.remove(names)
            when 'replace' then ::AdditionalTags::TagList.new(*names)
            else
              return Core::Helpers.mcp_error(
                code: 'VALIDATION_ERROR',
                message: 'mode must be replace, append, or remove',
                field: 'mode'
              )
            end

          checked = mode == 'append' ? names : updated.to_a
          unless mode == 'remove' || allowed?(issue, user, checked)
            return Core::Helpers.mcp_error(
              code: 'FORBIDDEN',
              message: 'A new tag name requires create_issue_tags. Call redmine_additional_tags_list_issue_tags for names that already exist.'
            )
          end

          return names(issue) if before_names.sort == updated.to_a.sort

          issue.init_journal(user)
          issue.tag_list = updated
          journal!(issue, before, issue.tag_list.to_s)
          return Core::Helpers.model_errors(issue) unless issue.save

          issue.reload
          names(issue)
        end

        def journal!(issue, before, after)
          return if before == after

          if issue.respond_to?(:tags_to_journal)
            issue.tags_to_journal(before, after)
          else
            issue.current_journal.details << JournalDetail.new(
              property: 'attr', prop_key: 'tag_list', old_value: before, value: after
            )
          end
        end

        def tag_count(scope)
          count = scope.unscope(:select, :order).count
          count.is_a?(Hash) ? count.size : count
        end

        def list_scope(user, project)
          Issue.available_tags(project: project, user: user, permission: :view_issue_tags)
        end

        def search_scope(user, names, match:, project:)
          scope = Issue.visible(user).where(project_id: Project.allowed_to(user, :view_issue_tags).select(:id))
          scope = scope.where(project_id: project.id) if project
          scope.tagged_with(names, any: match == 'any').preload(:tags, :project, :status)
        end
      end
    end
  end
end
