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

class RedmineMcpInternalRequestTest < RedmineMcpTestCase
  DUPLICATE_RECORD_ERROR = 'Duplicate record'

  test '2xx with JSON body parses object' do
    body = '{"id":42,"name":"Created"}'

    [200, 201, 204].each do |status|
      result = parse_response(status, body)

      assert_equal({'id' => 42, 'name' => 'Created'}, result)
      assert_not RedmineMcp::InternalRequest.error_response?(result)
    end
  end

  test '2xx with blank body returns empty hash' do
    [200, 201, 204].each do |status|
      result = parse_response(status, '')

      assert_empty(result)
      assert_not RedmineMcp::InternalRequest.error_response?(result)
    end
  end

  test '2xx with invalid JSON returns internal server error envelope' do
    result = parse_response(201, '{not-json')

    assert RedmineMcp::InternalRequest.error_response?(result)
    assert_equal I18n.t(:error_mcp_internal_server_error), result[:error]
    assert_equal 'VALIDATION_ERROR', result[:code]
  end

  test '409 with JSON body maps to conflict with response details' do
    payload = {'code' => 'existing_contact', 'existing_contact' => {'id' => 7}}
    result = parse_response(409, JSON.generate(payload))

    assert RedmineMcp::InternalRequest.error_response?(result)
    assert_equal 'CONFLICT', result[:code]
    assert_equal I18n.t(:notice_locking_conflict), result[:error]
    assert_equal({response: payload}, result[:details])
  end

  test '409 with error field in JSON uses extracted message' do
    result = parse_response(409, JSON.generate({'error' => DUPLICATE_RECORD_ERROR}))

    assert_equal 'CONFLICT', result[:code]
    assert_equal DUPLICATE_RECORD_ERROR, result[:error]
    assert_equal({response: {'error' => DUPLICATE_RECORD_ERROR}}, result[:details])
  end

  test '409 with blank body maps to conflict with stale hint' do
    result = parse_response(409, '')

    assert_equal 'CONFLICT', result[:code]
    assert_equal I18n.t(:notice_locking_conflict), result[:error]
    assert_equal({hint: I18n.t(:hint_mcp_conflict_stale)}, result[:details])
  end

private

  def parse_response(status, body_text)
    RedmineMcp::InternalRequest.send(:parse_response, status, body_text)
  end
end
