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

class RedmineMcpToolExecutionTest < RedmineMcpTestCase
  SUBPROJECT_SEARCH_SUBJECT = 'MCP unique subproject search xyz'
  fixtures :queries, :boards, :messages, :projects_trackers, :issue_categories,
           :time_entries, :journals, :journal_details

  test 'get_issue returns success envelope for visible issue' do
    admin = User.find(1)
    payload = invoke_mcp_tool('get_issue', user: admin, args: {issue_id: 1})

    assert payload[:ok]
    assert_equal 1, payload.dig(:data, :id)
    assert_equal "#{Setting.protocol}://#{Setting.host_name}/issues/1", payload.dig(:data, :url)
    assert_empty payload.dig(:data, :journals)
    assert_empty payload.dig(:data, :attachments)
  end

  test 'get_issue returns null url when host_name is blank' do
    admin = User.find(1)

    with_settings host_name: '' do
      payload = invoke_mcp_tool('get_issue', user: admin, args: {issue_id: 1})

      assert payload[:ok]
      assert_nil payload.dig(:data, :url)
    end
  end

  test 'list_issues returns paginated envelope' do
    admin = User.find(1)
    payload = invoke_mcp_tool('list_issues', user: admin, args: {project: 'ecookbook', limit: 5})

    assert payload[:ok]
    assert_kind_of Array, payload.dig(:data, :items)
    first = payload.dig(:data, :items).first

    assert first
    assert_equal "#{Setting.protocol}://#{Setting.host_name}/issues/#{first[:id]}", first[:url]
    assert payload.dig(:meta, :total_count)
    assert payload.dig(:meta, :has_more).in?([true, false])
  end

  test 'get_issue is idempotent' do
    admin = User.find(1)
    before = Issue.find(1).journals.count

    first = invoke_mcp_tool('get_issue', user: admin, args: {issue_id: 1})
    second = invoke_mcp_tool('get_issue', user: admin, args: {issue_id: 1})

    assert first[:ok]
    assert second[:ok]
    assert_equal first.dig(:data, :id), second.dig(:data, :id)
    assert_equal before, Issue.find(1).journals.count
  end

  test 'delete_issue without confirmation returns invalid state' do
    admin = User.find(1)
    payload = invoke_mcp_tool('delete_issue', user: admin, args: {issue_id: 1})

    assert_equal false, payload[:ok]
    assert_equal 'INVALID_STATE', payload.dig(:error, :code)
    assert_equal 'confirmation_required', payload.dig(:error, :details, :reason)
    assert Issue.exists?(1)
  end

  test 'get_issue missing issue returns not found' do
    admin = User.find(1)
    payload = invoke_mcp_tool('get_issue', user: admin, args: {issue_id: 99_999})

    assert_equal false, payload[:ok]
    assert_equal 'NOT_FOUND', payload.dig(:error, :code)
  end

  test 'board and query not found keep NOT_FOUND in Russian' do
    admin = User.find(1)
    I18n.with_locale(:ru) do
      query = invoke_mcp_tool('list_issues', user: admin, args: {query_id: 99_999})
      board = RedmineMcp::ToolResponse.from_handler_result(
        RedmineMcp::Core::Tools::Boards.get_board_message({message_id: 99_999}, {user: admin})
      )

      assert_equal 'NOT_FOUND', query.dig(:error, :code)
      assert_equal I18n.t(:error_mcp_query_not_found), query.dig(:error, :message)
      assert_equal 'NOT_FOUND', board.dig(:error, :code)
      assert_equal I18n.t(:error_mcp_board_message_not_found), board.dig(:error, :message)
    end
  end

  test 'create_issue blocked in read only mode' do
    admin = User.find(1)
    with_read_only_mcp!

    payload = invoke_mcp_tool(
      'create_issue',
      user: admin,
      args: {project: 'ecookbook', subject: 'Blocked by read only'}
    )

    assert_equal false, payload[:ok]
    assert_equal 'INVALID_STATE', payload.dig(:error, :code)
    assert_equal 'read_only_mode', payload.dig(:error, :details, :reason)
  end

  test 'summarize_project_status returns zeros on empty project' do
    project, user = generate_stats_project
    payload = invoke_mcp_tool('summarize_project_status', user: user, args: {project: project.identifier, days: 30})

    assert_mcp_ok(payload)
    data = payload[:data]

    assert_equal 0, data[:totals][:issues_count]
    assert_equal 0, data[:overdue_count]
    assert_equal 0, data[:unassigned_count]
    assert_equal 0, data[:stale_issues_count]
    assert_equal 0, data[:issues_closed_during_period]
    assert_equal 0, data[:reopened_count]
    assert_nil data[:estimated_hours]
    assert_in_delta 0.0, data[:spent_hours]
    assert_nil data[:average_resolution_hours]
    assert_equal 0, data[:estimation_accuracy][:issues_count]
    assert_in_delta 0.0, data[:estimation_accuracy][:total_estimated]
    assert_in_delta 0.0, data[:estimation_accuracy][:total_spent]
  end

  test 'summarize_project_status rejects days outside 1..365' do
    project, user = generate_stats_project

    low = invoke_mcp_tool('summarize_project_status', user: user, args: {project: project.identifier, days: 0})
    high = invoke_mcp_tool('summarize_project_status', user: user, args: {project: project.identifier, days: 500})

    assert_equal false, low[:ok]
    assert_equal 'VALIDATION_ERROR', low.dig(:error, :code)
    assert_equal false, high[:ok]
    assert_equal 'VALIDATION_ERROR', high.dig(:error, :code)
  end

  test 'summarize_project_status overdue count includes only open past-due issues' do
    project, user = generate_stats_project
    today = user.today
    Issue.generate!(project: project, subject: 'overdue open', due_date: today - 1)
    Issue.generate!(project: project, subject: 'future open', due_date: today + 2)
    closed = Issue.generate!(project: project, subject: 'overdue closed', due_date: today - 1)
    close_issue!(closed, at: Time.current)

    payload = invoke_mcp_tool('summarize_project_status', user: user, args: {project: project.identifier, days: 30})

    assert_mcp_ok(payload)
    assert_equal 1, payload.dig(:data, :overdue_count)
  end

  test 'summarize_project_status stale count uses the days window' do
    project, user = generate_stats_project
    stale = Issue.generate!(project: project, subject: 'stale open')
    fresh = Issue.generate!(project: project, subject: 'fresh open')
    stale.update_columns(updated_on: 40.days.ago)
    fresh.update_columns(updated_on: 1.day.ago)

    payload = invoke_mcp_tool('summarize_project_status', user: user, args: {project: project.identifier, days: 30})

    assert_mcp_ok(payload)
    assert_equal 1, payload.dig(:data, :stale_issues_count)
  end

  test 'summarize_project_status closed during period ignores older closures' do
    project, user = generate_stats_project
    recent = Issue.generate!(project: project, subject: 'closed recently')
    old = Issue.generate!(project: project, subject: 'closed long ago')
    close_issue!(recent, at: 2.days.ago)
    close_issue!(old, at: 40.days.ago)

    payload = invoke_mcp_tool('summarize_project_status', user: user, args: {project: project.identifier, days: 30})

    assert_mcp_ok(payload)
    assert_equal 1, payload.dig(:data, :issues_closed_during_period)
  end

  test 'summarize_project_status hides spent hours without view_time_entries' do
    project, user, role = generate_stats_project
    issue = Issue.generate!(project: project, subject: 'with time')
    TimeEntry.generate!(project: project, issue: issue, user: user, hours: 2.5)

    allowed = invoke_mcp_tool('summarize_project_status', user: user, args: {project: project.identifier, days: 30})
    role.remove_permission!(:view_time_entries)
    denied = invoke_mcp_tool('summarize_project_status', user: user.reload, args: {project: project.identifier, days: 30})

    assert_mcp_ok(allowed)
    assert_mcp_ok(denied)
    assert_in_delta 2.5, allowed.dig(:data, :spent_hours)
    assert_nil denied.dig(:data, :spent_hours)
  end

  test 'summarize_project_status hides estimation_accuracy total_spent without view_time_entries' do
    project, user, role = generate_stats_project
    issue = Issue.generate!(project: project, subject: 'closed with estimate', estimated_hours: 4.0)
    close_issue!(issue, at: Time.current)
    TimeEntry.generate!(project: project, issue: issue, user: user, hours: 3.0)

    allowed = invoke_mcp_tool('summarize_project_status', user: user, args: {project: project.identifier, days: 30})
    role.remove_permission!(:view_time_entries)
    denied = invoke_mcp_tool('summarize_project_status', user: user.reload, args: {project: project.identifier, days: 30})

    assert_mcp_ok(allowed)
    assert_mcp_ok(denied)
    assert_in_delta 3.0, allowed.dig(:data, :estimation_accuracy, :total_spent)
    assert_nil denied.dig(:data, :estimation_accuracy)
    assert_nil denied.dig(:data, :spent_hours)
  end

  test 'summarize_project_status resolution and estimation accuracy use closed issues with spent time' do
    project, user = generate_stats_project
    created_on = 10.hours.ago
    closed_on = Time.current
    matched = Issue.generate!(project: project, subject: 'estimated spent', estimated_hours: 4.0)
    unmatched = Issue.generate!(project: project, subject: 'estimated only', estimated_hours: 8.0)
    close_issue!(matched, at: closed_on)
    close_issue!(unmatched, at: closed_on)
    matched.update_columns(created_on: created_on)
    unmatched.update_columns(created_on: created_on)
    TimeEntry.generate!(project: project, issue: matched, user: user, hours: 3.0)

    payload = invoke_mcp_tool('summarize_project_status', user: user, args: {project: project.identifier, days: 30})

    assert_mcp_ok(payload)
    assert_in_delta 10.0, payload.dig(:data, :average_resolution_hours), 0.6
    accuracy = payload.dig(:data, :estimation_accuracy)

    assert_equal 1, accuracy[:issues_count]
    assert_in_delta 4.0, accuracy[:total_estimated]
    assert_in_delta 3.0, accuracy[:total_spent]
    assert_in_delta 12.0, payload.dig(:data, :estimated_hours)
  end

  test 'summarize_project_status reopened count is unique and window-bounded' do
    project, user = generate_stats_project
    inside = Issue.generate!(project: project, subject: 'reopened inside')
    outside = Issue.generate!(project: project, subject: 'reopened outside')
    add_reopen_journal!(inside, at: 2.days.ago)
    add_reopen_journal!(inside, at: 1.day.ago)
    add_reopen_journal!(outside, at: 40.days.ago)

    payload = invoke_mcp_tool('summarize_project_status', user: user, args: {project: project.identifier, days: 30})

    assert_mcp_ok(payload)
    assert_equal 1, payload.dig(:data, :reopened_count)
  end

  test 'get_issue_form_options returns only allowed trackers' do
    user = User.find(2)
    Role.find(1).set_permission_trackers(:add_issues, [1]).save!

    payload = invoke_mcp_tool('get_issue_form_options', user: user, args: {project: 'ecookbook'})

    assert_mcp_ok(payload)
    tracker_ids = Array(payload.dig(:data, :trackers)).map { |item| item[:id] }

    assert_includes tracker_ids, 1
    assert_not_includes tracker_ids, 2
  end

  test 'get_issue_form_options rejects issue_id with a different tracker_id' do
    payload = invoke_mcp_tool(
      'get_issue_form_options',
      user: User.find(2),
      args: {project: 'ecookbook', issue_id: 1, tracker_id: 2}
    )

    assert_equal false, payload[:ok]
    assert_equal 1, Issue.find(1).tracker_id
  end

  test 'get_issue_form_options assignees and possible_values use stable shapes' do
    payload = invoke_mcp_tool('get_issue_form_options', user: User.find(2), args: {project: 'ecookbook'})

    assert_mcp_ok(payload)
    assignees = Array(payload.dig(:data, :assignees))

    assert assignees.any?
    assignees.each do |item|
      assert_includes %w[user group], item[:type]
      assert item[:id]
      assert item[:name]
    end
    Array(payload.dig(:data, :custom_fields)).each do |field|
      Array(field[:possible_values]).each do |option|
        assert option.key?(:label)
        assert option.key?(:value)
      end
    end

    assert payload.dig(:data, :editable_fields).present?
    assert payload[:data].key?(:required_fields)
    %w[notes private_notes watcher_user_ids].each do |name|
      assert_not_includes Array(payload.dig(:data, :editable_fields)), name
    end
  end

  test 'create_issue rejects a tracker the user cannot use' do
    user = User.find(2)
    Role.find(1).set_permission_trackers(:add_issues, [1]).save!

    payload = invoke_mcp_tool(
      'create_issue',
      user: user,
      args: {project: 'ecookbook', subject: 'Forbidden tracker', tracker_id: 2}
    )

    assert_equal false, payload[:ok]
    assert_includes Array(payload.dig(:error, :details, :rejected_fields)), 'tracker_id'
  end

  test 'create_issue rejects a disabled description field' do
    tracker = Tracker.find(1)
    original_fields = tracker.core_fields
    tracker.core_fields = original_fields - ['description']
    tracker.save!

    payload = invoke_mcp_tool(
      'create_issue',
      user: User.find(1),
      args: {project: 'ecookbook', subject: 'No description', tracker_id: 1, description: 'Should be rejected'}
    )

    assert_equal(false, payload[:ok])
    assert_includes(Array(payload.dig(:error, :details, :rejected_fields)), 'description')
  ensure
    tracker.core_fields = original_fields
    tracker.save!
  end

  test 'get_project include_modules adds enabled_modules' do
    payload = invoke_mcp_tool(
      'get_project',
      user: User.find(1),
      args: {project: 'ecookbook', include_modules: true}
    )

    assert_mcp_ok(payload)
    assert_equal Project.find(1).enabled_module_names, payload.dig(:data, :enabled_modules)
  end

  test 'list_issues parent_id filter lists direct subtasks' do
    admin = User.find(1)
    parent = Issue.find(1)
    child = Issue.generate!(
      project: parent.project,
      author: admin,
      subject: 'MCP list_issues subtask',
      parent: parent,
      tracker_id: parent.tracker_id,
      status_id: parent.status_id
    )
    grandchild = Issue.generate!(
      project: parent.project,
      author: admin,
      subject: 'MCP list_issues nested subtask',
      parent: child,
      tracker_id: parent.tracker_id,
      status_id: parent.status_id
    )

    payload = invoke_mcp_tool(
      'list_issues',
      user: admin,
      args: {
        filters: [{field: 'parent_id', operator: '=', values: [parent.id.to_s]}]
      }
    )

    assert_mcp_ok(payload)
    ids = Array(payload.dig(:data, :items)).map { |item| item[:id] }

    assert_includes ids, child.id
    assert_not_includes ids, grandchild.id
  end

  test 'list_issues parent_id filter returns subtasks of multiple parents when values are separate strings' do
    admin = User.find(1)
    parent_a = Issue.find(1)
    parent_b = Issue.generate!(
      project: parent_a.project,
      author: admin,
      subject: 'MCP parent B for multi parent_id filter',
      tracker_id: parent_a.tracker_id,
      status_id: parent_a.status_id
    )
    child_a = Issue.generate!(
      project: parent_a.project,
      author: admin,
      subject: 'MCP child of parent A multi filter',
      parent: parent_a,
      tracker_id: parent_a.tracker_id,
      status_id: parent_a.status_id
    )
    child_b = Issue.generate!(
      project: parent_a.project,
      author: admin,
      subject: 'MCP child of parent B multi filter',
      parent: parent_b,
      tracker_id: parent_a.tracker_id,
      status_id: parent_a.status_id
    )

    payload = invoke_mcp_tool(
      'list_issues',
      user: admin,
      args: {
        filters: [{field: 'parent_id', operator: '=', values: [parent_a.id.to_s, parent_b.id.to_s]}]
      }
    )

    assert_mcp_ok(payload)
    ids = Array(payload.dig(:data, :items)).map { |item| item[:id] }

    assert_includes ids, child_a.id
    assert_includes ids, child_b.id
  end

  test 'list_issues parent_id filter checks access for each parent id including second in values array' do
    admin = User.find(1)
    parent_a = Issue.find(1)
    parent_b = Issue.generate!(
      project: parent_a.project,
      author: admin,
      subject: 'MCP private parent B for parent_id filter',
      tracker_id: parent_a.tracker_id,
      status_id: parent_a.status_id,
      is_private: true
    )
    role = Role.generate!(permissions: %i[view_issues])
    user = User.generate!
    User.add_to_project(user, parent_a.project, role)

    payload = invoke_mcp_tool(
      'list_issues',
      user: user,
      args: {
        filters: [{field: 'parent_id', operator: '=', values: [parent_a.id.to_s, parent_b.id.to_s]}]
      }
    )

    assert_equal false, payload[:ok]
  end

  test 'list_issues parent_id filter requires visible parent' do
    parent = Issue.find(1)
    role = Role.generate!(permissions: [])
    user = User.generate!
    User.add_to_project(user, parent.project, role)

    payload = invoke_mcp_tool(
      'list_issues',
      user: user,
      args: {
        filters: [{field: 'parent_id', operator: '=', values: [parent.id.to_s]}]
      }
    )

    assert_equal false, payload[:ok]
  end

  test 'list_groups is allowed for manage_members and forbidden for outsiders' do
    allowed = invoke_mcp_tool('list_groups', user: User.find(2), args: {})
    denied = invoke_mcp_tool('list_groups', user: User.find(7), args: {})

    assert_mcp_ok(allowed)
    names = Array(allowed.dig(:data, :items)).map { |item| item[:name] }

    assert_includes names, 'A Team'
    assert_equal false, denied[:ok]
    assert_equal 'FORBIDDEN', denied.dig(:error, :code)
  end

  test 'search_issues treats percent and underscore as literal characters' do
    admin = User.find(1)
    invoke_mcp_tool(
      'create_issue',
      user: admin,
      args: {project: 'ecookbook', subject: 'MCP 100% complete', tracker_id: 1, status_id: 1}
    )
    invoke_mcp_tool(
      'create_issue',
      user: admin,
      args: {project: 'ecookbook', subject: 'MCP a_b unique', tracker_id: 1, status_id: 1}
    )

    percent = invoke_mcp_tool('redmine_search_issues', user: admin, args: {query: '%'})
    underscore = invoke_mcp_tool('redmine_search_issues', user: admin, args: {query: '_'})
    visible_count = Issue.visible(admin).count

    assert_mcp_ok(percent)
    assert_mcp_ok(underscore)
    percent_subjects = Array(percent.dig(:data, :items)).map { |item| item[:subject] }
    underscore_subjects = Array(underscore.dig(:data, :items)).map { |item| item[:subject] }

    assert_operator Array(percent.dig(:data, :items)).size, :<, visible_count
    assert_operator Array(underscore.dig(:data, :items)).size, :<, visible_count
    assert(percent_subjects.any? { |subject| subject.to_s.include?('%') })
    assert(underscore_subjects.any? { |subject| subject.to_s.include?('_') })
  end

  test 'list_roles excludes builtin roles' do
    payload = invoke_mcp_tool('list_roles', user: User.find(2), args: {project: 'ecookbook'})
    missing_project = invoke_mcp_tool('list_roles', user: User.find(2), args: {})

    assert_mcp_ok(payload)
    names = Array(payload.dig(:data, :items)).map { |item| item[:name] }

    assert_not_includes names, 'Non member'
    assert_not_includes names, 'Anonymous'
    assert_equal false, missing_project[:ok]
    assert_equal 'VALIDATION_ERROR', missing_project.dig(:error, :code)
  end

  test 'list_project_member_candidates excludes current members' do
    payload = invoke_mcp_tool(
      'list_project_member_candidates',
      user: User.find(2),
      args: {project: 'ecookbook'}
    )

    assert_mcp_ok(payload)
    items = Array(payload.dig(:data, :items))
    member_ids = Project.find(1).memberships.map(&:user_id)

    items.each do |item|
      assert_not_includes member_ids, item[:id]
      assert_includes %w[user group], item[:type]
    end
  end

  test 'list_issues with query_id runs a visible query and hides a private one' do
    visible = invoke_mcp_tool('list_issues', user: User.find(2), args: {query_id: 4})
    hidden = invoke_mcp_tool('list_issues', user: User.find(2), args: {query_id: 2})

    assert_mcp_ok(visible)
    assert_kind_of Array, visible.dig(:data, :items)
    assert_equal false, hidden[:ok]
  end

  test 'list_project_activities rejects a window longer than 90 days' do
    user = User.find(2)
    payload = invoke_mcp_tool(
      'list_project_activities',
      user: user,
      args: {project: 'ecookbook', from: (user.today - 91).to_s, to: user.today.to_s}
    )

    assert_equal false, payload[:ok]
  end

  test 'list_project_activities returns empty list for unknown author_id' do
    user = User.find(2)
    Issue.generate!(project: Project.find(1), author: user, subject: 'MCP activity for author filter')

    unknown = invoke_mcp_tool(
      'list_project_activities',
      user: user,
      args: {project: 'ecookbook', author_id: 99_999}
    )
    unfiltered = invoke_mcp_tool('list_project_activities', user: user, args: {project: 'ecookbook'})

    assert_mcp_ok(unknown)
    assert_empty unknown.dig(:data, :items)
    assert_equal 0, unknown.dig(:meta, :total_count)
    assert_mcp_ok(unfiltered)
    assert Array(unfiltered.dig(:data, :items)).any?
  end

  test 'list_boards returns boards and errors when the module is disabled' do
    user = User.find(2)
    enabled = invoke_mcp_tool('list_boards', user: user, args: {project: 'ecookbook'})

    assert_mcp_ok(enabled)
    assert Array(enabled.dig(:data, :items)).any?

    Project.find(1).disable_module!(:boards)
    disabled = invoke_mcp_tool('list_boards', user: user, args: {project: 'ecookbook'})

    assert_equal false, disabled[:ok]
    assert_equal 'FORBIDDEN', disabled.dig(:error, :code)
  end

  test 'list_board_topics returns root topics for board' do
    user = User.find(2)
    payload = invoke_mcp_tool('list_board_topics', user: user, args: {board_id: 1})

    assert_mcp_ok(payload)
    assert Array(payload.dig(:data, :items)).any?
    assert(payload.dig(:data, :items).all? { |item| item[:board_id] == 1 })
  end

  test 'get_board_message returns message with replies metadata' do
    user = User.find(2)
    payload = invoke_mcp_tool('get_board_message', user: user, args: {message_id: 1})

    assert_mcp_ok(payload)
    assert_equal 1, payload.dig(:data, :id)
    assert payload.dig(:data, :content).present?
    assert_kind_of Array, payload.dig(:data, :replies)
  end

  test 'list_repositories errors when repository module is disabled' do
    user = User.find(2)
    enabled = invoke_mcp_tool('list_repositories', user: user, args: {project: 'ecookbook'})

    assert_mcp_ok(enabled)

    Project.find(1).disable_module!(:repository)
    disabled = invoke_mcp_tool('list_repositories', user: user, args: {project: 'ecookbook'})

    assert_equal(false, disabled[:ok])
    assert_equal('INVALID_STATE', disabled.dig(:error, :code))
  ensure
    Project.find(1).enable_module!(:repository)
  end

  test 'get_version spent_hours respects own time entries visibility' do
    project, user, role = generate_stats_project
    role.update!(time_entries_visibility: 'own')
    other = User.generate!
    User.add_to_project(other, project, role)
    version = Version.generate!(project: project, name: 'MCP spent hours version')
    issue = Issue.generate!(project: project, subject: 'MCP version spent', fixed_version: version)
    TimeEntry.generate!(project: project, issue: issue, user: user, hours: 1.0)
    TimeEntry.generate!(project: project, issue: issue, user: other, hours: 5.0)

    payload = invoke_mcp_tool('get_version', user: user, args: {version_id: version.id})

    assert_mcp_ok(payload)
    assert_in_delta 1.0, payload.dig(:data, :spent_hours)
  end

  test 'search_issues scope subprojects requires project and searches descendants' do
    admin = User.find(1)
    invoke_mcp_tool(
      'create_issue',
      user: admin,
      args: {project: 'subproject1', subject: SUBPROJECT_SEARCH_SUBJECT, tracker_id: 1, status_id: 1}
    )

    missing = invoke_mcp_tool(
      'redmine_search_issues',
      user: admin,
      args: {query: SUBPROJECT_SEARCH_SUBJECT, scope: 'subprojects'}
    )
    found = invoke_mcp_tool(
      'redmine_search_issues',
      user: admin,
      args: {query: SUBPROJECT_SEARCH_SUBJECT, scope: 'subprojects', project: 'ecookbook'}
    )

    assert_equal false, missing[:ok]
    assert_mcp_ok(found)
    subjects = Array(found.dig(:data, :items)).map { |item| item[:subject] }

    assert(subjects.any? { |subject| subject.to_s.include?(SUBPROJECT_SEARCH_SUBJECT) })
  end

  test 'list_project_activities returns newest events first' do
    user = User.find(2)
    project = Project.find(1)
    old_issue = Issue.generate!(project: project, author: user, subject: 'MCP activity yesterday unique')
    old_issue.update_columns(created_on: 1.day.ago, updated_on: 1.day.ago)
    Issue.generate!(project: project, author: user, subject: 'MCP activity today unique')

    payload = invoke_mcp_tool(
      'list_project_activities',
      user: user,
      args: {project: 'ecookbook', event_types: ['issues']}
    )

    assert_mcp_ok(payload)
    titles = Array(payload.dig(:data, :items)).map { |item| item[:title].to_s }
    today_idx = titles.index { |title| title.include?('MCP activity today unique') }
    yesterday_idx = titles.index { |title| title.include?('MCP activity yesterday unique') }

    assert today_idx
    assert yesterday_idx
    assert_operator today_idx, :<, yesterday_idx
  end

  test 'get_project hides an invisible parent project' do
    parent = Project.generate!(is_public: false)
    child = Project.generate_with_parent!(parent, is_public: true)
    role = Role.generate!(permissions: %i[view_project])
    user = User.generate!
    User.add_to_project(user, child, role)

    hidden = invoke_mcp_tool('get_project', user: user, args: {project: child.identifier})
    visible = invoke_mcp_tool('get_project', user: User.find(1), args: {project: child.identifier})

    assert_mcp_ok(hidden)
    assert_nil hidden.dig(:data, :parent)
    assert_mcp_ok(visible)
    assert_equal parent.id, visible.dig(:data, :parent, :id)
  end

  test 'time entry hours schema allows zero and more than 24' do
    tool = mcp_registry.tool('create_time_entry')

    assert_nil validate_mcp_args(tool, {project: 'ecookbook', hours: 0})
    assert_nil validate_mcp_args(tool, {project: 'ecookbook', hours: 25})
  end

  test 'list_users with project returns users not group memberships' do
    project, user, role = generate_stats_project(permissions: %i[view_project view_members])
    group = Group.find(10)
    Member.create!(project: project, principal: group, role_ids: [role.id])

    payload = invoke_mcp_tool('list_users', user: user, args: {project: project.identifier})

    assert_mcp_ok(payload)
    items = Array(payload.dig(:data, :items))
    ids = items.map { |item| item[:id] }

    assert_includes ids, user.id
    assert_not_includes ids, group.id
    items.each { |item| assert item[:login].present? }
  end

  test 'list_users name filter matches email addresses for admin' do
    payload = invoke_mcp_tool('list_users', user: User.find(1), args: {name: 'jsmith@somenet.foo'})

    assert_mcp_ok(payload)
    ids = Array(payload.dig(:data, :items)).map { |item| item[:id] }

    assert_includes ids, 2
  end

  test 'list_users admin with project and name returns validation error not forbidden' do
    admin = User.find(1)
    payload = invoke_mcp_tool(
      'list_users',
      user: admin,
      args: {project: 'ecookbook', name: 'ivan'}
    )

    assert_equal false, payload[:ok]
    assert_equal 'VALIDATION_ERROR', payload.dig(:error, :code)
  end

  test 'list_users admin applies name group_id and query filters with AND' do
    admin = User.find(1)
    payload = invoke_mcp_tool(
      'list_users',
      user: admin,
      args: {group_id: 10, query: 'User', name: 'Misc'}
    )

    assert_mcp_ok(payload)
    ids = Array(payload.dig(:data, :items)).map { |item| item[:id] }

    assert_equal [8], ids
  end

  test 'list_issues with query_id and status_id returns validation error' do
    admin = User.find(1)
    payload = invoke_mcp_tool(
      'list_issues',
      user: admin,
      args: {query_id: 4, status_id: 1}
    )

    assert_equal false, payload[:ok]
    assert_equal 'VALIDATION_ERROR', payload.dig(:error, :code)
  end

  test 'list_issues with global query_id and project narrows to project' do
    member = User.find(2)
    without_project = invoke_mcp_tool('list_issues', user: member, args: {query_id: 4, limit: 100})
    with_project = invoke_mcp_tool(
      'list_issues',
      user: member,
      args: {query_id: 4, project: 'ecookbook', limit: 100}
    )

    assert_mcp_ok(without_project)
    assert_mcp_ok(with_project)
    narrow_ids = Array(with_project.dig(:data, :items)).map { |item| item[:id] }
    wide_ids = Array(without_project.dig(:data, :items)).map { |item| item[:id] }

    assert(narrow_ids.all? { |id| Issue.find(id).project_id == 1 })
    assert_operator narrow_ids.size, :<=, wide_ids.size
  end

  test 'removed consolidated tools are not registered' do
    assert_nil mcp_registry.tool('admin_list_users')
    assert_nil mcp_registry.tool('run_issue_query')
    assert_nil mcp_registry.tool('import_time_entries')
  end

  test 'removed tool aliases are not registered' do
    %w[
      list_files delete_file get_server_info list_project_trackers
      get_project_modules set_issue_note_private
    ].each do |name|
      assert_nil mcp_registry.tool(name), name
    end
  end

  test 'get_mcp_info returns live text_formatting' do
    with_settings text_formatting: 'common_mark' do
      result = invoke_mcp_tool('get_mcp_info', user: User.find(1), args: {})

      assert_mcp_ok(result)
      assert_equal 'common_mark', result.dig(:data, :text_formatting)
    end

    with_settings text_formatting: 'textile' do
      result = invoke_mcp_tool('get_mcp_info', user: User.find(1), args: {})

      assert_mcp_ok(result)
      assert_equal 'textile', result.dig(:data, :text_formatting)
    end

    with_settings text_formatting: '' do
      result = invoke_mcp_tool('get_mcp_info', user: User.find(1), args: {})

      assert_mcp_ok(result)
      assert_equal '', result.dig(:data, :text_formatting)
    end
  end

  test 'get_mcp_info returns empty text_formatting for unregistered format' do
    with_settings text_formatting: 'custom_formatter' do
      result = invoke_mcp_tool('get_mcp_info', user: User.find(1), args: {})

      assert_mcp_ok(result)
      assert_equal '', result.dig(:data, :text_formatting)
    end
  end

  test 'get_mcp_info returns registered third-party text_formatting' do
    format_name = 'mcp_custom_formatter'
    formatters = Redmine::WikiFormatting.class_variable_get(:@@formatters)
    formatters[format_name] = {
      formatter: Redmine::WikiFormatting::NullFormatter::Formatter,
      helper: Redmine::WikiFormatting::NullFormatter::Helper,
      html_parser: Redmine::WikiFormatting::HtmlParser,
      label: 'MCP custom formatter'
    }

    with_settings(text_formatting: format_name) do
      result = invoke_mcp_tool('get_mcp_info', user: User.find(1), args: {})

      assert_mcp_ok(result)
      assert_equal(format_name, result.dig(:data, :text_formatting))
    end
  ensure
    formatters&.delete(format_name)
  end

  test 'get_version with project returns a shared version from list_versions' do
    source = Project.generate!(is_public: false)
    version = Version.generate!(project: source, name: 'MCP shared system version', sharing: 'system')
    target, user = generate_stats_project(permissions: %i[view_project view_issues])

    listed = invoke_mcp_tool('list_versions', user: user, args: {project: target.identifier})
    names = Array(listed.dig(:data, :items)).map { |item| item[:name] }
    without_project = invoke_mcp_tool('get_version', user: user, args: {version_id: version.id})
    with_project = invoke_mcp_tool(
      'get_version',
      user: user,
      args: {version_id: version.id, project: target.identifier}
    )

    assert_mcp_ok(listed)
    assert_includes names, 'MCP shared system version'
    assert_equal false, without_project[:ok]
    assert_mcp_ok(with_project)
    assert_equal version.id, with_project.dig(:data, :id)
  end

private

  def setup_validate_move_target_project
    target = Project.generate!
    target.trackers << Tracker.find(1) unless target.trackers.exists?(id: 1)
    target.enabled_module_names = %w[issue_tracking]
    target.save!
    target
  end
end
