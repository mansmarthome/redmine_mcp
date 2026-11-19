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

require File.expand_path('../test_helper', __dir__)

class RedmineMcpRepositoriesTest < RedmineMcpTestCase
  fixtures :repositories, :changesets, :boards, :messages

  README_TXT = 'readme.txt'
  IMAGE_BIN = 'image.bin'
  BIG_BIN = 'big.bin'
  SCM_ERROR_MESSAGE = 'git missing'
  REPOSITORY_TOOL_NAMES = %w[
    list_repositories
    get_repository
    list_revisions
    get_revision
    get_repository_file
    get_repository_diff
  ].freeze

  def setup
    super
    @admin = User.find(1)
    @member = User.find(2)
    @repository = Repository.find(10)
  end

  test 'list_repositories returns repositories for project' do
    payload = invoke_mcp_tool('list_repositories', user: @admin, args: {project: 'ecookbook'})

    assert_mcp_ok(payload)
    ids = Array(payload.dig(:data, :items)).map { |item| item[:id] }

    assert_includes ids, @repository.id
    assert_mcp_output_schema('list_repositories', payload)
  end

  test 'get_repository returns repository metadata' do
    payload = invoke_mcp_tool(
      'get_repository',
      user: @admin,
      args: {project: 'ecookbook', repository_id: @repository.id.to_s}
    )

    assert_mcp_ok(payload)
    assert_equal @repository.id, payload.dig(:data, :id)
    assert_equal 'subversion', payload.dig(:data, :scm_type)
    assert_nil payload.dig(:data, :url)
    assert_mcp_output_schema('get_repository', payload)
  end

  test 'list_revisions returns cached changesets' do
    payload = invoke_mcp_tool('list_revisions', user: @admin, args: {project: 'ecookbook', limit: 5})

    assert_mcp_ok(payload)
    revisions = Array(payload.dig(:data, :items)).map { |item| item[:revision] }

    assert revisions.any?
    assert payload.dig(:meta, :total_count).to_i.positive?
    assert_mcp_output_schema('list_revisions', payload)
  end

  test 'get_revision returns changeset details' do
    payload = invoke_mcp_tool(
      'get_revision',
      user: @admin,
      args: {project: 'ecookbook', revision: '1'}
    )

    assert_mcp_ok(payload)
    assert_equal '1', payload.dig(:data, :revision)
    assert payload.dig(:data, :comments).present?
    assert payload.dig(:data, :file_changes).present?
    assert_mcp_output_schema('get_revision', payload)
  end

  test 'get_repository_file returns directory listing with stubbed scm' do
    dir_entry = scm_entry(kind: 'dir', name: '', path: '')
    file_entry = scm_entry(kind: 'file', name: README_TXT, path: README_TXT, size: 12)
    stub_repository_scm(
      default_branch: '1',
      entry: dir_entry,
      entries: [file_entry]
    )

    payload = invoke_mcp_tool(
      'get_repository_file',
      user: @admin,
      args: {project: 'ecookbook', path: '', revision: '1'}
    )

    assert_mcp_ok(payload)
    assert_equal 'dir', payload.dig(:data, :kind)
    names = Array(payload.dig(:data, :entries)).map { |item| item[:name] }

    assert_includes names, README_TXT
    assert_mcp_output_schema('get_repository_file', payload)
  end

  test 'get_repository_file returns text content for text file' do
    file_entry = scm_entry(kind: 'file', name: README_TXT, path: README_TXT, size: 5)
    stub_repository_scm(
      default_branch: '1',
      entry: file_entry,
      cat: "hello\n"
    )

    payload = invoke_mcp_tool(
      'get_repository_file',
      user: @admin,
      args: {project: 'ecookbook', path: README_TXT, revision: '1'}
    )

    assert_mcp_ok(payload)
    assert_equal false, payload.dig(:data, :is_binary)
    assert_equal "hello\n", payload.dig(:data, :content)
    assert_nil payload.dig(:data, :content_base64)
    assert_mcp_output_schema('get_repository_file', payload)
  end

  test 'get_repository_file returns binary metadata without content by default' do
    file_entry = scm_entry(kind: 'file', name: IMAGE_BIN, path: IMAGE_BIN, size: 4)
    stub_repository_scm(
      default_branch: '1',
      entry: file_entry,
      cat: "PNG\x01"
    )

    payload = invoke_mcp_tool(
      'get_repository_file',
      user: @admin,
      args: {project: 'ecookbook', path: IMAGE_BIN, revision: '1'}
    )

    assert_mcp_ok(payload)
    assert payload.dig(:data, :is_binary)
    assert_equal false, payload.dig(:data, :content_available)
    assert_nil payload.dig(:data, :content)
    assert_nil payload.dig(:data, :content_base64)
    assert_mcp_output_schema('get_repository_file', payload)
  end

  test 'get_repository_file treats nul bytes in text extension as binary' do
    content = "hello\x00"
    file_entry = scm_entry(kind: 'file', name: README_TXT, path: README_TXT, size: content.bytesize)
    stub_repository_scm(
      default_branch: '1',
      entry: file_entry,
      cat: content
    )

    payload = invoke_mcp_tool(
      'get_repository_file',
      user: @admin,
      args: {project: 'ecookbook', path: README_TXT, revision: '1'}
    )

    assert_mcp_ok(payload)
    assert payload.dig(:data, :is_binary)
    assert_equal false, payload.dig(:data, :content_available)
    assert_nil payload.dig(:data, :content)
    assert_nil payload.dig(:data, :content_base64)
    assert_mcp_output_schema('get_repository_file', payload)
  end

  test 'get_repository_file returns content_base64 when requested for binary file' do
    content = "PNG\x01"
    file_entry = scm_entry(kind: 'file', name: IMAGE_BIN, path: IMAGE_BIN, size: content.bytesize)
    stub_repository_scm(
      default_branch: '1',
      entry: file_entry,
      cat: content
    )

    payload = invoke_mcp_tool(
      'get_repository_file',
      user: @admin,
      args: {project: 'ecookbook', path: IMAGE_BIN, revision: '1', include_content_base64: true}
    )

    assert_mcp_ok(payload)
    assert_equal Base64.strict_encode64(content), payload.dig(:data, :content_base64)
    assert_nil payload.dig(:data, :content)
  end

  test 'get_repository_file returns FILE_TOO_LARGE for oversized binary download' do
    limit = RedmineMcp::Core::Helpers.effective_repository_file_byte_limit
    content = 'x' * (limit + 1)
    file_entry = scm_entry(kind: 'file', name: BIG_BIN, path: BIG_BIN, size: content.bytesize)
    stub_repository_scm(
      default_branch: '1',
      entry: file_entry,
      cat: content
    )

    payload = invoke_mcp_tool(
      'get_repository_file',
      user: @admin,
      args: {project: 'ecookbook', path: BIG_BIN, revision: '1', include_content_base64: true}
    )

    assert_equal false, payload[:ok]
    assert_equal 'FILE_TOO_LARGE', payload.dig(:error, :code)
  end

  test 'get_repository_diff truncates by line and byte limits' do
    lines = ['a' * 1024] * (RedmineMcp::Core::Helpers.effective_repository_diff_line_limit + 5)
    stub_repository_scm(default_branch: '1', diff: lines)

    payload = invoke_mcp_tool(
      'get_repository_diff',
      user: @admin,
      args: {project: 'ecookbook', path: README_TXT, revision: '1'}
    )

    assert_mcp_ok(payload)
    assert payload.dig(:data, :truncated)
    assert_operator payload.dig(:data, :returned_lines), :<, payload.dig(:data, :total_lines)
    assert_mcp_output_schema('get_repository_diff', payload)
  end

  test 'get_repository_diff returns REDMINE_API_ERROR on scm command failure' do
    Repository.any_instance.stubs(:diff).raises(Redmine::Scm::Adapters::CommandFailed, SCM_ERROR_MESSAGE)
    Repository.any_instance.stubs(:default_branch).returns('main')
    Repository.any_instance.stubs(:valid_name?).returns(true)

    payload = invoke_mcp_tool(
      'get_repository_diff',
      user: @admin,
      args: {project: 'ecookbook', path: README_TXT, revision: '1'}
    )

    assert_equal false, payload[:ok]
    assert_equal 'REDMINE_API_ERROR', payload.dig(:error, :code)
    assert_not_includes payload.dig(:error, :message).to_s, SCM_ERROR_MESSAGE
    assert_not_equal 'NOT_FOUND', payload.dig(:error, :code)
  end

  test 'get_repository_file returns REDMINE_API_ERROR when default_branch scm fails without revision' do
    Repository.any_instance.stubs(:default_branch).raises(Redmine::Scm::Adapters::CommandFailed, SCM_ERROR_MESSAGE)

    payload = invoke_mcp_tool(
      'get_repository_file',
      user: @admin,
      args: {project: 'ecookbook', path: README_TXT}
    )

    assert_equal false, payload[:ok]
    assert_equal 'REDMINE_API_ERROR', payload.dig(:error, :code)
    assert_not_includes payload.dig(:error, :message).to_s, SCM_ERROR_MESSAGE
    assert_not_equal 'INTERNAL_ERROR', payload.dig(:error, :code)
  end

  test 'get_repository returns metadata with null default_branch when scm fails' do
    Repository.any_instance.stubs(:default_branch).raises(Redmine::Scm::Adapters::CommandFailed, SCM_ERROR_MESSAGE)

    payload = invoke_mcp_tool(
      'get_repository',
      user: @admin,
      args: {project: 'ecookbook', repository_id: @repository.id.to_s}
    )

    assert_mcp_ok(payload)
    assert_equal @repository.id, payload.dig(:data, :id)
    assert_nil payload.dig(:data, :default_branch)
    assert_mcp_output_schema('get_repository', payload)
  end

  test 'get_repository_file rejects invalid revision parameter' do
    Repository.any_instance.stubs(:default_branch).returns('main')
    Repository.any_instance.stubs(:valid_name?).returns(false)

    payload = invoke_mcp_tool(
      'get_repository_file',
      user: @admin,
      args: {project: 'ecookbook', path: README_TXT, revision: 'bad rev!'}
    )

    assert_equal false, payload[:ok]
    assert_equal 'VALIDATION_ERROR', payload.dig(:error, :code)
  end

  test 'repository tools stay listed when user has only view_changesets' do
    _project, user = generate_repository_access_project(permissions: %i[view_project view_changesets])
    names = mcp_registry.tools_for_user(user).map(&:name)

    REPOSITORY_TOOL_NAMES.each do |name|
      assert_includes names, name
    end
  end

  test 'repository tools stay listed when user has only browse_repository' do
    _project, user = generate_repository_access_project(permissions: %i[view_project browse_repository])
    names = mcp_registry.tools_for_user(user).map(&:name)

    REPOSITORY_TOOL_NAMES.each do |name|
      assert_includes names, name
    end
  end

  test 'repository tools stay listed when user has no repository permissions' do
    _project, user = generate_repository_access_project(permissions: %i[view_project])
    names = mcp_registry.tools_for_user(user).map(&:name)

    REPOSITORY_TOOL_NAMES.each do |name|
      assert_includes names, name
    end
  end

  test 'browse_repository without view_changesets can list repositories but not list revisions' do
    role = Role.find(1)
    role.remove_permission!(:view_changesets)
    user = User.find(2)

    list_repos = invoke_mcp_tool('list_repositories', user: user, args: {project: 'ecookbook'})
    list_revs = invoke_mcp_tool('list_revisions', user: user, args: {project: 'ecookbook'})

    assert_mcp_ok(list_repos)
    assert_equal(false, list_revs[:ok])
    assert_equal('FORBIDDEN', list_revs.dig(:error, :code))
  ensure
    role.add_permission!(:view_changesets)
  end

  test 'view_changesets without browse_repository can list revisions but not read files' do
    role = Role.find(1)
    role.remove_permission!(:browse_repository)
    user = User.find(2)

    list_revs = invoke_mcp_tool('list_revisions', user: user, args: {project: 'ecookbook', limit: 1})
    get_file = invoke_mcp_tool(
      'get_repository_file',
      user: user,
      args: {project: 'ecookbook', path: README_TXT, revision: '1'}
    )

    assert_mcp_ok(list_revs)
    assert_equal(false, get_file[:ok])
    assert_equal('FORBIDDEN', get_file.dig(:error, :code))
  ensure
    role.add_permission!(:browse_repository)
  end

  test 'get_revision omits file_changes without browse_repository' do
    role = Role.find(1)
    role.remove_permission!(:browse_repository)
    user = User.find(2)

    payload = invoke_mcp_tool(
      'get_revision',
      user: user,
      args: {project: 'ecookbook', revision: '1'}
    )

    assert_mcp_ok(payload)
    assert_equal('1', payload.dig(:data, :revision))
    assert payload.dig(:data, :comments).present?
    assert_not(payload[:data].key?(:file_changes))
    assert_not(payload[:data].key?(:file_changes_pagination))
  ensure
    role.add_permission!(:browse_repository)
  end

  test 'get_revision includes file_changes with browse_repository' do
    user = User.find(2)

    payload = invoke_mcp_tool(
      'get_revision',
      user: user,
      args: {project: 'ecookbook', revision: '1'}
    )

    assert_mcp_ok(payload)
    assert_equal '1', payload.dig(:data, :revision)
    assert payload.dig(:data, :file_changes).present?
    assert payload[:data].key?(:file_changes_pagination)
  end

  test 'browse_repository without view_changesets can get repository metadata' do
    role = Role.find(1)
    role.remove_permission!(:view_changesets)
    user = User.find(2)

    payload = invoke_mcp_tool(
      'get_repository',
      user: user,
      args: {project: 'ecookbook', repository_id: @repository.id.to_s}
    )

    assert_mcp_ok(payload)
  ensure
    role.add_permission!(:view_changesets)
  end

  test 'member without repository permissions gets FORBIDDEN when module enabled' do
    role = Role.find(1)
    role.remove_permission!(:view_changesets)
    role.remove_permission!(:browse_repository)
    user = User.find(2)

    payload = invoke_mcp_tool('list_repositories', user: user, args: {project: 'ecookbook'})

    assert_equal(false, payload[:ok])
    assert_equal('FORBIDDEN', payload.dig(:error, :code))
  ensure
    role.add_permission!(:view_changesets)
    role.add_permission!(:browse_repository)
  end

  test 'member without repository permissions gets FORBIDDEN when module disabled' do
    role = Role.find(1)
    role.remove_permission!(:view_changesets)
    role.remove_permission!(:browse_repository)
    user = User.find(2)
    project = Project.find(1)
    project.disable_module!(:repository)

    payload = invoke_mcp_tool('list_repositories', user: user, args: {project: 'ecookbook'})

    assert_equal(false, payload[:ok])
    assert_equal('FORBIDDEN', payload.dig(:error, :code))
  ensure
    project.enable_module!(:repository)
    role.add_permission!(:view_changesets)
    role.add_permission!(:browse_repository)
  end

  test 'member with repository permissions gets INVALID_STATE when module disabled' do
    user = User.find(2)
    project = Project.find(1)
    project.disable_module!(:repository)

    payload = invoke_mcp_tool('list_repositories', user: user, args: {project: 'ecookbook'})

    assert_equal(false, payload[:ok])
    assert_equal('INVALID_STATE', payload.dig(:error, :code))
  ensure
    project.enable_module!(:repository)
  end

  test 'admin can list repositories when module enabled' do
    payload = invoke_mcp_tool('list_repositories', user: @admin, args: {project: 'ecookbook'})

    assert_mcp_ok(payload)
  end

  test 'user without project access cannot list repositories on private project' do
    outsider = User.find(7)
    payload = invoke_mcp_tool('list_repositories', user: outsider, args: {project: 'onlinestore'})

    assert_equal false, payload[:ok]
    assert_equal 'NOT_FOUND', payload.dig(:error, :code)
  end

  test 'get_repository_diff returns FORBIDDEN without browse_repository' do
    project, user = generate_repository_access_project(permissions: %i[view_project view_changesets])

    payload = invoke_mcp_tool(
      'get_repository_diff',
      user: user,
      args: {project: project.identifier, path: README_TXT, revision: '1'}
    )

    assert_equal(false, payload[:ok])
    assert_equal('FORBIDDEN', payload.dig(:error, :code))
  end

  test 'get_revision returns FORBIDDEN without view_changesets' do
    project, user = generate_repository_access_project(permissions: %i[view_project browse_repository])

    payload = invoke_mcp_tool(
      'get_revision',
      user: user,
      args: {project: project.identifier, revision: '1'}
    )

    assert_equal(false, payload[:ok])
    assert_equal('FORBIDDEN', payload.dig(:error, :code))
  end

  test 'repository_tools_visible is true when user can see a project' do
    _project, user = generate_repository_access_project(permissions: %i[view_project])
    helpers = RedmineMcp::Core::Helpers

    assert helpers.repository_tools_visible?(user)
    assert helpers.repository_tools_visible?(@admin)
    assert_not helpers.repository_tools_visible?(nil)
  end

  test 'project_permission_granted checks role permissions without module gate' do
    project = Project.find(1)
    user = User.find(2)
    helpers = RedmineMcp::Core::Helpers

    assert helpers.project_permission_granted?(user, project, :view_changesets)
    assert user.allowed_to?(:view_changesets, project)

    project.disable_module!(:repository)
    project.reload

    assert helpers.project_permission_granted?(user, project, :view_changesets)
    assert_not(user.allowed_to?(:view_changesets, project))
  ensure
    project.enable_module!(:repository)
  end

  test 'project_permission_granted allows admin without project membership' do
    project = Project.find(2)
    admin = User.find(1)
    helpers = RedmineMcp::Core::Helpers

    assert helpers.project_permission_granted?(admin, project, :view_changesets)
  end

  test 'project_permission_granted denies outsider on private project' do
    project = Project.find(2)
    outsider = User.generate!
    helpers = RedmineMcp::Core::Helpers

    assert_not helpers.project_permission_granted?(outsider, project, :view_changesets)
  end

  test 'project_permission_granted denies member without permission' do
    project, user, = generate_repository_access_project(
      permissions: %i[view_project]
    )
    helpers = RedmineMcp::Core::Helpers

    assert_not helpers.project_permission_granted?(user, project, :view_changesets)
    assert_not helpers.project_permission_granted?(user, project, :browse_repository)
  end

  test 'project_permission_granted accepts browse_repository or view_changesets for discovery' do
    project, user, = generate_repository_access_project(
      permissions: %i[view_project browse_repository]
    )
    helpers = RedmineMcp::Core::Helpers

    assert_not helpers.project_permission_granted?(user, project, :view_changesets)
    assert helpers.project_permission_granted?(user, project, :browse_repository)
    assert helpers.repository_read_allowed?(user, project)
  end

private

  def generate_repository_access_project(permissions:)
    project = Project.generate!(is_public: false)
    project.enabled_module_names = %w[repository issue_tracking]
    project.save!
    role = Role.generate!(permissions: permissions)
    user = User.generate!
    User.add_to_project(user, project, role)
    [project, user, role]
  end

  def scm_entry(kind:, name:, path:, size: nil)
    Redmine::Scm::Adapters::Entry.new(name: name, path: path, kind: kind, size: size)
  end

  def stub_repository_scm(default_branch:, entry: nil, entries: nil, cat: nil, diff: nil)
    Repository.any_instance.stubs(:default_branch).returns(default_branch)
    Repository.any_instance.stubs(:valid_name?).returns(true)
    Repository.any_instance.stubs(:entry).returns(entry) if entry
    Repository.any_instance.stubs(:entries).returns(entries) if entries
    Repository.any_instance.stubs(:cat).returns(cat) if cat
    Repository.any_instance.stubs(:diff).returns(diff) if diff
  end
end
