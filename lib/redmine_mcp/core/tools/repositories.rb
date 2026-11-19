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

require 'base64'

module RedmineMcp
  module Core
    module Tools
      module Repositories
        COMMENTS_PREVIEW_LENGTH = 255

      module_function

        def register!
          register_list_repositories
          register_get_repository
          register_list_revisions
          register_get_revision
          register_get_repository_file
          register_get_repository_diff
        end

        def register_list_repositories
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_repositories',
            title: 'List project repositories',
            description: 'Return a paginated list of SCM repositories in one project. Each item includes id, identifier, ' \
                         'scm_type, is_default, and name. Requires project and the Repository module. Use before other ' \
                         'repository tools when repository_id is unknown. Requires view_changesets or browse_repository. ' \
                         'Default limit 25, maximum 100. Does not modify Redmine.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA
              }.merge(Helpers::PAGINATION_INPUT),
              required: ['project']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_REPOSITORIES,
            permission: ->(user, args, project) { repository_discovery_allowed?(user, args, project) },
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_repositories)
          )
        end

        def register_get_repository
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'get_repository',
            title: 'Get repository',
            description: 'Return metadata for one SCM repository in a project, including scm_type, is_default, and ' \
                         'default_branch when available. When repository_id is omitted, the project default repository ' \
                         'is used. Call redmine_list_repositories when repository_id is unknown. ' \
                         'Requires view_changesets or browse_repository. Does not modify Redmine.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA,
                repository_id: Helpers::REPOSITORY_ID_SCHEMA
              },
              required: ['project']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::REPOSITORY,
            permission: ->(user, args, project) { repository_discovery_allowed?(user, args, project) },
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:get_repository)
          )
        end

        def register_list_revisions
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'list_revisions',
            title: 'List repository revisions',
            description: 'Return a paginated list of cached changesets for the selected repository. When repository_id is ' \
                         'omitted, the project default repository is used. Each item includes revision, scmid, committer, ' \
                         'committed_on, comments_preview, and user. Requires view_changesets. ' \
                         'Default limit 25, maximum 100. Does not modify Redmine.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA,
                repository_id: Helpers::REPOSITORY_ID_SCHEMA
              }.merge(Helpers::PAGINATION_INPUT),
              required: ['project']
            },
            output_schema: RedmineMcp::Core::OutputSchemas::LIST_REVISIONS,
            permission: ->(user, args, project) { changesets_read_allowed?(user, args, project) },
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:list_revisions)
          )
        end

        def register_get_revision
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'get_revision',
            title: 'Get repository revision',
            description: 'Return one cached changeset by revision number or commit hash prefix. Includes parents, ' \
                         'children, visible linked issues, and file_changes when browse_repository is allowed. When ' \
                         'repository_id is omitted, the project default repository is used. Requires view_changesets. ' \
                         'Does not modify Redmine.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA,
                revision: {
                  type: 'string',
                  minLength: 1,
                  description: 'Revision number or commit hash/prefix. Use redmine_list_revisions when unknown.'
                },
                repository_id: Helpers::REPOSITORY_ID_SCHEMA,
                file_changes_limit: {
                  type: 'integer',
                  minimum: 1,
                  maximum: Helpers::MAX_LIST_LIMIT,
                  description: 'Maximum file changes to return when browse_repository is allowed. Default: 100'
                },
                file_changes_offset: {type: 'integer', minimum: 0, default: 0, description: 'File changes to skip'}
              },
              required: %w[project revision]
            },
            output_schema: RedmineMcp::Core::OutputSchemas::REVISION,
            permission: ->(user, args, project) { changesets_read_allowed?(user, args, project) },
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:get_revision)
          )
        end

        def register_get_repository_file
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'get_repository_file',
            title: 'Get repository file or directory',
            description: 'Return one repository path at a revision. When repository_id is omitted, the project default ' \
                         'repository is used. Directories return a paginated entry list. Text files return inline ' \
                         'content. Binary files return metadata only unless include_content_base64 is true. Requires ' \
                         'browse_repository. Does not modify Redmine.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA,
                path: {type: 'string', description: 'Repository path relative to root. Empty string for root.'},
                repository_id: Helpers::REPOSITORY_ID_SCHEMA,
                revision: {type: 'string', description: 'Revision, branch, tag, or commit hash. Defaults to default branch.'},
                include_content_base64: {
                  type: 'boolean',
                  default: false,
                  description: 'When true, return binary file bytes as content_base64 within MCP size limits.'
                }
              }.merge(Helpers::PAGINATION_INPUT),
              required: %w[project path]
            },
            output_schema: RedmineMcp::Core::OutputSchemas::REPOSITORY_FILE,
            permission: ->(user, args, project) { browse_repository_allowed?(user, args, project) },
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:get_repository_file)
          )
        end

        def register_get_repository_diff
          Registry.instance.register_tool(
            plugin_id: PLUGIN_ID,
            name: 'get_repository_diff',
            title: 'Get repository diff',
            description: 'Return a unified diff for one repository path at revision, optionally compared to revision_to. ' \
                         'When repository_id is omitted, the project default repository is used. Output is truncated ' \
                         'by Redmine and MCP line/byte limits. Requires browse_repository. Does not modify Redmine.',
            input_schema: {
              properties: {
                project: Helpers::PROJECT_SCHEMA,
                path: {type: 'string', description: 'Repository path relative to root. Empty string for root.'},
                revision: {type: 'string', minLength: 1, description: 'Revision, branch, tag, or commit hash.'},
                revision_to: {type: 'string', description: 'Optional second revision for comparison.'},
                repository_id: Helpers::REPOSITORY_ID_SCHEMA
              },
              required: %w[project path revision]
            },
            output_schema: RedmineMcp::Core::OutputSchemas::REPOSITORY_DIFF,
            permission: ->(user, args, project) { browse_repository_allowed?(user, args, project) },
            annotations: Helpers::READ_ONLY_ANNOTATIONS,
            handler: method(:get_repository_diff)
          )
        end

        def list_repositories(args, context)
          user = context[:user]
          project, err = find_repository_project(user, args[:project])
          return err if err

          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          repositories = project.repositories.order(is_default: :desc, identifier: :asc, id: :asc)
          Helpers.paginate_collection(repositories, limit: limit, offset: offset) do |repository|
            serialize_repository_summary(repository)
          end
        end

        def get_repository(args, context)
          user = context[:user]
          project, err = find_repository_project(user, args[:project])
          return err if err

          repository, err = Helpers.find_project_repository(project, args[:repository_id])
          return err if err

          serialize_repository_detail(repository)
        end

        def list_revisions(args, context)
          user = context[:user]
          project, err = find_repository_project(user, args[:project])
          return err if err
          return Helpers.error_result(:error_mcp_permission_denied) unless user.allowed_to?(:view_changesets, project)

          repository, err = Helpers.find_project_repository(project, args[:repository_id])
          return err if err

          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          scope = Changeset.visible(user).where(repository_id: repository.id).order(committed_on: :desc, id: :desc)
          Helpers.paginate_collection(scope.includes(:user), limit: limit, offset: offset) do |changeset|
            serialize_revision_summary(changeset)
          end
        end

        def get_revision(args, context)
          user = context[:user]
          project, err = find_repository_project(user, args[:project])
          return err if err
          return Helpers.error_result(:error_mcp_permission_denied) unless user.allowed_to?(:view_changesets, project)

          repository, err = Helpers.find_project_repository(project, args[:repository_id])
          return err if err

          changeset = repository.find_changeset_by_name(args[:revision])
          return Helpers.error_result(:error_mcp_revision_not_found) unless changeset

          serialize_revision_detail(
            changeset,
            user: user,
            project: project,
            include_file_changes: user.allowed_to?(:browse_repository, project),
            file_changes_limit: Helpers.nested_list_limit(args[:file_changes_limit]),
            file_changes_offset: Helpers.clamp_offset(args[:file_changes_offset])
          )
        end

        def get_repository_file(args, context)
          user = context[:user]
          project, err = find_repository_project(user, args[:project])
          return err if err
          return Helpers.error_result(:error_mcp_permission_denied) unless user.allowed_to?(:browse_repository, project)

          repository, err = Helpers.find_project_repository(project, args[:repository_id])
          return err if err

          path, err = Helpers.normalize_repository_path(args[:path])
          return err if err

          rev, err = Helpers.resolve_revision(repository, args[:revision])
          return err if err

          with_scm do
            entry = repository.entry(path, rev)
            return Helpers.error_result(:error_mcp_repository_path_not_found) unless entry

            if entry.is_dir?
              serialize_directory(repository, path, rev, args)
            else
              serialize_file(repository, entry, path, rev, args)
            end
          end
        end

        def get_repository_diff(args, context)
          user = context[:user]
          project, err = find_repository_project(user, args[:project])
          return err if err
          return Helpers.error_result(:error_mcp_permission_denied) unless user.allowed_to?(:browse_repository, project)

          repository, err = Helpers.find_project_repository(project, args[:repository_id])
          return err if err

          path, err = Helpers.normalize_repository_path(args[:path])
          return err if err

          rev, err = Helpers.resolve_revision(repository, args[:revision])
          return err if err

          rev_to, err = Helpers.resolve_revision_to(repository, args[:revision_to])
          return err if err

          with_scm do
            diff_lines = repository.diff(path, rev, rev_to)
            return Helpers.error_result(:error_mcp_repository_path_not_found) unless diff_lines

            truncated = Helpers.truncate_repository_diff(diff_lines)
            {
              path: path,
              revision: rev,
              revision_to: rev_to,
              diff: truncated[:diff],
              truncated: truncated[:truncated],
              total_lines: truncated[:total_lines],
              returned_lines: truncated[:returned_lines],
              total_bytes: truncated[:total_bytes],
              returned_bytes: truncated[:returned_bytes]
            }
          end
        end

        def find_repository_project(user, project_ref)
          project = Helpers.find_project(user, project_ref)
          return [nil, Helpers.error_result(:error_mcp_project_not_found)] unless project
          return [nil, Helpers.error_result(:error_mcp_repository_not_enabled)] unless project.module_enabled?(:repository)

          [project, nil]
        end

        def repository_discovery_allowed?(user, args, project)
          return Helpers.repository_tools_visible?(user) if repository_tool_listing?(args, project)

          project ||= Helpers.find_project(user, args[:project])
          return false unless project

          Helpers.repository_read_allowed?(user, project)
        end

        def changesets_read_allowed?(user, args, project)
          return Helpers.repository_tools_visible?(user) if repository_tool_listing?(args, project)

          project ||= Helpers.find_project(user, args[:project])
          return false unless project

          Helpers.project_permission_granted?(user, project, :view_changesets)
        end

        def browse_repository_allowed?(user, args, project)
          return Helpers.repository_tools_visible?(user) if repository_tool_listing?(args, project)

          project ||= Helpers.find_project(user, args[:project])
          return false unless project

          Helpers.project_permission_granted?(user, project, :browse_repository)
        end

        def repository_tool_listing?(args, project)
          args[:project].blank? && project.nil?
        end

        def with_scm
          yield
        rescue Redmine::Scm::Adapters::CommandFailed => e
          Helpers.scm_command_error(e)
        end

        def serialize_repository_summary(repository)
          {
            id: Helpers.integer_id(repository.id),
            identifier: repository.identifier.to_s.presence,
            scm_type: normalized_scm_type(repository),
            is_default: repository.is_default?,
            name: repository.name
          }
        end

        def serialize_repository_detail(repository)
          data = serialize_repository_summary(repository)
          branch = with_scm { repository.default_branch }
          data[:default_branch] = branch.is_a?(Hash) && branch[:code] ? nil : branch
          data
        end

        def normalized_scm_type(repository)
          repository.scm_name.to_s.downcase
        end

        def serialize_revision_summary(changeset)
          {
            revision: changeset.identifier,
            scmid: changeset.scmid.to_s.presence,
            committer: changeset.committer.to_s,
            committed_on: changeset.committed_on&.iso8601,
            comments_preview: comments_preview(changeset.comments),
            user: Helpers.serialize_user_ref(changeset.user)
          }
        end

        def serialize_revision_detail(changeset, user:, project:, include_file_changes:, file_changes_limit:, file_changes_offset:)
          data = serialize_revision_summary(changeset).merge(
            comments: changeset.comments.to_s,
            parents: changeset.parents.map { |parent| serialize_revision_ref(parent) },
            children: changeset.children.map { |child| serialize_revision_ref(child) },
            issues: visible_issues(changeset, user).map { |issue| serialize_issue_ref(issue) },
            project: Helpers.serialize_project(project)
          )

          if include_file_changes
            file_changes, file_changes_pagination = Helpers.paginated_nested(
              changeset.filechanges.reorder(:path),
              limit: file_changes_limit,
              offset: file_changes_offset
            ) do |change|
              serialize_file_change(change)
            end
            data[:file_changes] = file_changes
            data[:file_changes_pagination] = file_changes_pagination
          end

          data
        end

        def serialize_revision_ref(changeset)
          {
            revision: changeset.identifier,
            scmid: changeset.scmid.to_s.presence
          }
        end

        def serialize_issue_ref(issue)
          {
            id: Helpers.integer_id(issue.id),
            subject: issue.subject
          }
        end

        def visible_issues(changeset, user)
          changeset.issues.select { |issue| issue.visible?(user) }
        end

        def serialize_file_change(change)
          {
            action: change.action,
            path: change.path,
            from_path: change.from_path.to_s.presence,
            from_revision: change.from_revision.to_s.presence
          }
        end

        def serialize_directory(repository, path, rev, args)
          entries = repository.entries(path, rev) || []
          limit = Helpers.clamp_limit(args[:limit])
          offset = Helpers.clamp_offset(args[:offset])
          paginated = Helpers.paginate_collection(entries, limit: limit, offset: offset) do |entry|
            serialize_entry(entry)
          end
          {
            kind: 'dir',
            path: path,
            revision: rev,
            entries: paginated.dig(:data, :items) || [],
            entries_pagination: paginated[:meta]
          }
        end

        def serialize_file(repository, entry, path, rev, args)
          result = {
            kind: 'file',
            path: path,
            revision: rev,
            name: entry.name,
            size: entry.size,
            content_type: Redmine::MimeType.of(path).presence || Helpers::DEFAULT_CONTENT_TYPE
          }

          byte_limit = Helpers.effective_repository_file_byte_limit
          if Helpers.truthy?(args[:include_content_base64]) && entry.size && entry.size > byte_limit
            return Helpers.error_result(
              :error_mcp_repository_file_too_large,
              details: {
                size: entry.size,
                max_bytes: byte_limit
              }
            )
          end

          return result.merge(is_binary: nil, content_available: false) if entry.size && entry.size > byte_limit

          content = repository.cat(path, rev)
          return Helpers.error_result(:error_mcp_repository_path_not_found) unless content

          return result.merge(is_binary: nil, content_available: false, size: content.bytesize) if content.bytesize > byte_limit

          if Helpers.repository_text_entry?(content, path)
            normalized = content.to_s.dup.force_encoding(Encoding::UTF_8).gsub("\r\n", "\n")
            result.merge(is_binary: false, content_available: true, encoding: 'utf-8', content: normalized)
          else
            result[:is_binary] = true
            result[:content_available] = false
            if Helpers.truthy?(args[:include_content_base64])
              too_large = binary_download_error(content, byte_limit)
              return too_large if too_large

              result[:content_available] = true
              result[:content_base64] = Base64.strict_encode64(content)
              result[:size] = content.bytesize
            end
            result
          end
        end

        def binary_download_error(content, byte_limit)
          return nil if content.bytesize <= byte_limit

          Helpers.error_result(
            :error_mcp_repository_file_too_large,
            details: {
              size: content.bytesize,
              max_bytes: byte_limit
            }
          )
        end

        def serialize_entry(entry)
          data = {
            name: entry.name,
            path: entry.path,
            kind: entry.kind,
            size: entry.size
          }
          if entry.lastrev
            data[:lastrev] = {
              revision: entry.lastrev.identifier.to_s,
              scmid: entry.lastrev.scmid.to_s.presence,
              committed_on: entry.lastrev.time&.iso8601,
              author: entry.lastrev.author.to_s
            }
          end
          data
        end

        def comments_preview(comments)
          text = comments.to_s
          return text if text.length <= COMMENTS_PREVIEW_LENGTH

          "#{text[0, COMMENTS_PREVIEW_LENGTH]}..."
        end
      end
    end
  end
end
