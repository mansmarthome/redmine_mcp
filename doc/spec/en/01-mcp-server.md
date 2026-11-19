# MCP server and HTTP endpoint

[Deutsch](../de/01-mcp-server.md) | [English](01-mcp-server.md) | [Español](../es/01-mcp-server.md) | [Français](../fr/01-mcp-server.md) | [Italiano](../it/01-mcp-server.md) | [日本語](../ja/01-mcp-server.md) | [한국어](../ko/01-mcp-server.md) | [Polski](../pl/01-mcp-server.md) | [Português (Brasil)](../pt-BR/01-mcp-server.md) | [Русский](../ru/01-mcp-server.md) | [中文](../zh/01-mcp-server.md)

## Overview

Redmine MCP provides an HTTP endpoint `/mcp` implementing the MCP (Model Context Protocol) in Streamable HTTP mode without session persistence between requests (stateless).

## Goal

Allow external AI clients to interact with Redmine using the standard MCP protocol without a separate server process.

## Affected areas

- API
- Plugins

## Business rules

- The endpoint is available at `/mcp` relative to the Redmine root.
- HTTP methods `GET`, `POST`, and `DELETE` are supported per the Streamable HTTP specification.
- Each request is handled in the context of the current authenticated user.
- For each request, an up-to-date set of tools, resources, and prompts is built according to the user's permissions.
- The server advertises the name `redmine_mcp` and a version matching the plugin version.
- MCP Protocol Revision is `2025-11-25` (header `MCP-Protocol-Version` and `protocolVersion` in `initialize`).
- Standard MCP methods are supported: `initialize`, `tools/list`, `tools/call`, `resources/list`, `resources/read`, `prompts/list`, `prompts/get`, and others provided by the supported protocol version.
- Tool responses return a JSON envelope in `structuredContent` (`ok`, `data` or `error`) and a short text representation in `content` (JSON string on success, error message on failure).
- The API key is accepted from the `X-Redmine-API-Key` header only. The JSON-RPC body is not used for authentication and is not parsed before the request size check.
- HTTP body size is limited before JSON parsing: when the limit is exceeded, the request is rejected and the MCP transport does not read the body.
- In `initialize`, server instructions include a general hint: write issue descriptions, notes, and Wiki text using the active Redmine text formatting. For `common_mark` — CommonMark Markdown; for `textile` — Textile; when formatting is disabled (empty string) — plain text. For a third-party format registered by a plugin in Redmine, instructions include a short hint with the active format identifier and a request to clarify its syntax if unknown; the syntax itself comes from that format’s documentation, and the current code is also available via `redmine_get_mcp_info`. If settings still name a format that is not registered (for example after the plugin was removed), instructions report that the format is unavailable and suggest plain text — matching Redmine display without available formatting. The format value is read when instructions are built for the request and is not cached for the whole application process.

## Edge cases

- When MCP is disabled, the endpoint returns HTTP 503 and does not process MCP requests.
- In stateless mode, `GET` requests for a standalone SSE stream are not supported (HTTP 405) — this is expected behavior.
- When operating behind a load balancer, sticky sessions are not required.
- The tool list may differ between users depending on permissions.
- After the text formatting setting changes in administration without restarting Redmine, a new `initialize` gets the updated hint in instructions; the current format code is also available via `redmine_get_mcp_info` without reconnecting.
- If settings still contain the format identifier of a removed plugin, `initialize` does not treat it as active and suggests plain text.

## Error handling

- Invalid JSON-RPC request — MCP protocol error response.
- Internal request processing error — HTTP 500 with an error message.
- Tool execution error — MCP response with `isError: true` and a text description.
- In-process REST (`InternalRequest`): 404 → `NOT_FOUND`; version conflict → `CONFLICT`; 401/403 without conflict → `FORBIDDEN`; `errors` array → `VALIDATION_ERROR`. The envelope does not include the internal request HTTP status or a raw exception message.
- Invalid tool arguments (missing required fields, wrong type, extra properties when `additionalProperties: false`, out of min/max range) — execution error with `VALIDATION_ERROR` in `structuredContent`. Text in `content` matches `error.message` and does not contain raw JSON Schema messages.

## Test scenarios

1. `POST /mcp` with method `initialize` returns capabilities, `serverInfo`, and `protocolVersion` `2025-11-25`.
2. `POST /mcp` with method `tools/list` returns the current user's tool list.
3. `POST /mcp` with method `tools/call` and a valid tool name returns a result with `structuredContent`.
4. A request to `/mcp` when MCP is disabled returns HTTP 503.
5. Calling a non-existent tool returns a "Tool not found" error.
6. `tools/call` without permission for the tool returns an execution error with an access-denied code; the call is counted in rate limit and structured audit.
7. An HTTP body larger than the limit is rejected before JSON parsing.
8. A write tool with read-only mode enabled returns an error through the same HTTP/`tools/call` path.
9. `resources/read` with a URI for an inaccessible project does not return resource content.
10. `prompts/get` with an inaccessible project argument denies access.
11. `tools/call` with empty args, an extra field, or a wrong argument type returns `isError: true` and `structuredContent.error.code` `VALIDATION_ERROR`.
12. `initialize` instructions mention the active text formatting (CommonMark, Textile, plain text, or a registered third-party format identifier) for issue descriptions, notes, and Wiki.
13. After text formatting changes without restarting Redmine, a new `initialize` reflects the new format in instructions.
14. If settings name an unregistered format, `initialize` reports that it is unavailable and suggests plain text.
