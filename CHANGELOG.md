# Changelog

## [2.0.0] - 2026-11-18

### Added
- Read-only Repository/SCM MCP tools: `list_repositories`, `get_repository`, `list_revisions`, `get_revision`, `get_repository_file`, `get_repository_diff`;
- `update_issue`: optional `project` to move an issue to another allowed target project;
- `redmine_get_mcp_info` and server instructions report the active Redmine `text_formatting` for issue descriptions, notes, and Wiki text;

### Changed
- Reduced MCP tools from 78 to 68 by consolidating related operations and removing redundant tools;
- Removed `validate_issue_create`, `validate_issue_update`, and `import_time_entries`;

### Improved
- Core class patches migrated from `alias_method` chains to `Module#prepend`;

### Fixed
- Explicit missing or invisible `project` returns `NOT_FOUND` before the tool permission check (not `FORBIDDEN`); visible projects without the required permission still return `FORBIDDEN`;
- `update_issue`: `parent_issue_id` is no longer falsely rejected as unavailable when setting or clearing the parent issue;
- `InternalRequest`: treat HTTP 2xx as success; map HTTP 409 to `CONFLICT` with opaque response body in details;
- Boot/`db:create` no longer fails when the database is missing: settings lookup rescues `ActiveRecord::NoDatabaseError`;

## [1.1.0] - 2026-09-04

### Added
- Built-in MCP extensions via `lib/redmine_mcp/extensions/<plugin.id>.rb` for third-party plugins that cannot be modified
- Compatibility with Redmine 7.0;

## [1.0.1] - 2026-09-01

### Added
- Issue and attachment tools expose canonical web UI links (`url`, `content_url`); `null` when Redmine "Host name and path" is blank;

### Improved
- Core tool renames and watcher `principal_id` (previous names remain callable); permission denials in `add_issue_watcher`, `remove_issue_watcher`, and `remove_project_member` return `FORBIDDEN` instead of a generic parameter error;

## [1.0.0] - 2026-08-25

### Added
- Redmine MCP plugin: `/mcp` endpoint, core tools (projects, issues, time tracking, wiki, boards, files, search), extension API, permission-aware `tools/list`, audit logging; MCP protocol revision `2025-11-25`; admin settings for MCP, read-only mode, and per-plugin extensions;
- `redmine_download_attachment`: read attachment bytes as `content_base64` (max 10 MiB);

### Improved
- Developer documentation: specs, extension guide, and MCP tool development guide;
