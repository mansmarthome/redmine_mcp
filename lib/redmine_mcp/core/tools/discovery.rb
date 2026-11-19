# frozen_string_literal: true

# Redmine MCP plugin
#
# Copyright (C) 2026 RK Team
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
  module Core
    module Tools
      module Discovery
      module_function

        def register!
          register_list_trackers
          register_list_issue_statuses
          register_list_issue_priorities
          register_get_current_user
          register_list_queries
        end

        def register_list_trackers
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_trackers',
            title: 'List issue trackers',
            description: 'Return a paginated list of issue tracker types. Without project: all trackers defined in the Redmine instance (for example Bug, Feature, Support); each item includes id, ' \
                         'name, and description. With optional project: only trackers enabled for that project; description is an empty string. Use before redmine_create_issue or ' \
                         'redmine_update_issue when tracker_id is unknown. Call redmine_list_projects when project is unknown. Default limit 25, maximum 100. Does not modify Redmine.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA
              }.merge(Helpers::PAGINATION_INPUT)
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_TRACKERS,
            permission: :view_issues,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_trackers)
          )
        end

        def register_list_issue_statuses
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_issue_statuses',
            title: 'List issue statuses',
            description: 'Return a paginated list of all issue workflow statuses in the Redmine instance. Each item includes id, name, and is_closed. Use before redmine_create_issue or ' \
                         'redmine_update_issue when ' \
                         'status_id is unknown or to interpret open versus closed issues. Does not include allowed transitions for a specific issue; use redmine_get_issue_form_options ' \
                         'when needed. Default limit 25, maximum 100. Does not modify Redmine.',
            input_schema: {properties: Helpers::PAGINATION_INPUT.dup},
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_STATUSES,
            permission: :view_issues,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_issue_statuses)
          )
        end

        def register_list_issue_priorities
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_issue_priorities',
            title: 'List issue priorities',
            description: 'Return a paginated list of active issue priority levels in the Redmine instance. Each item includes id, name, active, and is_default. Use before redmine_create_issue or ' \
                         'redmine_update_issue when priority_id is unknown. For workflow states, use redmine_list_issue_statuses instead. Default limit 25, maximum 100. Does not modify Redmine.',
            input_schema: {properties: Helpers::PAGINATION_INPUT.dup},
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_PRIORITIES,
            permission: :view_issues,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_issue_priorities)
          )
        end

        def register_get_current_user
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'get_current_user',
            title: 'Get current user',
            description: 'Return the profile of the currently authenticated MCP user: id, login, name parts, mail, admin flag, created_on, and last_login_on. Use to confirm identity and ' \
                         'permissions before user-scoped or admin operations. Does not include project memberships or roles. Does not modify Redmine. For MCP plugin version and read-only mode, use ' \
                         'redmine_get_mcp_info.',
            input_schema: {properties: {}},
            output_schema: RedmineMcp::Core::OutputSchemas::CURRENT_USER,
            permission: :use_mcp,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:get_current_user)
          )
        end

        def register_list_queries
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_queries',
            title: 'List saved queries',
            description: 'Return a paginated list of saved issue queries visible to the current user (private and public). Each item includes id, name, is_public, and project_id when the query is ' \
                         'project-scoped. Use to discover query_id before redmine_list_issues with query_id. Does not execute the query or return matching issues. ' \
                         'Default limit 25, maximum 100. Does not modify Redmine.',
            input_schema: {properties: Helpers::PAGINATION_INPUT.dup},
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_QUERIES,
            permission: :view_issues,
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_queries)
          )
        end

        def list_trackers(args, context)
          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          if args[:project].present?
            user = context[:user]
            project = Helpers.find_project(user, args[:project])
            return Helpers.error_result(:error_mcp_project_not_found) unless project

            scope = Helpers.with_id_order(project.trackers.sorted)
            return Helpers.paginate_collection(scope, limit: limit, offset: offset) do |tracker|
              {id: Helpers.integer_id(tracker.id), name: tracker.name, description: ''}
            end
          end

          Helpers.paginate_collection(Helpers.with_id_order(Tracker.sorted), limit: limit, offset: offset) do |tracker|
            {id: Helpers.integer_id(tracker.id), name: tracker.name, description: tracker.description.to_s}
          end
        end

        def list_issue_statuses(args, _context)
          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          Helpers.paginate_collection(Helpers.with_id_order(IssueStatus.sorted), limit: limit, offset: offset) do |status|
            {id: Helpers.integer_id(status.id), name: status.name, is_closed: status.is_closed?}
          end
        end

        def list_issue_priorities(args, _context)
          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          Helpers.paginate_collection(Helpers.with_id_order(IssuePriority.active.sorted), limit: limit, offset: offset) do |priority|
            {
              id: Helpers.integer_id(priority.id),
              name: priority.name,
              active: priority.active?,
              is_default: priority.is_default?
            }
          end
        end

        def get_current_user(_args, context)
          user = context[:user]
          {
            id: Helpers.integer_id(user.id),
            login: user.login,
            firstname: user.firstname,
            lastname: user.lastname,
            mail: user.mail,
            admin: user.admin?,
            created_on: user.created_on,
            last_login_on: user.last_login_on
          }
        end

        def list_queries(args, context)
          user = context[:user]
          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          queries = IssueQuery.visible(user).sorted
          Helpers.paginate_collection(Helpers.with_id_order(queries), limit: limit, offset: offset) do |query|
            {
              id: Helpers.integer_id(query.id),
              name: query.name,
              is_public: query.visibility == Query::VISIBILITY_PUBLIC,
              project_id: Helpers.integer_id(query.project_id)
            }
          end
        end
      end
    end
  end
end
