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
  class ServerBuilder
    SERVER_NAME = 'redmine_mcp'

    class << self
      def build(user:)
        registry = Registry.instance
        server_context = {
          user_id: user.id,
          login: user.login
        }

        listed_tools = registry.to_mcp_tools(user)
        server = McpServer.new(
          name: SERVER_NAME,
          title: I18n.t(:label_redmine_mcp),
          version: RedmineMcp::VERSION,
          instructions: server_instructions,
          tools: listed_tools + registry.to_mcp_alias_tools(user),
          listed_tool_names: listed_tools.map(&:name_value),
          prompts: registry.to_mcp_prompts(user),
          resources: registry.to_mcp_resources(user),
          server_context: server_context,
          configuration: MCP::Configuration.new(
            protocol_version: '2025-11-25',
            validate_tool_call_arguments: false
          )
        )

        server.resources_read_handler do |params|
          read_resource(params[:uri], user)
        end

        server
      end

    private

      def server_instructions
        parts = [I18n.t(:text_redmine_mcp_server_instructions).strip]
        formatting_hint = text_formatting_instructions
        parts << formatting_hint if formatting_hint
        parts << I18n.t(:text_redmine_mcp_server_instructions_read_only) if Settings.read_only?
        parts.join("\n\n")
      end

      def text_formatting_instructions
        format_name = Setting.text_formatting.to_s
        case format_name
        when 'common_mark'
          I18n.t(:text_redmine_mcp_server_instructions_text_formatting_common_mark)
        when 'textile'
          I18n.t(:text_redmine_mcp_server_instructions_text_formatting_textile)
        when ''
          I18n.t(:text_redmine_mcp_server_instructions_text_formatting_none)
        else
          if Settings.text_formatting_registered?(format_name)
            I18n.t(:text_redmine_mcp_server_instructions_text_formatting_other, format_name: format_name)
          else
            I18n.t(
              :text_redmine_mcp_server_instructions_text_formatting_unavailable,
              format_name: format_name
            )
          end
        end
      end

      def read_resource(uri, user)
        resource = Registry.instance.find_resource(uri)
        raise MCP::Server::ResourceNotFoundError.new(uri, {uri: uri}) unless resource

        unless resource.allowed_for?(user, {uri: uri})
          Logger.warn("permission denied for resource #{uri}, user=#{user.login}")
          raise MCP::Server::ResourceNotFoundError.new(uri, {uri: uri})
        end

        payload = resource.handler.call({uri: uri}, user: user, login: user.login, user_id: user.id)
        content = normalize_resource_payload(payload, uri, resource.mime_type)
        [content]
      end

      def normalize_resource_payload(payload, uri, mime_type)
        case payload
        when Hash
          {
            uri: uri,
            mimeType: payload[:mime_type] || payload['mime_type'] || mime_type,
            text: payload[:text] || payload['text'] || JSON.generate(payload)
          }
        when String
          {uri: uri, mimeType: mime_type, text: payload}
        else
          {uri: uri, mimeType: mime_type, text: JSON.generate(payload)}
        end
      end
    end
  end
end
