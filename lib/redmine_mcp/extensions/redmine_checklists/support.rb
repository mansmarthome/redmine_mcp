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
    module RedmineChecklists
      # Reads and writes RedmineUP checklist items through Checklist and Issue
      # nested attributes. Journal rows use JournalChecklistHistory when save_log
      # is on, which is the plugin's own history object. The REST done action is
      # not API-authenticated and its journal wrapper is a no-op, so writes go
      # through the model after the MCP permission check.
      module Support
        module_function

        def with_user(user)
          previous = User.current
          User.current = user
          yield
        ensure
          User.current = previous
        end

        def item_payload(item)
          {
            id: item.id,
            issue_id: item.issue_id,
            subject: item.subject.to_s,
            is_done: flag?(item.is_done),
            is_section: flag?(item.is_section),
            position: item.position,
            created_at: timestamp(item.created_at),
            updated_at: timestamp(item.updated_at)
          }
        end

        def summary(issue)
          items = issue.checklists.reject { |item| flag?(item.is_section) }
          {total: items.size, done: items.count { |item| flag?(item.is_done) }}
        end

        def find_visible_item(user, checklist_id)
          return nil unless defined?(::Checklist)

          item = ::Checklist.joins(:issue).merge(Issue.visible(user)).find_by(id: checklist_id.to_i)
          return nil unless item&.issue&.visible?(user)
          return nil unless user.allowed_to?(:view_checklists, item.issue.project)

          item
        end

        def create!(issue, attrs, user)
          before = snapshot_items(issue)
          item = issue.checklists.build
          item.safe_attributes = {
            'subject' => attrs[:subject].to_s,
            'is_done' => attrs[:is_done] == true,
            'is_section' => attrs[:is_section] == true,
            'position' => attrs[:position].presence || next_position(issue)
          }
          return Core::Helpers.model_errors(item) unless item.save

          finish_write!(issue, before, user)
          item.reload
        end

        def update!(item, attrs, user)
          issue = item.issue
          before = snapshot_items(issue)
          values = {}
          values['subject'] = attrs[:subject].to_s if attrs.key?(:subject)
          values['is_done'] = attrs[:is_done] == true if attrs.key?(:is_done)
          values['is_section'] = attrs[:is_section] == true if attrs.key?(:is_section)
          values['position'] = attrs[:position] if attrs.key?(:position)
          item.safe_attributes = values
          return item if unchanged?(item)

          return Core::Helpers.model_errors(item) unless item.save

          finish_write!(issue, before, user)
          item.reload
        end

        def set_done!(item, is_done, user)
          return item if flag?(item.is_done) == is_done

          issue = item.issue
          before = snapshot_items(issue)
          item.is_done = is_done
          return Core::Helpers.model_errors(item) unless item.save

          finish_write!(issue, before, user)
          item.reload
        end

        def delete!(item, user)
          issue = item.issue
          checklist_id = item.id
          before = snapshot_items(issue)
          item.destroy!
          finish_write!(issue, before, user)
          {deleted_checklist_id: checklist_id, issue_id: issue.id}
        end

        def stale_result(record, expected_updated_at)
          return nil if expected_updated_at.blank? || record.nil?

          expected = parse_time(expected_updated_at)
          unless expected
            return Core::Helpers.mcp_error(
              code: 'VALIDATION_ERROR',
              message: I18n.t(:error_mcp_invalid_parameters),
              field: 'expected_updated_at'
            )
          end

          actual = record.updated_at
          return nil if actual && actual.to_i == expected.to_i

          Core::Helpers.mcp_error(
            code: 'CONFLICT',
            message: I18n.t(:notice_locking_conflict),
            details: {
              updated_at: timestamp(actual),
              hint: I18n.t(:hint_mcp_conflict_stale)
            }
          )
        end

        def timestamp(value)
          value&.iso8601
        end

        def next_position(issue)
          (issue.checklists.map(&:position).compact.max || 0) + 1
        end

        def unchanged?(item)
          !item.changed?
        end

        def finish_write!(issue, before, user)
          recalc!(issue)
          record_journal(issue, before, user)
        end

        def recalc!(issue)
          return unless defined?(::Checklist) && ::Checklist.respond_to?(:recalc_issue_done_ratio)
          return unless defined?(::RedmineChecklists) && ::RedmineChecklists.respond_to?(:issue_done_ratio?)
          return unless ::RedmineChecklists.issue_done_ratio?
          return unless Setting.issue_done_ratio == 'issue_field'

          ::Checklist.recalc_issue_done_ratio(issue.id)
        end

        def record_journal(issue, before, user)
          return unless log_changes?
          return unless defined?(::JournalChecklistHistory)

          after = issue.checklists.reload.to_a
          return if snapshot(before) == snapshot(after)
          return if recent_checklist_journal?(issue, user)

          issue.init_journal(user)
          issue.current_journal.details << ::JournalChecklistHistory.new(before, after).journal_details
          issue.save!
        end

        def log_changes?
          return false unless defined?(::RedmineChecklists) && ::RedmineChecklists.respond_to?(:settings)

          value = ::RedmineChecklists.settings['save_log']
          value == true || %w[1 true yes on].include?(value.to_s.strip.downcase) || value.to_i.positive?
        rescue StandardError
          false
        end

        def recent_checklist_journal?(issue, user)
          issue.journals.joins(:details)
               .where(user_id: user.id, journal_details: {prop_key: 'checklist'})
               .where('journals.created_on >= ?', 2.seconds.ago)
               .exists?
        end

        def snapshot_items(issue)
          issue.checklists.map(&:dup)
        end

        def snapshot(items)
          items.map { |item| [item.id, item.subject.to_s, flag?(item.is_done), flag?(item.is_section), item.position] }
        end

        def flag?(value)
          value == true || value.to_s == '1'
        end

        def parse_time(value)
          Time.iso8601(value.to_s)
        rescue ArgumentError
          Time.zone.parse(value.to_s)
        end
      end
    end
  end
end
