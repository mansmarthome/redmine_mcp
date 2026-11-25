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

class RedmineMcpBuiltinExtensionsTest < RedmineMcpTestCase
  CHECKLIST_TOOLS = %w[
    list_issue_checklists
    create_checklist
    update_checklist
    delete_checklist
    set_checklist_done
  ].freeze
  TAG_TOOLS = %w[
    list_issue_tags
    get_issue_tags
    set_issue_tags
    add_issue_tags
    remove_issue_tags
    search_issues_by_tags
  ].freeze
  LIMIT = RedmineMcp::ToolDefinition::MAX_FULL_NAME_LENGTH

  test 'checklist and tag tool names stay within the published length limit' do
    CHECKLIST_TOOLS.each do |name|
      full = RedmineMcp::ToolDefinition.full_name_for(:redmine_checklists, name)

      assert_operator full.length, :<=, LIMIT, full
    end
    TAG_TOOLS.each do |name|
      full = RedmineMcp::ToolDefinition.full_name_for(:additional_tags, name)

      assert_operator full.length, :<=, LIMIT, full
    end
  end

  test 'builtin extension files use the target plugin ids' do
    root = File.expand_path('../../lib/redmine_mcp/extensions', __dir__)

    assert File.file?(File.join(root, 'redmine_checklists.rb'))
    assert File.file?(File.join(root, 'additional_tags.rb'))
  end

  test 'builtin extension files qualify annotation constants' do
    root = File.expand_path('../../lib/redmine_mcp/extensions', __dir__)
    bare = /(?<![:\w])(?:READ_ONLY|CREATE|UPDATE|DELETE)_ANNOTATIONS\b/

    %w[additional_tags.rb redmine_checklists.rb].each do |name|
      source = File.read(File.join(root, name))

      assert_no_match bare, source, name
    end
  end
end

class RedmineMcpChecklistsExtensionTest < RedmineMcpTestCase
  setup do
    skip('redmine_checklists is not installed') unless Redmine::Plugin.installed?(:redmine_checklists)
    skip('redmine_mcp extension is disabled') if RedmineMcp::Settings.extension_disabled?(:redmine_checklists)

    plugin = Redmine::Plugin.find(:redmine_checklists)
    assert RedmineMcp::ExtensionLoader.load_plugin_extension(plugin)
    assert mcp_registry.tool('redmine_checklists_create_checklist')
  end

  test 'create_checklist rejects a call without subject' do
    payload = invoke_mcp_tool(
      'redmine_checklists_create_checklist',
      user: User.find(1),
      args: {issue_id: 1}
    )

    assert_equal false, payload[:ok]
    assert_equal 'VALIDATION_ERROR', payload.dig(:error, :code)
  end

  test 'update_checklist rejects a call that changes nothing' do
    payload = invoke_mcp_tool(
      'redmine_checklists_update_checklist',
      user: User.find(1),
      args: {checklist_id: 1}
    )

    assert_equal false, payload[:ok]
    assert_equal 'VALIDATION_ERROR', payload.dig(:error, :code)
  end

  test 'create_checklist returns a schema-valid item' do
    subject = "MCP checklist #{SecureRandom.hex(4)}"
    checklist_id = nil
    payload = invoke_mcp_tool(
      'redmine_checklists_create_checklist',
      user: User.find(1),
      args: {issue_id: 1, subject: subject, is_done: false}
    )

    assert_mcp_ok(payload)
    assert_mcp_output_schema('redmine_checklists_create_checklist', payload)
    assert_equal subject, payload.dig(:data, :checklist, :subject)
    assert_equal false, payload.dig(:data, :checklist, :is_done)
    checklist_id = payload.dig(:data, :checklist, :id)

    listed = invoke_mcp_tool(
      'redmine_checklists_list_issue_checklists',
      user: User.find(1),
      args: {issue_id: 1, limit: 100}
    )
    assert_mcp_ok(listed)
    assert_mcp_output_schema('redmine_checklists_list_issue_checklists', listed)
    assert listed.dig(:data, :items).any? { |item| item[:id] == checklist_id }

    done = invoke_mcp_tool(
      'redmine_checklists_set_checklist_done',
      user: User.find(1),
      args: {checklist_id: checklist_id, is_done: true}
    )
    assert_mcp_ok(done)
    assert_equal true, done.dig(:data, :checklist, :is_done)

    removed = invoke_mcp_tool(
      'redmine_checklists_delete_checklist',
      user: User.find(1),
      args: {checklist_id: checklist_id, confirm_delete: true}
    )
    assert_mcp_ok(removed)
    assert_equal checklist_id, removed.dig(:data, :deleted_checklist_id)
    checklist_id = nil
  ensure
    Checklist.where(id: checklist_id).delete_all if checklist_id && defined?(Checklist)
  end
end

class RedmineMcpAdditionalTagsExtensionTest < RedmineMcpTestCase
  setup do
    skip('additional_tags is not installed') unless Redmine::Plugin.installed?(:additional_tags)
    skip('redmine_mcp extension is disabled') if RedmineMcp::Settings.extension_disabled?(:additional_tags)

    plugin = Redmine::Plugin.find(:additional_tags)
    assert RedmineMcp::ExtensionLoader.load_plugin_extension(plugin)
    assert mcp_registry.tool('redmine_additional_tags_set_issue_tags')
  end

  test 'add_issue_tags rejects an empty tag list' do
    payload = invoke_mcp_tool(
      'redmine_additional_tags_add_issue_tags',
      user: User.find(1),
      args: {issue_id: 1, tags: []}
    )

    assert_equal false, payload[:ok]
    assert_equal 'VALIDATION_ERROR', payload.dig(:error, :code)
  end

  test 'search_issues_by_tags rejects an unknown match value' do
    payload = invoke_mcp_tool(
      'redmine_additional_tags_search_issues_by_tags',
      user: User.find(1),
      args: {tags: ['mcp'], match: 'none'}
    )

    assert_equal false, payload[:ok]
    assert_equal 'VALIDATION_ERROR', payload.dig(:error, :code)
  end

  test 'set_issue_tags replaces tags and get_issue_tags returns them' do
    tag = "mcp-ext-#{SecureRandom.hex(4)}"
    with_issue_tags_enabled do
      payload = invoke_mcp_tool(
        'redmine_additional_tags_set_issue_tags',
        user: User.find(1),
        args: {issue_id: 1, tags: [tag]}
      )

      assert_mcp_ok(payload)
      assert_mcp_output_schema('redmine_additional_tags_set_issue_tags', payload)
      assert_includes payload.dig(:data, :tags), tag

      fetched = invoke_mcp_tool(
        'redmine_additional_tags_get_issue_tags',
        user: User.find(1),
        args: {issue_id: 1}
      )
      assert_mcp_ok(fetched)
      assert_includes fetched.dig(:data, :tags), tag

      cleared = invoke_mcp_tool(
        'redmine_additional_tags_set_issue_tags',
        user: User.find(1),
        args: {issue_id: 1, tags: []}
      )
      assert_mcp_ok(cleared)
      assert_not_includes cleared.dig(:data, :tags), tag
    end
  end

  private

  def with_issue_tags_enabled
    previous = Setting.plugin_additional_tags
    current = previous.respond_to?(:to_h) ? previous.to_h : {}
    Setting.plugin_additional_tags = current.merge('active_issue_tags' => '1')
    yield
  ensure
    Setting.plugin_additional_tags = previous if defined?(previous)
  end
end
