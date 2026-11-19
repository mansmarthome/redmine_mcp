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

class RedmineMcpGetAttachmentTest < RedmineMcpTestCase
  TEXT_PLAIN = 'text/plain'

  def setup
    super
    set_tmp_attachments_directory
    @admin = User.find(1)
    @member = User.find(2)
  end

  test 'get_attachment returns metadata without include_content' do
    attachment = create_issue_attachment(content: 'meta-only', filename: 'meta.txt', content_type: TEXT_PLAIN)

    payload = invoke_mcp_tool('get_attachment', user: @admin, args: {attachment_id: attachment.id})

    assert payload[:ok], "expected ok payload, got: #{payload.inspect}"
    assert_equal attachment.id, payload.dig(:data, :attachment_id)
    assert payload.dig(:data, :content_url).present?
    assert_nil payload.dig(:data, :content_base64)
    assert_mcp_output_schema('get_attachment', payload)
  end

  test 'get_attachment with include_content false returns metadata only' do
    attachment = create_issue_attachment(content: 'meta-only', filename: 'meta.txt', content_type: TEXT_PLAIN)

    payload = invoke_mcp_tool('get_attachment', user: @admin, args: {attachment_id: attachment.id, include_content: false})

    assert payload[:ok], "expected ok payload, got: #{payload.inspect}"
    assert_nil payload.dig(:data, :content_base64)
  end

  test 'get_attachment with include_content true returns content_base64 for issue attachment' do
    content = "PK\x03\x04fake-docx-zip-body"
    attachment = create_issue_attachment(content: content, filename: 'spec.docx', content_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
    downloads_before = attachment.downloads

    payload = invoke_mcp_tool('get_attachment', user: @admin, args: content_args(attachment.id))

    assert payload[:ok], "expected ok payload, got: #{payload.inspect}"
    assert_equal attachment.id, payload.dig(:data, :attachment_id)
    assert_equal 'spec.docx', payload.dig(:data, :filename)
    assert payload.dig(:data, :content_url).present?
    assert_equal attachment.filesize, payload.dig(:data, :size)
    decoded = Base64.strict_decode64(payload.dig(:data, :content_base64))

    assert_equal content, decoded
    assert decoded.start_with?('PK')
    assert_equal downloads_before, attachment.reload.downloads
    assert_nil payload.dig(:data, :diskfile)
    assert_not_includes payload.to_json, Attachment.storage_path.to_s
    assert_mcp_output_schema('get_attachment', payload)
  end

  test 'get_attachment returns empty content_base64 for empty file when include_content true' do
    attachment = create_issue_attachment(content: '', filename: 'empty.bin', content_type: 'application/octet-stream')

    payload = invoke_mcp_tool('get_attachment', user: @admin, args: content_args(attachment.id))

    assert payload[:ok], "expected ok payload, got: #{payload.inspect}"
    assert_equal 0, payload.dig(:data, :size)
    assert_equal '', Base64.strict_decode64(payload.dig(:data, :content_base64))
  end

  test 'get_attachment with include_content true returns FILE_TOO_LARGE when filesize exceeds limit' do
    attachment = create_issue_attachment(
      content: 'small',
      filename: 'big.bin',
      content_type: RedmineMcp::Core::Helpers::DEFAULT_CONTENT_TYPE
    )
    attachment.update_column(:filesize, RedmineMcp::Core::Helpers::MAX_DOWNLOAD_BYTES + 1)
    File.binwrite(attachment.diskfile, 'x' * (RedmineMcp::Core::Helpers::MAX_DOWNLOAD_BYTES + 1))
    downloads_before = attachment.downloads

    payload = invoke_mcp_tool('get_attachment', user: @admin, args: content_args(attachment.id))

    assert_equal false, payload[:ok]
    assert_equal 'FILE_TOO_LARGE', payload.dig(:error, :code)
    assert_equal RedmineMcp::Core::Helpers::MAX_DOWNLOAD_BYTES + 1, payload.dig(:error, :details, :size)
    assert_equal RedmineMcp::Core::Helpers::MAX_DOWNLOAD_BYTES, payload.dig(:error, :details, :max_bytes)
    assert_equal downloads_before, attachment.reload.downloads
  end

  test 'get_attachment metadata only succeeds for oversized file on disk' do
    attachment = create_issue_attachment(
      content: 'small',
      filename: 'big.bin',
      content_type: RedmineMcp::Core::Helpers::DEFAULT_CONTENT_TYPE
    )
    attachment.update_column(:filesize, RedmineMcp::Core::Helpers::MAX_DOWNLOAD_BYTES + 1)
    File.binwrite(attachment.diskfile, 'x' * (RedmineMcp::Core::Helpers::MAX_DOWNLOAD_BYTES + 1))

    payload = invoke_mcp_tool('get_attachment', user: @admin, args: {attachment_id: attachment.id})

    assert payload[:ok], "expected ok payload, got: #{payload.inspect}"
    assert_nil payload.dig(:data, :content_base64)
  end

  test 'get_attachment with include_content true returns FILE_TOO_LARGE when disk file exceeds limit despite small metadata' do
    attachment = create_issue_attachment(
      content: 'tiny',
      filename: 'mismatch.bin',
      content_type: RedmineMcp::Core::Helpers::DEFAULT_CONTENT_TYPE
    )
    oversized = RedmineMcp::Core::Helpers::MAX_DOWNLOAD_BYTES + 1
    File.binwrite(attachment.diskfile, 'x' * oversized)
    attachment.update_column(:filesize, 4)
    downloads_before = attachment.downloads

    payload = invoke_mcp_tool('get_attachment', user: @admin, args: content_args(attachment.id))

    assert_equal false, payload[:ok]
    assert_equal 'FILE_TOO_LARGE', payload.dig(:error, :code)
    assert_equal oversized, payload.dig(:error, :details, :size)
    assert_equal RedmineMcp::Core::Helpers::MAX_DOWNLOAD_BYTES, payload.dig(:error, :details, :max_bytes)
    assert_equal downloads_before, attachment.reload.downloads
  end

  test 'get_attachment with include_content true returns actual content size when metadata differs' do
    attachment = create_issue_attachment(
      content: 'hello',
      filename: 'size.bin',
      content_type: RedmineMcp::Core::Helpers::DEFAULT_CONTENT_TYPE
    )
    File.binwrite(attachment.diskfile, 'hello-world')
    attachment.update_column(:filesize, 1)
    downloads_before = attachment.downloads

    payload = invoke_mcp_tool('get_attachment', user: @admin, args: content_args(attachment.id))

    assert payload[:ok], "expected ok payload, got: #{payload.inspect}"
    assert_equal 11, payload.dig(:data, :size)
    assert_equal 'hello-world', Base64.strict_decode64(payload.dig(:data, :content_base64))
    assert_equal downloads_before, attachment.reload.downloads
  end

  test 'get_attachment denies invisible attachment' do
    attachment = Attachment.create!(
      file: mock_file(original_filename: 'orphan.txt', content_type: TEXT_PLAIN, content: 'secret'),
      author: @admin
    )

    payload = invoke_mcp_tool('get_attachment', user: @member, args: {attachment_id: attachment.id})

    assert_equal false, payload[:ok]
    assert_equal 'NOT_FOUND', payload.dig(:error, :code)
  end

  test 'get_attachment with include_content true denies invisible attachment' do
    attachment = Attachment.create!(
      file: mock_file(original_filename: 'orphan.txt', content_type: TEXT_PLAIN, content: 'secret'),
      author: @admin
    )

    payload = invoke_mcp_tool('get_attachment', user: @member, args: content_args(attachment.id))

    assert_equal false, payload[:ok]
    assert_equal 'NOT_FOUND', payload.dig(:error, :code)
  end

  test 'get_attachment returns NOT_FOUND for missing id' do
    payload = invoke_mcp_tool('get_attachment', user: @admin, args: {attachment_id: 99_999})

    assert_equal false, payload[:ok]
    assert_equal 'NOT_FOUND', payload.dig(:error, :code)
  end

  test 'get_attachment with include_content true returns NOT_FOUND for missing id' do
    payload = invoke_mcp_tool('get_attachment', user: @admin, args: content_args(99_999))

    assert_equal false, payload[:ok]
    assert_equal 'NOT_FOUND', payload.dig(:error, :code)
  end

  test 'get_attachment with include_content true falls back to octet-stream when content_type blank' do
    attachment = create_issue_attachment(content: 'plain', filename: 'no-mime.bin', content_type: TEXT_PLAIN)
    attachment.update_column(:content_type, nil)

    payload = invoke_mcp_tool('get_attachment', user: @admin, args: content_args(attachment.id))

    assert payload[:ok], "expected ok payload, got: #{payload.inspect}"
    assert_equal RedmineMcp::Core::Helpers::DEFAULT_CONTENT_TYPE, payload.dig(:data, :content_type)
  end

  test 'download_attachment tool is not registered' do
    assert_nil mcp_registry.tool('download_attachment')
    assert_nil mcp_registry.tool('redmine_download_attachment')
  end

  def content_args(attachment_id)
    {attachment_id: attachment_id, include_content: true}
  end

  def create_issue_attachment(content:, filename:, content_type:)
    upload_io = RedmineMcp::Core::Helpers.build_upload_io(content, filename: filename, content_type: content_type)
    attachment = Attachment.new(container: Issue.find(1), author: @admin)
    attachment.file = upload_io
    attachment.filename = filename
    attachment.save!
    attachment
  end
end
