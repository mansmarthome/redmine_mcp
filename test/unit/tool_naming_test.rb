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

# SPEC: docs/spec/04-extensions.md — tool name prefix, 45-char limit, legacy names.
class RedmineMcpToolNamingTest < RedmineMcpTestCase
  OUTPUT_SCHEMA = RedmineMcp::SchemaNormalizer.envelope_output(
    type: 'object',
    properties: {id: {type: 'integer'}}
  ).freeze
  LIMIT = RedmineMcp::ToolDefinition::MAX_FULL_NAME_LENGTH

  test 'redmine_ plugin id is not doubled in the prefix' do
    assert_equal 'redmine_naming_a_bar', RedmineMcp::ToolDefinition.full_name_for(:redmine_naming_a, 'bar')
    assert_equal 'redmine_naming_a_bar', RedmineMcp::ToolDefinition.full_name_for(:naming_a, 'bar')
    assert_equal 'redmine_bar', RedmineMcp::ToolDefinition.full_name_for(:redmine, 'bar')
  end

  test 'legacy full name exists only for redmine_ plugin ids' do
    assert_equal 'redmine_redmine_naming_a_bar', RedmineMcp::ToolDefinition.legacy_full_name_for(:redmine_naming_a, 'bar')
    assert_nil RedmineMcp::ToolDefinition.legacy_full_name_for(:naming_a, 'bar')
    assert_nil RedmineMcp::ToolDefinition.legacy_full_name_for(:redmine, 'bar')
  end

  test 'declared alias names resolve to the canonical tool and are not listed' do
    extension = build_extension(:redmine_naming_b)
    extension.register_tool(**tool_args('bar', aliases: ['old_bar']))
    tool = mcp_registry.tool('redmine_naming_b_bar')

    assert_not_nil tool
    %w[redmine_naming_b_old_bar redmine_redmine_naming_b_old_bar].each do |name|
      assert_same tool, mcp_registry.tool(name), name
    end

    admin = User.find(1)
    listed = mcp_registry.to_mcp_tools(admin).map(&:name_value)
    alias_listed = mcp_registry.to_mcp_alias_tools(admin).map(&:name_value)

    assert_includes listed, 'redmine_naming_b_bar'
    assert_includes alias_listed, 'redmine_naming_b_old_bar'
    assert_not_includes listed, 'redmine_naming_b_old_bar'
    assert_not_includes listed, 'redmine_redmine_naming_b_old_bar'
  end

  test 'legacy and alias names resolve to the canonical tool and are not listed' do
    extension = build_extension(:redmine_naming_b2)
    extension.register_tool(**tool_args('bar'))
    tool = mcp_registry.tool('redmine_naming_b2_bar')

    assert_not_nil tool
    assert_same tool, mcp_registry.tool('redmine_redmine_naming_b2_bar')

    admin = User.find(1)
    listed = mcp_registry.to_mcp_tools(admin).map(&:name_value)
    alias_listed = mcp_registry.to_mcp_alias_tools(admin).map(&:name_value)

    assert_includes listed, 'redmine_naming_b2_bar'
    assert_includes alias_listed, 'redmine_redmine_naming_b2_bar'
    assert_not_includes listed, 'redmine_redmine_naming_b2_bar'
  end

  test 'tool name at the limit registers, one character over is skipped' do
    extension = build_extension(:redmine_naming_c)
    prefix = 'redmine_naming_c_'
    fits = 'a' * (LIMIT - prefix.length)
    too_long = 'b' * (LIMIT - prefix.length + 1)

    assert_not_nil extension.register_tool(**tool_args(fits))
    assert_nil extension.register_tool(**tool_args(too_long))
    assert_nil mcp_registry.tool("#{prefix}#{too_long}")
    assert_not_nil extension.register_tool(**tool_args('after_skip'))
  end

  test 'extend_tool accepts a legacy name' do
    extension = build_extension(:redmine_naming_d)
    extension.register_tool(**tool_args('bar'))
    extension.extend_tool('redmine_redmine_naming_d_bar', extra_params: {naming_extra: {type: 'string'}})

    assert_equal 1, mcp_registry.tool_extensions('redmine_naming_d_bar').size
  end

  test 'every registered tool name fits the client limit' do
    mcp_registry.instance_variable_get(:@tools).each_key do |name|
      assert_nil RedmineMcp::ToolDefinition.full_name_error(name), name
      assert_not name.start_with?('redmine_redmine_'), name
    end
  end

private

  def build_extension(id)
    Module.new do
      extend RedmineMcp::ExtensionApi

      plugin_id id
    end
  end

  def tool_args(name, **options)
    {
      name: name,
      description: 'naming test tool',
      input_schema: {properties: {}},
      output_schema: OUTPUT_SCHEMA,
      permission: :view_issues,
      handler: ->(_args, _context) { {ok: true} },
      **options
    }
  end
end
