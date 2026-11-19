# 内置工具（core tools）

[Deutsch](../de/03-core-tools.md) | [English](../en/03-core-tools.md) | [Español](../es/03-core-tools.md) | [Français](../fr/03-core-tools.md) | [Italiano](../it/03-core-tools.md) | [日本語](../ja/03-core-tools.md) | [한국어](../ko/03-core-tools.md) | [Polski](../pl/03-core-tools.md) | [Português (Brasil)](../pt-BR/03-core-tools.md) | [Русский](../ru/03-core-tools.md) | [中文](03-core-tools.md)

## 概述

Redmine MCP 插件提供一组工具，用于处理 Redmine 项目、议题、工时记录、wiki、论坛、文件及参考数据（读写）。

## 目标

让 AI 客户端无需安装额外插件即可使用项目管理、议题操作、工时记录、发现、搜索与 Wiki、论坛、文件操作和元信息操作。

## 涉及领域

- 项目
- 版本
- 成员 / 角色
- 议题（CRUD、relations、watchers、notes、categories、form options、保存的查询）
- 工时记录
- 跟踪器、状态、优先级、查询
- 项目活动
- Wiki 页面
- 论坛 / 消息
- 项目文件 / 附件
- 用户
- 权限
- 设置（只读模式）

## 业务规则

### 通用规则

- 完整工具名：`redmine_<name>`（例如 `redmine_get_issue`）。
- 结果以 JSON 封装形式在 `structuredContent` 中返回，并在 `content` 中以文本形式重复。
- 数据经 Redmine 项目/议题可见性与权限过滤。
- 参数 `project` 为字符串：数字 id 的字符串形式（例如 `"1"`）或项目 identifier（例如 `"ecookbook"`）。
- 显式指定的不存在或不可见 `project` 在工具权限检查之前返回 `NOT_FOUND`（见 [02-authentication.md](02-authentication.md)）；可见但缺少所需权限的项目返回 `FORBIDDEN`。不含 `project` 的 tools 不受影响。
- 启用**只读模式**时，写入工具返回错误。只读工具（含 `list_issue_relations` 和 `get_issue_form_options`）仍可用。

### 项目管理

| 工具 | R/W | 权限 |
|------|-----|------------|
| `list_projects` | R | `view_project` |
| `get_project` | R | `view_project` |
| `list_project_issue_custom_fields` | R | `view_issues` |
| `summarize_project_status` | R | `view_issues` |
| `list_project_activities` | R | `view_project` |
| `list_versions` | R | `view_issues` |
| `get_version` | R | `view_issues` |
| `create_version` | W | `manage_versions` |
| `update_version` | W | `manage_versions` |
| `delete_version` | W | `manage_versions` |
| `list_project_members` | R | `view_members` |
| `list_project_member_candidates` | R | `manage_members` |
| `list_roles` | R | `manage_members` + `project` |
| `add_project_member` | W | `manage_members` |
| `update_project_member` | W | `manage_members` |
| `remove_project_member` | W | `manage_members` |

### 议题操作

| 工具 | R/W | 权限 |
|------|-----|------------|
| `get_issue` | R | `view_issues` |
| `list_issues` | R | `view_issues` |
| `search_issues` | R | `view_issues` |
| `get_issue_form_options` | R | `view_issues` |
| `create_issue` | W | `add_issues` |
| `update_issue` | W | 属性——若可编辑；仅 `uploads`——若可添加附件 |
| `add_issue_note` | W | `add_issue_notes`；`private_notes=true` 还需 `set_notes_private` |
| `delete_issue` | W | `delete_issues` |
| `copy_issue` | W | 源项目的 `copy_issues` 和目标项目的 `add_issues` |
| `list_issue_relations` | R | `view_issues` |
| `create_issue_relation` | W | `manage_issue_relations` |
| `delete_issue_relation` | W | `manage_issue_relations` |
| `add_issue_watcher` | W | `add_issue_watchers` |
| `remove_issue_watcher` | W | `delete_issue_watchers` |
| `update_issue_note` | W | journal 条目可见且可编辑（`edit_issue_notes` / `edit_own_issue_notes`）；更改 `private_notes` 另外需要 `set_notes_private` |
| `get_private_notes` | R | `view_private_notes` |
| `list_issue_categories` | R | `view_issues` |
| `create_issue_category` | W | `manage_categories` |
| `update_issue_category` | W | `manage_categories` |
| `delete_issue_category` | W | `manage_categories` |

### 用户

| 工具 | R/W | 权限 |
|------|-----|------------|
| `list_users` | R | `view_members` + `project`；无 `project`——仅管理员 |
| `list_groups` | R | `manage_members`（任一项目）或管理员 |

### 工时记录

| 工具 | R/W | 权限 |
|------|-----|------------|
| `list_time_entries` | R | `view_time_entries` |
| `create_time_entry` | W | `log_time` |
| `update_time_entry` | W | 条目可由当前用户编辑（`edit_time_entries` / `edit_own_time_entries`） |
| `list_time_entry_activities` | R | `log_time` |

`list_time_entry_activities` — 用于时间记录的工作活动类型目录，不是项目事件 feed（`list_project_activities`）。

### 发现 / 枚举

| 工具 | R/W | 权限 |
|------|-----|------------|
| `list_trackers` | R | `view_issues` |
| `list_issue_statuses` | R | `view_issues` |
| `list_issue_priorities` | R | `view_issues` |
| `get_current_user` | R | `use_mcp` |
| `list_queries` | R | `view_issues` |

### 搜索与 Wiki

| 工具 | R/W | 权限 |
|------|-----|------------|
| `search_all` | R | 至少可访问一种被搜索类型（`view_issues` 和/或 `view_wiki_pages`） |
| `list_wiki_pages` | R | `view_wiki_pages` |
| `get_wiki_page` | R | `view_wiki_pages`；历史 `version` 还需 `view_wiki_edits` |
| `create_wiki_page` | W | `edit_wiki_pages` 且页面必须可编辑 |
| `update_wiki_page` | W | `edit_wiki_pages` 且页面必须可编辑 |
| `delete_wiki_page` | W | `delete_wiki_pages` 且页面必须可编辑 |
| `rename_wiki_page` | W | `rename_wiki_pages` 且页面必须可编辑 |

### Repository / SCM

| 工具 | R/W | 权限 |
|------|-----|------------|
| `list_repositories` | R | `view_changesets` **或** `browse_repository` |
| `get_repository` | R | `view_changesets` **或** `browse_repository` |
| `list_revisions` | R | `view_changesets` |
| `get_revision` | R | `view_changesets` |
| `get_repository_file` | R | `browse_repository` |
| `get_repository_diff` | R | `browse_repository` |

### 论坛

| 工具 | R/W | 权限 |
|------|-----|------------|
| `list_boards` | R | `view_messages` |
| `list_board_topics` | R | `view_messages` |
| `get_board_message` | R | `view_messages` |

### 文件操作

| 工具 | R/W | 权限 |
|------|-----|------------|
| `list_project_files` | R | `view_files` |
| `upload_file` | W | `manage_files` |
| `delete_attachment` | W | `manage_files`（或容器权限） |
| `get_attachment` | R | 附件容器上的权限 |

### 元信息

| 工具 | R/W | 权限 |
|------|-----|------------|
| `get_mcp_info` | R | `use_mcp` |

`get_mcp_info` 返回当前会话 MCP 插件的元数据，而非 Redmine 版本或任意应用程序设置：`server_version`（MCP 插件版本）、`read_only_mode`、`auth_mode`、当前用户简要数据、`capabilities.issue_search` 以及 `text_formatting`。响应中不列出第三方插件安装情况：其 MCP 工具通过 `tools/list` 及扩展自行注册的 `capabilities` 可见。

`text_formatting` 是例外：它是每次调用时读取的当前 Redmine 文本格式设置（`Setting.text_formatting`）。客户端将其用于问题描述、备注和 Wiki 正文。典型值：`common_mark`、`textile`；禁用格式时为空字符串（纯文本）；已注册的第三方格式为其代码。若设置中为未注册格式（例如插件已卸载），则返回空字符串——与 Redmine 在无可用格式时的显示一致。在管理界面更改格式且不重启 Redmine 时，下一次 `get_mcp_info` 调用可见新值。

完整 tool 名 — `redmine_get_mcp_info`。旧名（`get_server_info`、`redmine_get_server_info` 及其他 core callable alias）在本 major 中不再注册，`tools/call` 也不接受。

`capabilities.issue_search` 包含搜索模式：

| 模式 | 默认 | 说明 |
|------|---------|------|
| `keyword` | `available: true`，工具 `redmine_search_issues` | 始终 |
| `cross_resource` | `available: true`，工具 `redmine_search_all` | 始终 |
| `semantic` | `available: false` | 插件可通过 `register_capability(:issue_search, :semantic)` 覆盖 |

当 `semantic.available: true` 时，能力必须包含 `tool`、`provider` 以及 `use_when` / `avoid_when`——选择语义搜索的简要提示。`Registry#apply_capabilities` 规范化 provider 响应：若违反约定，则发布 `{ available: false }`。

### 补充说明

- `delete_issue` 无 `confirm_delete` 时返回影响预览；若存在**任何**子任务（包括对用户不可见的），则需要 `confirm_delete_with_children`。`impact` 中的计数仅涵盖当前用户可见的 journals、relations、time entries、children 和 attachments。
- `search_issues` 使用 `scope=subprojects` 时需要 `project`，在该项目及其子项目中搜索。无 `project` 时该 scope 为参数错误。`scope=my_project` 将搜索限制为用户为成员的项目。
- `get_issue`：journals、attachments、watchers、relations、children 和 custom fields 仅在显式 `include_*` 时包含。嵌套列表有独立的 `limit`/`offset` 和 `*_pagination` 字段（journals：默认 limit 25，最大 100；其他嵌套列表：默认和最大均为 100）。无对应 `include_*` 时列表为空，pagination 为 `null`。可选字段（`custom_fields`、`journals`、`attachments`、`watchers`、`relations`、`children`）始终在响应中。Custom fields——仅当前用户可见的。Journals——与 Redmine 中议题历史相同可见性：条目仅在用户可见文本或至少一项 detail 变更时出现在 `journals` 和 `journal_pagination` 中。仅含空格、制表符或换行的文本视为空。空条目及仅含隐藏 detail（含隐藏 custom fields）的条目从列表和 `total_count` / `offset` / `has_more` 中排除。私有评论——自己的评论或具有 `view_private_notes` 权限。Journal 元素仅含可见 detail 变更。Relations——仅双方对用户均可见的链接。`list_issue_relations` 适用相同 relation 可见性规则。
- `get_private_notes` 仅返回文本非空的私有评论（仅空格、制表符和换行无其他内容视为空文本）。页面由 `limit`/`offset` 限制，不加载完整议题历史。
- `list_project_issue_custom_fields` 返回用户在项目中可见的字段。若设置 `tracker_id`，tracker 必须属于该项目。
- `copy_issue` 需要**源**项目的复制议题权限和**目标**项目的创建议题权限。仅当用户在目标项目有添加 watcher 权限时才复制 watchers。指向原议题的链接及附件复制遵循 Redmine 设置 `link_copied_issue` 和 `copy_attachments_on_issue_copy`（`yes` / `no` / `ask`）。无字段覆盖时，复制仍经表单写入规则。源议题的 parent 在允许时保留（含同项目内复制）。
- `create_issue_relation` 仅应用允许的 relation 属性并将变更写入议题 journal。`delete_issue_relation` 仅当当前用户可删除该 relation 时允许（双方议题可见且用户在至少一侧有管理 relation 权限）；删除亦写入 journal。
- `add_project_member` / `update_project_member` 仅接受当前用户可在项目中管理的角色。超出该集合的角色被拒绝；角色不会部分分配。
- `create_issue_category` / `update_issue_category`：`assigned_to_id` 为 principal ID（用户或组），不限于用户。
- 议题附件的 `delete_attachment` 遵循「该议题附件是否可删除」规则（含自己的议题和 tracker 权限），不仅限于全局 `edit_issues`。在 `tools/list` 中，若用户可删除至少一个附件（项目文件、议题或 wiki），工具可见，不仅限于全局 `manage_files`。
- `get_wiki_page`：`attachments` 始终在响应中；默认 `[]` 和 `attachments_pagination: null`；`include_attachments=true` 时——带 `attachment_limit`/`attachment_offset` 的分页附件列表（默认和最大 100）。历史 `version` 需要查看 wiki 编辑的权限。更改、重命名或删除受保护页面需要保护 wiki 页面的权限。
- `list_issues`、`search_issues：默认摘要字段；完整描述通过 `fields` 或 `get_issue`。
- `get_issue`、`list_issues`、`search_issuescreate_issue`、`update_issue` 和 `copy_issue` 的议题对象包含 `url` — 指向 Web UI 的绝对链接。主机来自 Redmine「主机名和路径」及协议设置，与邮件相同。若「主机名和路径」为空，`url` 为 `null` 而非无效链接。list/search 摘要默认含 `url`。`search_all` 中 `type` 为 `issues` 的项及 `get_issue` 嵌套 `children` 也含 `url`。向用户引用议题时，客户端从 tool 结果复制 `url`。
- `create_issue` 和 `update_issue` 接受显式议题**属性**（`subject`、`description`、`tracker_id`、`status_id`、`custom_fields` 等）。所有显式传入的属性（含创建时的 `subject` 和 `description`）经与 Redmine Web 表单相同的写入规则。创建/更新前，若允许字段值未知，agent 应调用 `get_issue_form_options`。显式传入但 Redmine 未应用的值导致错误，而非部分成功。
- 若客户端在 `create_issue` 中**未传递** `start_date`，且 Redmine 启用「开始日期 = 创建日期」（`default_issue_start_date_to_creation_date`），MCP 将 `start_date` 设为用户当天 — 与新议题表单相同。显式 `start_date`（含 `null`）禁用此替换。`copy_issue` 和 `update_issue` 不会自行替换日期。
- `update_issue` 不接受 `notes`、`private_notes` 或 `watcher_user_ids`。评论 — `add_issue_note`; 观察者 — `add_issue_watcher` / `remove_issue_watcher`。
- `update_issue` 接受可选 `project`（字符串 ID 或 identifier），用于将议题移到另一项目。规则与 Redmine Web 表单相同：当前用户须可编辑该议题，目标项目须在 `Issue#allowed_target_projects` 中，且在目标项目上需要 `add_issues`（若与当前项目相同则始终允许）。迁移执行标准 Redmine 回调（`after_project_change`，以及按核心规则更新关联 time entries 与子任务）。显式传入的非法项目产生带 `project_id` 的 `rejected_fields`；若 identifier/id 不存在或项目不可见，则为「项目未找到」错误。`project` 不能通过 `null` 清空 — 只能改为另一项目。在 `get_issue_form_options.editable_fields` 中，当表单上 `project_id` 可写时，字段显示为 `project`。
- `update_issue` 还支持 `uploads` 向议题附加文件。附件仅在属性验证成功（含 `rejected_fields`）后处理。仅含 `uploads`（无属性）的调用在用户可向议题添加附件时允许——包括允许评论但无法编辑属性时。可选 `idempotency_key` 防止响应丢失后的重试（含重复上传相同文件）。响应中的 `journal_id` 为**本次**调用的 journal 条目，非议题最新条目。
- 要清空可选字段，对 `assigned_to_id`、`category_id`、`fixed_version_id`、`parent_issue_id`、`start_date`、`due_date` 或 `estimated_hours` 传入 `null`。`update_version.due_date` / `wiki_page_title` 和 `update_issue_category.assigned_to_id` 同理。
- `create_issue` 不支持 `uploads`。
- `update_issue` 接受 `uploads[*].content_base64` 和 `uploads[*].filename`。上传成功后响应含 `added_attachments`——仅本次调用的文件，非完整议题附件列表。损坏的 Base64 为参数错误。
- `update_issue` 接受 `status_name` 并解析为 `status_id`。
- `upload_file` 接受 `content_base64`（最大 20 MiB）；`project`、`filename` 和 `content_base64` 为必填。
- `get_attachment` 返回 `attachment_id`、`filename`、`content_type`、`size` 和 `content_url`；当 `include_content` 缺失或为 `false` 时不返回文件字节。`size` 为附件 `filesize`。若「主机名和路径」为空，则 `content_url` 为 `null`。`include_content: true` 时还返回 `content_base64`；此时 `size` 为实际内容字节数。未知 MIME — `application/octet-stream`。不增加 `downloads` 计数。10 MiB 限制（读取前磁盘 `File.size` 与读取后 `bytesize`）仅在 `include_content: true` 时适用；超出 — `FILE_TOO_LARGE`。响应中不返回服务器文件系统路径。`attachment_id` 来自 `redmine_get_issue` / `redmine_get_wiki_page` 的 `include_attachments=true` 或 `redmine_list_project_files`。要读取或处理附件，请传 `include_content: true` 并在本地解码 `content_base64`。不存在与不可访问的附件返回相同的「未找到」响应。
- `create_time_entry` 需要 `hours` 以及 `project` 或 `issue_id`。`hours` 可以为 0；零值有效性和每日上限由 Redmine 检查（`timelog_accept_0_hours`、`timelog_max_hours_per_day`）。
- 创建/更新任务时 `assigned_to_id` 为 principal ID（来自 `get_issue_form_options.assignees` 的用户或组）；`null` 清除负责人。`add_issue_watcher` / `remove_issue_watcher` 需要 `issue_id` 与 `principal_id`（用户或组）；响应包含 `issue_id` 与 `principal_id`。其他 tool 中 `user_id` 为用户 ID。当前用户使用 `assignee_ref` 或 `user_ref` 值 `me`。
- 敏感更新/删除上的 `expected_updated_at`（可选）：与 `updated_on` 不匹配时返回 `CONFLICT`。
- `idempotency_key`（可选）用于 `create_issue`、`copy_issue`、`update_issue`、`add_issue_note`、`create_time_entry`、`upload_file`：以相同键和**相同参数集**（键本身除外）重试时返回缓存的成功结果（TTL 24 小时）。相同键但不同 payload — `CONFLICT`，不重复写入。首个请求仍在执行时，相同键的重试不会再次写入（«in progress» 标记与成功结果一样存活 24 小时）。无 fingerprint 的缓存条目（本版本之前的缓存）在 TTL 到期前仍按以前方式返回。服务器 timeout 60 秒适用于**读取**。写入操作不会因服务器 timeout 中断，以便成功保存后记录幂等结果；客户端若丢失连接可用相同键重试。
- `delete_attachment` 默认仅删除 project/version 文件；issue/wiki 附件需 `confirm_delete_any_attachment=true`。完整名 — `redmine_delete_attachment`。旧名（`delete_file`、`redmine_delete_file`）不再注册。
- 列表/搜索使用 `limit`/`offset`。DB 查询在查询层限制页面，而非裁剪已加载的完整列表。任何分页 MCP 集合有显式稳定顺序；最后准则始终为 `id`，避免页面跳过或重复项。
- 子串搜索（`query`、`login`、`name` 及文本 `search_issues`）按字符字面匹配：`%` 和 `_` 不是 SQL 通配符。
- MCP 限制：读取工具超时 60 s，每用户速率限制 120 次/分钟，MCP 请求 HTTP 体 36 MiB，JSON 工具参数最大 32 MiB，上传 base64 最大 20 MiB，下载 base64 最大 10 MiB。任何 `content_base64` 中损坏的 Base64 在工具执行前为参数错误。
- 每次工具调用（含访问拒绝）写入结构化审计日志（tool、user、target IDs、outcome、duration、correlation_id）并计入速率限制；不记录 base64 内容和私有笔记。Target IDs 含 `board_id`、`message_id`、`query_id`、`user_id`、`group_id` 等。
- 每个 core tool 的 `outputSchema` 描述 `data` 顶层（列表为 `items` 元素字段），而非任意开放对象。模式字段集与实际响应一致：带 `project` 的 `list_users` 元素无 `created_on`；管理员无 `project` 的全局 `list_users` 包含 `created_on`；`get_attachment` 包含 `size`、`content_url` 及可选 `content_base64`。实际响应中可能为空的字段允许 `null`（包括 `time_entry.issue`、无 include 的 `*_pagination`、`estimation_accuracy`、附件 `content_type`）。自定义字段值和 `possible_values` 不限于对象。`attachments_not_saved` — 文件名数组。
- schema 中 `summarize_project_status.days`：默认 30，最小 1，最大 365。
- `search_all.resources`：最多两个唯一值。
- `version_id`、`file_id`、`tracker_id` 为不小于 1 的整数。

### `get_project`

- 输入：`project`（必填）；可选 `include_modules`（boolean）。
- 输出：`id`、`name`、`identifier`、`description`、`homepage`、`status`、`is_public`、`inherit_members`、`created_on`、`updated_on`、`parent`（对象 `id`/`name`/`identifier` 或 `null`）、`subprojects`（可见子项目简要列表：`id`/`name`/`identifier`）、`custom_fields`、`last_activity_date`。`include_modules: true` 时另有 `enabled_modules` — 已启用模块名称数组。
- `parent` 仅在父项目对当前用户可见时填充；否则 `null`。
- 不返回成员或议题统计。成员 — `list_project_members`；议题聚合 — `summarize_project_status`。

### `get_issue_form_options`

- 创建/更新前一次调用替代多次参考查询。独立的 `list_trackers`（可选 `project`）、`list_issue_statuses`、`list_issue_priorities`、`list_issue_categories`、`list_versions`、`list_users`、`list_project_issue_custom_fields` 仍可用。
- 输入：`project`（必填）；可选 `tracker_id`、`issue_id`。
- 快照反映**当前用户的议题表单**，而非完整项目配置：与 Redmine UI 提供的相同允许值。
- 无 `issue_id` 的 `tracker_id` 设置创建表单上下文。tracker 必须对当前用户可在表单上选择；否则——参数错误。
- `issue_id` 设置该项目中现有可见议题的表单。有 `issue_id` 时，`tracker_id` 仅在与议题当前 tracker 一致时允许；否则——参数错误（tracker 变更不通过此工具建模）。
- 输出——无分页的表单快照：
  - `project`：`id`、`name`、`identifier`；
  - `trackers`：当前用户在此表单上可选择的 tracker（`id`、`name`），非项目启用的全部 tracker；
  - `priorities`：活动优先级（`id`、`name`、`is_default`）；
  - `categories`：项目类别（`id`、`name`）；
  - `versions`：此表单上可选择的版本（`id`、`name`、`status`、`due_date`）；
  - `assignees`：此表单上下文中可分配的 principal。元素：`id`、`name`、`type`（`user` 或 `group`）；`user` 另有 `login`。Redmine 启用议题分配给组时包含组；
  - `custom_fields`：仅当前用户可在表单上编辑的字段，考虑项目/tracker、可见性、工作流只读。元素：`id`、`name`、`field_format`、`required`（字段必填或工作流要求）、`readonly`（此列表中始终 `false`）、`multiple`、`default_value`、`possible_values`、`trackers`。表单上下文——`issue_id` 的议题或考虑 `tracker_id` 的创建草稿；
  - `possible_values`——对象数组 `{ "label": "...", "value": "..." }`。无独立标签的列表中 `label` 与 `value` 相同。用户/版本/枚举中 `label` 为显示名，`value` 为标识符；
  - `statuses`：工作流允许当前用户的状态。有 `issue_id`——该可见议题的转换。无 `issue_id`——创建的初始状态（若设置则考虑 `tracker_id`）；
  - `editable_fields`：此 MCP 约定在创建/更新上接受且当前用户可在表单上设置的属性名，以及可编辑 custom field id 的字符串形式。不含 `notes`、`private_notes`、`watcher_user_ids` 及 MCP 写入工具中不存在的其他 Web 表单字段；
  - `required_fields`：当前用户在此表单上必填的字段名，与 `editable_fields` 同名形式。
- 不存在的 `tracker_id`、用户不允许的 tracker，或 `issue_id` 在项目外/不可见——参数错误。

### `add_issue_note`

- 向现有可见议题添加评论，不更改议题属性。
- 输入：`issue_id`（必填）、`notes`（必填），可选 `private_notes`、`uploads` 和 `idempotency_key`。
- 权限：用户可向该议题添加评论。`private_notes=true` 需要私有评论权限；否则——拒绝，不创建评论。同一调用中的附件在用户可向议题添加附件时允许。
- 不接受议题字段或 watcher 列表。
- 输出：`issue_id`、`journal_id`、`notes`、`private_notes`；有 `uploads` 时——`added_attachments`（仅本次调用的文件）。
- 只读模式下不可用。

### `update_issue_note`

- 仅处理当前用户**可见**的 journal 条目（无查看私有笔记权限时无法访问他人的私有评论）。
- 条目须可由当前用户编辑（编辑评论或自己的评论的权限）。
- 输入：`journal_id`（必填）；至少需要 `notes` 或 `private_notes` 之一。
- `notes` 可为空字符串（清空现有条目文本）。通过 `add_issue_note` 的新评论不能为空。
- 更改隐私（`private_notes`）需要单独的私有评论权限；否则拒绝，文本不会部分更改。
- 输出 — journal 对象（`JOURNAL`），与编辑文本时相同。
- 记录谁编辑了 journal 条目。
- 只读模式下不可用。
- 只读模式下不可用。

### `list_trackers`

- 无 `project`：Redmine 实例的全部 tracker（`id`、`name`、`description`）。
- 有 `project`：仅对已可见项目启用的 tracker；`description` 为空字符串以保持响应 schema 一致。
- 不存在或不可见的 `project` 返回 `NOT_FOUND`，而不是 `FORBIDDEN`。

### `list_issues` — 扩展过滤器

- 保留现有扁平过滤器（`project`、`status_id`、`tracker_id`、`assigned_to_id` / `assignee_ref`、`priority_id`、`fixed_version_id`、`sort`、`fields`）。
- 可选 `filters`：对象数组 `{ "field": "...", "operator": "...", "values": ["..."] }`。`values` 为字符串数组；无值运算符允许空数组。
- 允许的 `field`：`status_id`、`tracker_id`、`assigned_to_id`、`priority_id`、`fixed_version_id`、`category_id`、`parent_id`、`subject`、`due_date`、`start_date`、`created_on`、`updated_on`、`estimated_hours`、`done_ratio`、`author_id`、`watcher_id`，以及议题 custom field 的 `cf_<id>`。
- 运算符为标准 Redmine 查询运算符，含 `=`、`!`、`>=`、`<=`、`><`、`~`、`!~`、`o`、`c`、`*`、`!*`。运算符必须对字段类型有效；否则——参数错误。
- 未知 `field` 或无效 `operator`——参数错误，不执行查询。
- 扁平过滤器与 `filters` 以 AND 组合。
- 过滤器仅应用于当前用户可见的议题。
- 直接子任务：`filters` 中 `field` 为 `parent_id`，`operator` 为 `=`，一个或多个值 — 父议题 ID。同一字符串内可用逗号分隔多个 ID（Redmine 写法：`"123,456"`），或多个 `values` 元素（MCP 在查询前合并为一条字符串）。列出的每个父议题必须对当前用户可见；否则为「议题未找到」错误（与 `get_issue` 相同）。独立工具 `list_subtasks` 已移除。


### `list_project_activities`

- 这是项目事件 feed（「发生了什么」），不是用于时间记录的工作活动类型目录。工作活动类型 — `list_time_entry_activities`。
- 输入：`project`（必填）；可选 `from`、`to`（日期 `YYYY-MM-DD`）、`author_id`、`event_types`（字符串数组）、`limit`/`offset`。
- 默认窗口——最近 7 天（`to` = 今天，`from` = 今天减 6 天）。最大窗口长度 90 天；超出——参数错误。
- 来自项目活动源的事件：类型、时间、作者（`id`/`name`）、`title`、`description`、`url`。顺序——较新事件在前；时间相同时——较大 `id` 在前。
- 封装与其他 `list_*` 相同。
- `event_types` 限制事件类型。用户不可用或项目中禁用的类型从选择中排除（无错误）。
- 不存在的 `author_id`——空列表，非错误。

### `summarize_project_status`

这不是 Redmine 对象，而是对可见项目议题和时间记录的服务端聚合。

保留现有字段：`project_id`、`project_name`、`analysis_period_days`、`recent_activity`（`created_count`、`updated_count`）、`totals`（`issues_count`、`open_count`、`closed_count`）、`status_breakdown`、`priority_breakdown`、`assignee_breakdown`。

`days` 窗口（默认 30，范围 1–365）仍影响 `recent_activity` 及下列周期指标。超出范围的值被 schema 拒绝。`totals` 和 breakdown 经 DB 聚合计算所有可见项目议题，无日期过滤，不将全部议题加载到内存。不包含子项目。

附加字段：

- `overdue_count`——`due_date` 严格早于用户今天的开放可见议题数。
- `unassigned_count`——无负责人的开放可见议题数。
- `stale_issues_count`——`updated_on` 早于 `days` 窗口开始的开放可见议题数。
- `issues_closed_during_period`——`closed_on` 在 `days` 窗口内的可见议题数。
- `estimated_hours`——可见项目议题估算总和（无估算时为 `null`，否则为数字含 0）。
- `spent_hours`——可见项目议题已花费时间总和（无条目时为 0）。需要项目上的 `view_time_entries`；无权限时字段为 `null`。
- `average_resolution_hours`——`days` 窗口内关闭议题的 `(closed_on - created_on)` 平均小时数；无此类议题时为 `null`。
- `estimation_accuracy`——窗口内关闭且同时有估算和非零/已记录工时的议题：`{ "issues_count", "total_estimated", "total_spent" }`。无匹配议题——`{ "issues_count": 0, "total_estimated": 0, "total_spent": 0 }`。需要项目上的 `view_time_entries`；无权限时字段为 `null`。
- `reopened_count`——journal 状态在 `days` 窗口内从关闭变为开放的可见议题数。每个议题最多计一次。

工具返回事实，而非文本化的「项目健康分析」。

### `list_versions` / `get_version`

这些工具中的 `Version` 是 Redmine 实体（roadmap 阶段 / milestone），不是软件产品版本。`list_versions` 返回项目 roadmap 版本，包括共享版本。

### `get_version`

- 输入：`version_id`（必填）；可选 `project`。若设置 `project`，当版本在该可见项目的共享版本中时可访问（即使版本的源项目对用户不可见）。无 `project` 时，版本必须在其源项目上可见。
- 输出：类似 `list_versions` 元素的字段（`id`、`name`、`description`、`status`、`due_date`、`sharing`、`wiki_page_title`、`project`、`created_on`、`updated_on`）加聚合：`issues_count`、`open_issues_count`、`closed_issues_count`、`estimated_hours`、`spent_hours`、`completed_percent`。
- 聚合仅针对当前用户可见的版本议题计算。
- 不返回议题列表。
- `spent_hours` 需要版本项目上的 `view_time_entries`；无权限——`null`。仅对可见版本议题求和，且仅当前用户可见的 time entries（含 `time_entries_visibility=own`）。

### Repository / SCM

- 项目 Repository 模块必须启用；否则错误「Repository module is not enabled for this project」。
- `list_repositories` / `get_repository`：权限 `view_changesets` **或** `browse_repository`。无 `repository_id` 时按 Redmine 规则选择仓库：`project.repository || project.repositories.first`。
- `list_revisions` / `get_revision`：权限 `view_changesets`。列表来自缓存的 changeset（`Changeset.visible`）；未 fetch 的新提交可能缺失。
- `get_revision`：通过 `repository.find_changeset_by_name` 按 revision 号或 prefix hash 查找；**不**接受 branch/tag（SCM ref 用 `get_repository_file` / `get_repository_diff`）；关联 issue 仅 `Issue.visible`；`file_changes` 仅在 `:browse_repository` 时返回。
- `get_repository`：即使 SCM 无法提供 `default_branch` 也返回 metadata（`id`, `scm_type`, `name`, …）；此时 `default_branch` 为 `null`。
- `get_repository_file` / `get_repository_diff`：权限 `browse_repository`。无 `repository_id` 时使用项目默认仓库。默认 revision 为 `default_branch`；参数可为 branch/tag/hash（SCM 适配器）。解析默认 revision 时 SCM 失败（省略 `revision`）——`REDMINE_API_ERROR`。
- `get_repository_file`：目录——分页 `entries`；文本文件——inline `content`；二进制——metadata，可选 `content_base64`（独立字段）。是否二进制按内容判定：无效 UTF-8、空字节或控制字节占比高。文本扩展名不覆盖该结果。大小受 `min(Setting.file_max_size_displayed, MCP cap 10 MiB)` 限制。
- `get_repository_diff`：unified diff，按 `min(Setting.diff_max_lines_displayed, MCP line cap)` 和 MCP byte cap（512 KiB）截断。
- 缺少 repository/revision/path——`NOT_FOUND`；SCM 适配器失败——`REDMINE_API_ERROR`，非 `NOT_FOUND` 或 `INTERNAL_ERROR`。
- 只要用户能看到至少一个项目，所有 Repository 工具都会出现在 `tools/list` 中。出现在列表中并不表示有权调用：缺少所需权限时调用返回 `FORBIDDEN`，不会隐藏工具。调用时在权限检查之后再检查 Repository 模块状态：无权限——`FORBIDDEN`（含模块关闭）；有权限但模块关闭——`INVALID_STATE`。
- 不返回 `url`、`root_url`、`login`、`password`、`extra_info`。

### 论坛

- 必须启用项目论坛模块；否则错误「Boards module is not enabled for this project」（wiki 类比）。
- 权限 `view_messages`。无论坛写入操作。
- `list_boards`：`project` 必填；分页。元素：`id`、`name`、`description`、`parent_id`（根 board 为 `null`）、`topics_count`、`messages_count`。
- `list_board_topics`：`board_id` 必填；分页。仅根消息（无 parent）。元素：`id`、`subject`、`author`、`created_on`、`updated_on`、`replies_count`、`board_id`。
- `get_board_message`：`message_id` 必填。输出：`id`、`subject`、`content`、`author`、`created_on`、`updated_on`、`board`（`id`/`name`）、`project`（`id`/`name`/`identifier`）、`parent_id`、`replies`——简要回复列表（`id`、`subject`、`author`、`created_on`），无各回复全文，含 `replies_limit`/`replies_offset`（默认和最大 100）及 `replies_pagination`。
- 不可见 board/message 或来自其他项目的 board——「未找到」错误。

### `list_users`

- 带 `project`：活跃的**用户**项目成员（权限 `view_members`）。项目中的组membership 不会作为组出现；组内用户仅在其本人为成员时出现。无 `project` — 仅管理员。
- 带 `project` 的元素：`id`、`login`、`firstname`、`lastname`、`mail`（无 `created_on`）。管理员无 `project` 的全局列表还包含 `created_on`。
- 可选 `query`：对 `login`、`firstname`、`lastname` 不区分大小写的子串匹配。
- 保留可选 `login`（仅 login 子串）以兼容。若同时设置 `query` 和 `login`，两个条件均适用（AND）。
- 可选 `name` 和 `group_id` — 仅无 `project` 的管理员。`name` — 通过 `User.like` 的子串（login、firstname、lastname、email）。`group_id` — 组内用户。`name` 与 `group_id` 可组合；与 `query`/`login` 条件以 AND 组合。带 `project` 或非管理员时，`name`/`group_id` — 参数错误或拒绝访问。

### `list_project_files`

- 项目「文件」部分文件及其版本附件的分页列表。不包含议题或 Wiki 附件 — 通过 `include_attachments` 的 `get_issue` / `get_wiki_page` 读取。
- 输入：`project`（必填）、分页。权限 `view_files`。
- 规范全名 — `redmine_list_project_files`。
- 旧名称 `list_files`（`redmine_list_files`）至少保留到下一 major 版本作为 callable alias：相同权限、输入、输出和行为；以旧名称 `tools/call` 执行相同操作；alias 不在 `tools/list` 中发布；alias 调用可在 audit log 中通过调用的工具名区分。
- 其他工具的链接使用规范名。

### `list_groups`

- 可赋予组的分页列表（`id`、`name`），对当前用户**可见**，用于在 `add_project_member` 中选择 `group_id`。
- 可选 `query`：组名不区分大小写子串；`%` 和 `_` 按字面匹配。
- 权限：管理员或在至少一个可见项目上有 `manage_members`。
- 不返回组成员身份或成员关系。

### `list_project_member_candidates`

- 添加到项目的候选：不在项目中的活动可见用户和组。
- 输入：`project`（必填）；可选 `query`（子串，如 Redmine 成员选择器）。
- 输出列表封装：`id`、`name`、`type`（`user` 或 `group`）；用户另有 `login`。
- 项目上的权限 `manage_members`。
- `add_project_member`：`user_id` 仅用于用户，`group_id` 仅用于组。错误类型的 ID——参数错误。添加前从此工具（或若候选已知则从 `list_users` / `list_groups`）获取 ID。

### `list_roles`

- 仅当前用户可在指定项目中管理的角色。
- 输入：`project`（必填）。
- 项目上的权限 `manage_members`。
- 对管理员，集合与可分配项目角色一致（不含 Non member / Anonymous）。

## 边界情况

- 不存在/不可访问的项目或议题——`{ "error": "..." }`。
- 只读模式 — 写入工具在调用 handler **之前**返回 `{ "error": "MCP is in read-only mode..." }`，含 Extension API 工具；form options/list/get 仍可用。
- 空列表/搜索结果——`{ "ok": true, "data": { "items": [] }, "meta": { ... } }`。
- 带分页的列表/搜索始终返回 `data.items` 和 `meta`（`total_count`、`limit`、`offset`、`has_more`、`next_offset`）。默认 limit 25，最大 100。
- 所有 `list_*` 工具（含参考：trackers、statuses、roles、queries、boards、board topics 等）使用相同封装。`get_issue_form_options`、`get_project`、`get_version`、`get_board_message`、`summarize_project_status` — 单个对象，非列表封装。
- `get_attachment`：不存在或不可访问的附件 — 相同的「未找到」错误；`include_content: true` 时磁盘文件不可读 — 错误；磁盘或读取后大小超过 10 MiB — `FILE_TOO_LARGE`（无法用较低的 DB `filesize` 绕过限制）；仅元数据请求不适用大小限制。
- `list_project_activities`：窗口超过 90 天——参数错误；`from` 晚于 `to`——参数错误。
- 带 `query_id` 的 `list_issues`：不可见查询——视为不存在；`query_id` 与额外筛选参数同时使用——参数错误。
- `get_issue_form_options` 对来自其他项目的议题使用 `issue_id`——参数错误。
- `get_issue_form_options` 使用 `issue_id` 且 `tracker_id` 不等于该议题 tracker——参数错误。
- 通过 MCP 的写入经 Redmine 模型。模型回调运行；Web 界面控制器钩子不被调用。

## 错误处理

- 缺少权限——工具在 `tools/list` 中不可见或「Permission denied」。
- 模型验证错误 — `{ "error": "<messages>" }`（议题 create/update 另有 `missing_required_fields` 为模型错误符号的字段名，不解析翻译文本，以及 `hint`）。
- 禁用的 wiki/boards 模块——单独错误消息，非「未找到」。
- 封装中的规范错误代码由 handler 显式设置；代码不从消息文本派生，不依赖用户语言。

## 测试场景

1. `list_projects` / `list_issues` 返回封装 `data.items` + 带分页的 `meta`。
2. `get_issue` 无 `include_*` 不返回 journals/attachments；有 `include_journals`——带分页的 journals。
3. `search_issues` 按文本找到议题；`search_all` 搜索多种类型时包含 wiki。
4. `create_issue` / `update_issue` 有效字段成功；无权限或只读——错误。
4a. 启用开始日期设置时 `create_issue` 无 `start_date` 设置当天日期；显式 `start_date` 或 `null` 不被该设置覆盖。
5. `delete_issue` 无 `confirm_delete` 返回 `INVALID_STATE` 和影响；确认后删除。
6. `create_time_entry` requires `hours` and `project` or `issue_id`.
7. 启用 Wiki 模块时 `list_wiki_pages` / `get_wiki_page` / `create_wiki_page` 可用。
8. `upload_file` 需要 `filename` 和 `content_base64`；议题附件的 `delete_attachment` 需要确认。
9. 无 `use_mcp` 的用户无法通过 MCP 认证；无工具权限者在 `tools/list` 中看不到该工具。
10. 相同 `idempotency_key` 和相同参数重试 `create_issue` 不创建重复；相同 key 不同 subject——`CONFLICT`。
11. 对可见 issue 附件，`include_content: true` 的 `get_attachment` 返回 `content_base64` 和 `content_url` 及实际内容 `size`；磁盘上 > 10 MiB（即使元数据很小）— `FILE_TOO_LARGE`；无 `include_content` 时大文件仅返回元数据；不存在与不可访问不可区分；`tools/list` 中无 `redmine_download_attachment`。
12. 按 identifier 的 `get_project` 返回 description、subprojects 和 `last_activity_date`；不可访问项目——错误。
13. 项目的 `get_issue_form_options` 返回 trackers/statuses/priorities/categories/versions/assignees/custom_fields 及 `editable_fields` / `required_fields` 列表；`trackers`——仅当前用户可用的；有 `issue_id` 时 statuses 反映该议题允许的转换；`issue_id` + 不同 `tracker_id`——错误；`possible_values`——`label`/`value` 对象。
14. 无效 tracker 或 status 的 `create_issue` 返回错误且不创建议题。
15. 带 `filters`（`due_date` `<=` 日期、`priority_id` `!`、子任务用 `parent_id` `=`）的 `list_issues` 仅返回匹配的可见议题；未知 `field` — 错误；不可见父议题的 `parent_id` `=`（包括逗号分隔列表中的任一 ID）— 「议题未找到」错误。
16. 带可见 `query_id` 的 `list_issues` 返回与 UI 中保存查询相同的议题；不可见 query — 错误；带 `filters` 的 `query_id` — 参数错误。
17. 3 天的 `list_project_activities` 返回带分页的项目事件；91 天窗口——错误。
18. `summarize_project_status` 包含 `overdue_count`、`unassigned_count`、`stale_issues_count`、`issues_closed_during_period` 和 `reopened_count`。
19. `get_version` 返回聚合 `open_issues_count` / `completed_percent`，无议题列表。
20. 启用 Boards 模块时 `list_boards` / `list_board_topics` / `get_board_message` 可用；禁用时——模块错误。
21. 带 `project` 和按名称 `query` 的 `list_users` 无需知道 login 即可找到成员。
22. `get_issue_form_options` 返回 `type` 为 user/group 的 assignees 及仅可编辑 custom fields 含 `required`/`readonly`。
23. 显式传入 Redmine 未应用的值的 `create_issue` / `update_issue` / `copy_issue`（含禁用/只读核心字段，含创建时 `description`）返回错误且不部分保存。
24. 有 `add_issue_notes` 的 `add_issue_note` 无 `edit_issues` 成功；无 `set_notes_private` 的 `private_notes` — 拒绝。仅 `uploads` 的 `update_issue` 在有添加附件权限时无 `edit_issues` 成功。
25. `list_groups` 为有 `manage_members` 的用户返回可赋予组。
26. `update_issue` 将 `assigned_to_id`/`category_id`/`fixed_version_id`/`parent_issue_id`/`start_date`/`due_date`/`estimated_hours` = `null` 在可写时清空字段。
27. 无查看私有评论权限时，`update_issue_note` 不会修改他人的私有评论。
28. 有编辑评论权限但无私有评论权限的用户可更改公开评论文本，不能更改隐私标志。
29. 带 `uploads` 的 `add_issue_note` 一次调用创建评论和附件；相同 `idempotency_key` 重试不重复。
30. 带 `uploads` 和 `idempotency_key` 的 `update_issue`：相同 payload 重试不重复附件；相同 key 不同文件——`CONFLICT`。损坏 Base64——参数错误。
31. `get_issue` 不返回隐藏 custom fields、不可见 journal detail 或含不可见议题的 relations。`get_version` 聚合仅针对可见议题。
32. 源项目无复制权限的 `copy_issue`——拒绝，即使目标有 `add_issues`。
33. 用户无法管理的角色的 `add_project_member` / `update_project_member`——拒绝，无部分分配。
34. 用户不允许的 `sharing` 的 `create_version` / `update_version`——拒绝。繁忙版本的 `delete_version`——拒绝删除。
35. 有 `edit_own_time_entries` 的工时作者可通过 `update_time_entry` 更新自己的条目。
36. 有 wiki 权限无 `view_issues` 的用户若搜索包含 wiki 则 `search_all` 可用。
37. `list_project_member_candidates` 返回尚不在项目中的用户和组；组的 `user_id` 的 `add_project_member`——错误。
38. 项目的 `list_roles` 仅返回用户可管理的角色；无 `project`——schema 错误。不含内置 Non member 和 Anonymous。
39. 相同 `idempotency_key` 重试 `copy_issue` / `create_time_entry` 不创建重复；相同 key 不同 payload——`CONFLICT`。
40. `search_issues` 及用户/组搜索对 `%` 或 `_` 按字符字面匹配，非通配符。
41. `time_entries_visibility=own` 时 `get_version.spent_hours` 仅计自己的 time entries。
42. 无 `project` 的 `scope=subprojects` 的 `search_issues`——错误；有 `project` 在后代中找到议题。
43. `list_project_activities` 较新事件排在较旧之前。
44. `delete_issue` 影响不含隐藏 journals、relations 和他人的 time entries；隐藏子任务仍需要 `confirm_delete_with_children`。
45. `get_project` 不返回对当前用户不可见的 parent。
46. `due_date`/`wiki_page_title` = `null` 的 `update_version` 清空字段。
47. `assigned_to_id` = `null` 的 `update_issue_category` 清空默认负责人。
48. Schema 接受 `hours` 为 0 及超过 24 的值；仅 Redmine 验证拒绝。
49. 空 `notes` 的 `update_issue_note` 清空现有评论文本。
50. 带 `project` 的 `list_users` 仅返回用户，即使项目有组成员身份。
51. 无 `view_wiki_edits` 的历史 wiki 页面版本不可访问；无保护 wiki 权限时无法更改受保护页面。
52. 无添加 watcher 权限的 `copy_issue` 不复制 watchers；`link_copied_issue` / `copy_attachments_on_issue_copy` = `no` 禁止链接和附件；同项目 parent 保留。
53. 只读模式下 Extension 写入工具不调用 handler。
54. 可删除议题附件的用户在 `tools/list` 中可见 `delete_attachment`，无 `manage_files`。
55. `add_issue_watcher` / `remove_issue_watcher` 通过 `principal_id` 或 deprecated `user_id` 接受 group principal。
56. 带 `project` 的 `get_version` 返回该项目 `list_versions` 返回的共享版本。
57. `get_issue` / `get_wiki_page` / `get_board_message` 用 `limit`/`offset` 限制嵌套列表并返回 `*_pagination`；无 include 时 pagination 为 `null`。
58. 实际工具响应（含可空字段）与发布的 `outputSchema` 一致。
59. 带 `include_journals` 的 `get_issue`：仅含隐藏 custom-field detail 的 journal 不在列表中且不计入 `journal_pagination.total_count`。
60. 两个可见条目之间的隐藏 journal 不产生页面间隙：`journal_limit=2` 时返回两个可见条目，`total_count` 等于可见计数。
61. 无 `view_private_notes` 权限时 `get_issue` 不返回他人的私有评论。
62. `get_private_notes` 按 `limit`/`offset` 返回页面，不加载完整议题历史。
63. 同时含 journals `attr`、`cf` 和 `relation` 的 `get_issue` 不失败且仅返回可见条目。
64. 含隐藏 custom-field detail 且 notes 为空格、制表符或换行的 journal 不包含在 `get_issue` 中。
65. `get_private_notes` 不返回仅含空格、制表符或换行的评论。
71. `list_repositories` / `get_repository` 可在无 `view_changesets` 时有 `browse_repository`（及反之用于 discovery）；`list_revisions` / `get_revision` 需要 `view_changesets`；`get_repository_file` / `get_repository_diff` 需要 `browse_repository`。缺少所需权限时调用返回 `FORBIDDEN`，工具仍留在 `tools/list`。
72. `get_repository_file` 文本在 `content` 中，二进制文件——无 `content` 的 metadata；`include_content_base64`——独立字段。无效 UTF-8 的文件（含无空字节的 PNG 签名）视为二进制。含 NUL 的 `.txt` 即使扩展名如此也视为二进制。
73. `get_repository_diff` 按行/字节限制截断 diff 并返回 `truncated: true`。
74. SCM 适配器失败返回 `REDMINE_API_ERROR`，非 `NOT_FOUND`。
75. `list_repositories` / `list_revisions` / 文件工具在 Repository 模块启用时可用。有权限但模块关闭——`INVALID_STATE`；无权限且模块关闭——`FORBIDDEN`。
76. `get_revision` 无 `:browse_repository` 时不返回 `file_changes`。
77. 无 `revision` 的 `get_repository_file` 在 `default_branch` SCM 失败时返回 `REDMINE_API_ERROR`。
78. `default_branch` SCM 失败时 `get_repository` 返回 `default_branch: null` 的 metadata。
79. 只要用户能看到至少一个项目，无论 `view_changesets` / `browse_repository` 如何组合（包括两者皆无），所有 Repository 工具都出现在 `tools/list` 中。
80. 带 `project` 的 `update_issue` 将议题移到允许的目标项目；未知 identifier — `NOT_FOUND`（非 `FORBIDDEN`）；目标项目无 `add_issues` — 带 `project_id` 的 `rejected_fields`，议题不更改项目。
81. `get_mcp_info` 返回有效格式的 `text_formatting`（`common_mark`、`textile`、空字符串或已注册的第三方格式代码）。
82. 在不重启 Redmine 的情况下更改文本格式后，下一次 `get_mcp_info` 调用返回新的 `text_formatting` 值。
83. 若设置中为未注册格式，`get_mcp_info` 返回 `text_formatting: ""`。
