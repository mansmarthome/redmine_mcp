# Servidor MCP y endpoint HTTP

[Deutsch](../de/01-mcp-server.md) | [English](../en/01-mcp-server.md) | [Español](01-mcp-server.md) | [Français](../fr/01-mcp-server.md) | [Italiano](../it/01-mcp-server.md) | [日本語](../ja/01-mcp-server.md) | [한국어](../ko/01-mcp-server.md) | [Polski](../pl/01-mcp-server.md) | [Português (Brasil)](../pt-BR/01-mcp-server.md) | [Русский](../ru/01-mcp-server.md) | [中文](../zh/01-mcp-server.md)

## Descripción general

Redmine MCP proporciona un endpoint HTTP `/mcp` que implementa MCP (Model Context Protocol) en modo Streamable HTTP sin persistencia de sesión entre solicitudes (sin estado).

## Objetivo

Permitir que clientes de IA externos interactúen con Redmine mediante el protocolo MCP estándar sin un proceso de servidor separado.

## Áreas afectadas

- API
- Plugins

## Reglas de negocio

- El endpoint está disponible en `/mcp` relativo a la raíz de Redmine.
- Los métodos HTTP `GET`, `POST` y `DELETE` son compatibles según la especificación Streamable HTTP.
- Cada solicitud se procesa en el contexto del usuario autenticado actual.
- Para cada solicitud se construye un conjunto actualizado de herramientas, recursos y prompts según los permisos del usuario.
- El servidor anuncia el nombre `redmine_mcp` y una versión que coincide con la versión del plugin.
- La revisión del protocolo MCP es `2025-11-25` (cabecera `MCP-Protocol-Version` y `protocolVersion` en `initialize`).
- Se admiten los métodos MCP estándar: `initialize`, `tools/list`, `tools/call`, `resources/list`, `resources/read`, `prompts/list`, `prompts/get` y otros proporcionados por la versión del protocolo compatible.
- Las respuestas de herramientas devuelven un sobre JSON en `structuredContent` (`ok`, `data` o `error`) y una representación de texto breve en `content` (cadena JSON en caso de éxito, mensaje de error en caso de fallo).
- La clave API solo se acepta desde la cabecera `X-Redmine-API-Key`. El cuerpo JSON-RPC no se usa para autenticación y no se analiza antes de la comprobación del tamaño de la solicitud.
- El tamaño del cuerpo HTTP se limita antes del análisis JSON: cuando se supera el límite, la solicitud se rechaza y el transporte MCP no lee el cuerpo.
- En `initialize`, las instrucciones del servidor incluyen una pista general: escribir descripciones de peticiones, notas y texto Wiki con el formato de texto activo de Redmine. Para `common_mark` — CommonMark Markdown; para `textile` — Textile; con el formato desactivado (cadena vacía) — texto plano. Para un formato de terceros registrado por un plugin, las instructions incluyen una pista breve con el identificador del formato activo y la petición de aclarar su sintaxis si se desconoce; la sintaxis en sí proviene de la documentación de ese formato, y el código actual también está disponible mediante `redmine_get_mcp_info`. Si en la configuración figura un formato no registrado (por ejemplo tras eliminar el plugin), las instructions indican que el formato no está disponible y proponen texto plano — como al mostrar en Redmine sin formato disponible. El valor del formato se lee al formar las instrucciones de la petición y no se almacena en caché para todo el proceso de la aplicación.

## Casos límite

- Cuando MCP está deshabilitado, el endpoint devuelve HTTP 503 y no procesa solicitudes MCP.
- En modo sin estado, las solicitudes `GET` para un flujo SSE independiente no son compatibles (HTTP 405) — es el comportamiento esperado.
- Cuando se opera detrás de un balanceador de carga, no se requieren sesiones persistentes (sticky sessions).
- La lista de herramientas puede diferir entre usuarios según los permisos.
- Tras cambiar el formato de texto en administración sin reiniciar Redmine, un nuevo `initialize` recibe la pista actualizada en instructions; el código de formato actual también está disponible mediante `redmine_get_mcp_info` sin reconectar.
- Si en la configuración permanece el identificador de formato de un plugin eliminado, `initialize` no lo trata como activo y propone texto plano.

## Manejo de errores

- Solicitud JSON-RPC no válida — respuesta de error del protocolo MCP.
- Error interno de procesamiento de la solicitud — HTTP 500 con un mensaje de error.
- Error de ejecución de herramienta — respuesta MCP con `isError: true` y una descripción en texto.
- REST en proceso (`InternalRequest`): 404 → `NOT_FOUND`; conflicto de versiones → `CONFLICT`; 401/403 sin conflicto → `FORBIDDEN`; array `errors` → `VALIDATION_ERROR`. El sobre no incluye el estado HTTP de la solicitud interna ni un mensaje de excepción sin procesar.
- Argumentos de herramienta no válidos (campos obligatorios ausentes, tipo incorrecto, propiedades adicionales cuando `additionalProperties: false`, fuera del rango min/max) — error de ejecución con `VALIDATION_ERROR` en `structuredContent`. El texto en `content` coincide con `error.message` y no contiene mensajes JSON Schema sin procesar.

## Escenarios de prueba

1. `POST /mcp` con el método `initialize` devuelve capacidades, `serverInfo` y `protocolVersion` `2025-11-25`.
2. `POST /mcp` con el método `tools/list` devuelve la lista de herramientas del usuario actual.
3. `POST /mcp` con el método `tools/call` y un nombre de herramienta válido devuelve un resultado con `structuredContent`.
4. Una solicitud a `/mcp` cuando MCP está deshabilitado devuelve HTTP 503.
5. Invocar una herramienta inexistente devuelve un error «Tool not found».
6. `tools/call` sin permiso para la herramienta devuelve un error de ejecución con código de acceso denegado; la llamada se cuenta en el límite de tasa y en la auditoría estructurada.
7. Un cuerpo HTTP mayor que el límite se rechaza antes del análisis JSON.
8. Una herramienta de escritura con el modo de solo lectura habilitado devuelve un error por la misma ruta HTTP/`tools/call`.
9. `resources/read` con un URI de un proyecto inaccesible no devuelve contenido del recurso.
10. `prompts/get` con un argumento de proyecto inaccesible deniega el acceso.
11. `tools/call` con argumentos vacíos, un campo adicional o un tipo de argumento incorrecto devuelve `isError: true` y `structuredContent.error.code` `VALIDATION_ERROR`.
12. Las instructions de `initialize` mencionan el formato de texto activo (CommonMark, Textile, texto plano o identificador de formato de terceros registrado) para descripciones de peticiones, notas y Wiki.
13. Tras cambiar el formato de texto sin reiniciar Redmine, un nuevo `initialize` refleja el nuevo formato en instructions.
14. Si la configuración nombra un formato no registrado, `initialize` indica que no está disponible y propone texto plano.
