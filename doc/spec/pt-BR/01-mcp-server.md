# Servidor MCP e endpoint HTTP

[Deutsch](../de/01-mcp-server.md) | [English](../en/01-mcp-server.md) | [Español](../es/01-mcp-server.md) | [Français](../fr/01-mcp-server.md) | [Italiano](../it/01-mcp-server.md) | [日本語](../ja/01-mcp-server.md) | [한국어](../ko/01-mcp-server.md) | [Polski](../pl/01-mcp-server.md) | [Português (Brasil)](01-mcp-server.md) | [Русский](../ru/01-mcp-server.md) | [中文](../zh/01-mcp-server.md)

## Visão geral

O Redmine MCP fornece um endpoint HTTP `/mcp` implementando o MCP (Model Context Protocol) no modo Streamable HTTP sem persistência de sessão entre requisições (stateless).

## Objetivo

Permitir que clientes de IA externos interajam com o Redmine usando o protocolo MCP padrão sem um processo de servidor separado.

## Áreas afetadas

- API
- Plugins

## Regras de negócio

- O endpoint está disponível em `/mcp` relativo à raiz do Redmine.
- Métodos HTTP `GET`, `POST` e `DELETE` são suportados conforme a especificação Streamable HTTP.
- Cada requisição é tratada no contexto do usuário autenticado atual.
- Para cada requisição, um conjunto atualizado de ferramentas, recursos e prompts é construído conforme as permissões do usuário.
- O servidor anuncia o nome `redmine_mcp` e uma versão correspondente à versão do plugin.
- MCP Protocol Revision é `2025-11-25` (header `MCP-Protocol-Version` e `protocolVersion` em `initialize`).
- Métodos MCP padrão são suportados: `initialize`, `tools/list`, `tools/call`, `resources/list`, `resources/read`, `prompts/list`, `prompts/get`, e outros fornecidos pela versão do protocolo suportada.
- Respostas de ferramentas retornam um envelope JSON em `structuredContent` (`ok`, `data` ou `error`) e uma representação textual curta em `content` (string JSON em sucesso, mensagem de erro em falha).
- A chave de API é aceita apenas do header `X-Redmine-API-Key`. O corpo JSON-RPC não é usado para autenticação e não é parseado antes da verificação de tamanho da requisição.
- O tamanho do corpo HTTP é limitado antes do parse JSON: quando o limite é excedido, a requisição é rejeitada e o transporte MCP não lê o corpo.
- Em `initialize`, as instruções do servidor incluem uma dica geral: escrever descrições de tarefas, notas e texto Wiki no formato de texto ativo do Redmine. Para `common_mark` — CommonMark Markdown; para `textile` — Textile; com formatação desativada (string vazia) — texto simples. Para um formato de terceiros registrado por um plugin, as instructions incluem uma dica curta com o identificador do formato ativo e o pedido para esclarecer a sintaxe se for desconhecida; a sintaxe em si vem da documentação desse formato, e o código atual também está disponível via `redmine_get_mcp_info`. Se as configurações mantiverem um formato não registrado (por exemplo após remover o plugin), as instructions informam que o formato está indisponível e sugerem texto simples — como na exibição do Redmine sem formatação disponível. O valor do formato é lido ao montar as instructions da requisição e não é armazenado em cache para todo o processo da aplicação.

## Casos extremos

- Com o MCP desabilitado, o endpoint retorna HTTP 503 e não processa requisições MCP.
- No modo stateless, requisições `GET` para um fluxo SSE standalone não são suportadas (HTTP 405) — comportamento esperado.
- Ao operar atrás de um load balancer, sticky sessions não são necessárias.
- A lista de ferramentas pode diferir entre usuários dependendo das permissões.
- Após alterar o formato de texto na administração sem reiniciar o Redmine, um novo `initialize` recebe a dica atualizada nas instructions; o código de formato atual também está disponível via `redmine_get_mcp_info` sem reconectar.
- Se as configurações ainda tiverem o identificador de formato de um plugin removido, `initialize` não o trata como ativo e sugere texto simples.

## Tratamento de erros

- Requisição JSON-RPC inválida — resposta de erro do protocolo MCP.
- Erro interno de processamento da requisição — HTTP 500 com mensagem de erro.
- Erro de execução de ferramenta — resposta MCP com `isError: true` e descrição textual.
- REST in-process (`InternalRequest`): 404 → `NOT_FOUND`; conflito de versão → `CONFLICT`; 401/403 sem conflito → `FORBIDDEN`; array `errors` → `VALIDATION_ERROR`. O envelope não inclui o status HTTP da requisição interna nem mensagem de exceção bruta.
- Argumentos de ferramenta inválidos (campos obrigatórios ausentes, tipo errado, propriedades extras quando `additionalProperties: false`, fora do intervalo min/max) — erro de execução com `VALIDATION_ERROR` em `structuredContent`. O texto em `content` corresponde a `error.message` e não contém mensagens brutas de JSON Schema.

## Cenários de teste

1. `POST /mcp` com método `initialize` retorna capabilities, `serverInfo` e `protocolVersion` `2025-11-25`.
2. `POST /mcp` com método `tools/list` retorna a lista de ferramentas do usuário atual.
3. `POST /mcp` com método `tools/call` e nome de ferramenta válido retorna um resultado com `structuredContent`.
4. Uma requisição a `/mcp` com MCP desabilitado retorna HTTP 503.
5. Chamar uma ferramenta inexistente retorna erro "Tool not found".
6. `tools/call` sem permissão para a ferramenta retorna erro de execução com código de acesso negado; a chamada é contada no rate limit e na auditoria estruturada.
7. Corpo HTTP maior que o limite é rejeitado antes do parse JSON.
8. Ferramenta de escrita com modo somente leitura habilitado retorna erro pelo mesmo caminho HTTP/`tools/call`.
9. `resources/read` com URI de projeto inacessível não retorna conteúdo do recurso.
10. `prompts/get` com argumento de projeto inacessível nega acesso.
11. `tools/call` com args vazios, campo extra ou tipo de argumento errado retorna `isError: true` e `structuredContent.error.code` `VALIDATION_ERROR`.
12. As instructions de `initialize` mencionam o formato de texto ativo (CommonMark, Textile, texto simples ou identificador de formato de terceiros registrado) para descrições de tarefas, notas e Wiki.
13. Após alterar o formato de texto sem reiniciar o Redmine, um novo `initialize` reflete o novo formato nas instructions.
14. Se as configurações nomearem um formato não registrado, `initialize` informa que está indisponível e sugere texto simples.
