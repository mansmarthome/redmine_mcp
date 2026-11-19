# Strumenti integrati (core tools)

[Deutsch](../de/03-core-tools.md) | [English](../en/03-core-tools.md) | [Español](../es/03-core-tools.md) | [Français](../fr/03-core-tools.md) | [Italiano](03-core-tools.md) | [日本語](../ja/03-core-tools.md) | [한국어](../ko/03-core-tools.md) | [Polski](../pl/03-core-tools.md) | [Português (Brasil)](../pt-BR/03-core-tools.md) | [Русский](../ru/03-core-tools.md) | [中文](../zh/03-core-tools.md)

## Panoramica

Il plugin Redmine MCP fornisce un insieme di strumenti per lavorare con progetti, issue, registrazione del tempo, wiki, forum, file e dati di riferimento di Redmine (lettura e scrittura).

## Obiettivo

Fornire ai client AI operazioni di gestione progetti, operazioni sulle issue, registrazione del tempo, scoperta, ricerca e wiki, forum, operazioni sui file e meta senza installare plugin aggiuntivi.

## Aree interessate

- Progetti
- Versioni
- Membri / Ruoli
- Issue (CRUD, relazioni, osservatori, note, categorie, opzioni formulario, query salvate)
- Voci di tempo
- Tracker, stati, priorità, query
- Attività del progetto
- Pagine wiki
- Forum / messaggi
- File di progetto / allegati
- Utenti
- Permessi
- Impostazioni (modalità read-only)

## Regole di business

### Regole generali

- Nome completo dello strumento: `redmine_<name>` (ad esempio `redmine_get_issue`).
- Il risultato viene restituito come envelope JSON in `structuredContent` e duplicato come testo in `content`.
- I dati sono filtrati in base alla visibilità di progetti/issue e ai permessi di Redmine.
- Il parametro `project` è una stringa: id numerico come stringa (ad esempio `"1"`) o identificatore del progetto (ad esempio `"ecookbook"`).
- Un `project` esplicitamente mancante o invisibile restituisce `NOT_FOUND` prima del controllo di permesso dello strumento (vedi [02-authentication.md](02-authentication.md)); un progetto visibile senza il permesso richiesto restituisce `FORBIDDEN`. I tool senza `project` non sono interessati.
- Quando la **modalità read-only** è abilitata, gli strumenti di scrittura restituiscono un errore. Gli strumenti di sola lettura, inclusi `list_issue_relations` e `get_issue_form_options`, restano disponibili.

### Gestione progetti

| Strumento | R/W | Permesso |
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

### Operazioni sulle issue

| Strumento | R/W | Permesso |
|------|-----|------------|
| `get_issue` | R | `view_issues` |
| `list_issues` | R | `view_issues` |
| `search_issues` | R | `view_issues` |
| `get_issue_form_options` | R | `view_issues` |
| `create_issue` | W | `add_issues` |
| `update_issue` | W | attributi — se sono modificabili; `uploads` solo — se è possibile aggiungere allegati |
| `add_issue_note` | W | `add_issue_notes`; `private_notes=true` richiede inoltre `set_notes_private` |
| `delete_issue` | W | `delete_issues` |
| `copy_issue` | W | `copy_issues` sul progetto sorgente e `add_issues` sul progetto di destinazione |
| `list_issue_relations` | R | `view_issues` |
| `create_issue_relation` | W | `manage_issue_relations` |
| `delete_issue_relation` | W | `manage_issue_relations` |
| `add_issue_watcher` | W | `add_issue_watchers` |
| `remove_issue_watcher` | W | `delete_issue_watchers` |
| `update_issue_note` | W | voce del journal visibile e modificabile (`edit_issue_notes` / `edit_own_issue_notes`); modificare `private_notes` richiede inoltre `set_notes_private` |
| `get_private_notes` | R | `view_private_notes` |
| `list_issue_categories` | R | `view_issues` |
| `create_issue_category` | W | `manage_categories` |
| `update_issue_category` | W | `manage_categories` |
| `delete_issue_category` | W | `manage_categories` |

### Utenti

| Strumento | R/W | Permesso |
|------|-----|------------|
| `list_users` | R | `view_members` + `project`; senza `project` — solo admin |
| `list_groups` | R | `manage_members` (su qualsiasi progetto) o admin |

### Registrazione del tempo

| Strumento | R/W | Permesso |
|------|-----|------------|
| `list_time_entries` | R | `view_time_entries` |
| `create_time_entry` | W | `log_time` |
| `update_time_entry` | W | la voce è modificabile dall'utente corrente (`edit_time_entries` / `edit_own_time_entries`) |
| `list_time_entry_activities` | R | `log_time` |

`list_time_entry_activities` — catalogo dei tipi di attività di lavoro per la registrazione del tempo, non il feed eventi del progetto (`list_project_activities`).

### Scoperta / enumerazione

| Strumento | R/W | Permesso |
|------|-----|------------|
| `list_trackers` | R | `view_issues` |
| `list_issue_statuses` | R | `view_issues` |
| `list_issue_priorities` | R | `view_issues` |
| `get_current_user` | R | `use_mcp` |
| `list_queries` | R | `view_issues` |

### Ricerca e wiki

| Strumento | R/W | Permesso |
|------|-----|------------|
| `search_all` | R | accesso ad almeno uno dei tipi cercati (`view_issues` e/o `view_wiki_pages`) |
| `list_wiki_pages` | R | `view_wiki_pages` |
| `get_wiki_page` | R | `view_wiki_pages`; la `version` storica richiede inoltre `view_wiki_edits` |
| `create_wiki_page` | W | `edit_wiki_pages` e la pagina deve essere modificabile |
| `update_wiki_page` | W | `edit_wiki_pages` e la pagina deve essere modificabile |
| `delete_wiki_page` | W | `delete_wiki_pages` e la pagina deve essere modificabile |
| `rename_wiki_page` | W | `rename_wiki_pages` e la pagina deve essere modificabile |

### Repository / SCM

| Strumento | R/W | Permesso |
|------|-----|------------|
| `list_repositories` | R | `view_changesets` **o** `browse_repository` |
| `get_repository` | R | `view_changesets` **o** `browse_repository` |
| `list_revisions` | R | `view_changesets` |
| `get_revision` | R | `view_changesets` |
| `get_repository_file` | R | `browse_repository` |
| `get_repository_diff` | R | `browse_repository` |

### Forum

| Strumento | R/W | Permesso |
|------|-----|------------|
| `list_boards` | R | `view_messages` |
| `list_board_topics` | R | `view_messages` |
| `get_board_message` | R | `view_messages` |

### Operazioni sui file

| Strumento | R/W | Permesso |
|------|-----|------------|
| `list_project_files` | R | `view_files` |
| `upload_file` | W | `manage_files` |
| `delete_attachment` | W | `manage_files` (o permessi del contenitore) |
| `get_attachment` | R | permessi sul contenitore dell'allegato |

### Meta

| Strumento | R/W | Permesso |
|------|-----|------------|
| `get_mcp_info` | R | `use_mcp` |

`get_mcp_info` restituisce i metadati del plugin MCP della sessione corrente, non la versione di Redmine né impostazioni applicative arbitrarie: `server_version` (versione del plugin MCP), `read_only_mode`, `auth_mode`, brevi dati dell'utente corrente, `capabilities.issue_search` e `text_formatting`. L'installazione di plugin di terze parti non è elencata nella risposta: i loro strumenti MCP sono visibili tramite `tools/list` e tramite `capabilities` che le estensioni registrano autonomamente.

`text_formatting` è un'eccezione: è il valore corrente della formattazione testo Redmine (`Setting.text_formatting`), letto a ogni chiamata. Il client lo usa per descrizioni delle segnalazioni, note e testo Wiki. Valori tipici: `common_mark`, `textile`; con formattazione disattivata — stringa vuota (testo semplice); un formato di terze parti registrato — il suo codice. Se le impostazioni indicano un formato non registrato (ad esempio dopo la rimozione del plugin), viene restituita una stringa vuota — come nella visualizzazione Redmine senza formattazione disponibile. Una modifica del formato in amministrazione senza riavviare Redmine è visibile nella chiamata successiva a `get_mcp_info`.

Nome completo del tool — `redmine_get_mcp_info`. I nomi precedenti (`get_server_info`, `redmine_get_server_info` e altri alias invocabili core) non sono registrati e non sono accettati in `tools/call` in questa major.

`capabilities.issue_search` contiene le modalità di ricerca:

| Modalità | Predefinito | Note |
|------|---------|------|
| `keyword` | `available: true`, tool `redmine_search_issues` | Sempre |
| `cross_resource` | `available: true`, tool `redmine_search_all` | Sempre |
| `semantic` | `available: false` | I plugin possono sovrascrivere tramite `register_capability(:issue_search, :semantic)` |

Quando `semantic.available: true`, la capability DEVE includere `tool`, `provider` e `use_when` / `avoid_when` — brevi indicazioni su quando scegliere la ricerca semantica. `Registry#apply_capabilities` normalizza la risposta del provider: se il contratto è violato, viene pubblicato `{ available: false }`.

### Chiarimenti

- `delete_issue` senza `confirm_delete` restituisce un'anteprima dell'impatto; se esistono **qualsiasi** sottoattività (incluse quelle invisibili all'utente), è richiesto `confirm_delete_with_children`. I contatori in `impact` coprono solo journal, relazioni, registrazioni del tempo, figli e allegati visibili all'utente corrente.
- `search_issues` con `scope=subprojects` richiede `project` e cerca in quel progetto e nei suoi discendenti. Senza `project`, quello scope è un errore di parametro. `scope=my_project` limita la ricerca ai progetti di cui l'utente è membro.
- `get_issue`: journal, allegati, watcher, relazioni, figli e campi personalizzati sono inclusi solo con `include_*` espliciti. Le liste annidate hanno `limit`/`offset` separati e un campo `*_pagination` (journal: limite predefinito 25, massimo 100; altre liste annidate: predefinito e massimo 100). Senza il corrispondente `include_*`, la lista è vuota e la paginazione è `null`. I campi opzionali (`custom_fields`, `journals`, `attachments`, `watchers`, `relations`, `children`) sono sempre presenti nella risposta. Campi personalizzati — solo quelli visibili all'utente corrente. Journal — stessa visibilità della cronologia issue in Redmine: una voce appare in `journals` e `journal_pagination` solo se ha testo o almeno una modifica di dettaglio visibile all'utente. Il testo composto solo da spazi, tab o interruzioni di riga è trattato come vuoto. Le voci vuote e quelle con solo dettagli nascosti (inclusi campi personalizzati nascosti) sono escluse sia dalla lista sia da `total_count` / `offset` / `has_more`. Commenti privati — propri commenti o con permesso `view_private_notes`. Gli elementi del journal contengono solo modifiche di dettaglio visibili. Relazioni — solo collegamenti in cui entrambe le parti sono visibili all'utente. La stessa regola di visibilità delle relazioni si applica a `list_issue_relations`.
- `get_private_notes` restituisce solo commenti privati con testo non vuoto (spazi, tab e interruzioni di riga senza altro contenuto contano come testo vuoto). La pagina è limitata da `limit`/`offset` senza caricare l'intera cronologia dell'issue.
- `list_project_issue_custom_fields` restituisce i campi visibili all'utente nel progetto. Se `tracker_id` è impostato, il tracker deve appartenere al progetto.
- `copy_issue` richiede il permesso di copiare issue sul progetto **sorgente** e il permesso di creare issue sul progetto **di destinazione**. I watcher vengono copiati solo se l'utente ha il permesso di aggiungere watcher sul progetto di destinazione. Il collegamento all'originale e la copia degli allegati seguono le impostazioni Redmine `link_copied_issue` e `copy_attachments_on_issue_copy` (`yes` / `no` / `ask`). Senza override dei campi, la copia passa comunque attraverso le regole di scrittura del form. Il genitore dell'issue sorgente viene preservato quando consentito (incluso quando si copia nello stesso progetto).
- `create_issue_relation` applica solo gli attributi di relazione consentiti e scrive la modifica nel journal dell'issue. `delete_issue_relation` è consentito solo se la relazione può essere eliminata dall'utente corrente (entrambe le issue sono visibili e l'utente ha il permesso di gestire le relazioni su almeno un lato); l'eliminazione viene anch'essa scritta nel journal.
- `add_project_member` / `update_project_member` accettano solo ruoli che l'utente corrente può gestire nel progetto. Un ruolo al di fuori di quell'insieme viene rifiutato; i ruoli non vengono assegnati parzialmente.
- `create_issue_category` / `update_issue_category`: `assigned_to_id` è un ID principal (utente o gruppo), non solo un utente.
- `delete_attachment` per un allegato di issue segue la regola "è possibile eliminare gli allegati su questa issue" (incluse le proprie issue e i permessi del tracker), non solo il globale `edit_issues`. In `tools/list`, lo strumento è visibile se l'utente può eliminare almeno un allegato (file di progetto, issue o wiki), non solo con il globale `manage_files`.
- `get_wiki_page`: `attachments` è sempre nella risposta; per impostazione predefinita `[]` e `attachments_pagination: null`; con `include_attachments=true` — una lista paginata di allegati con `attachment_limit`/`attachment_offset` (predefinito e massimo 100). La `version` storica richiede il permesso di visualizzare le modifiche wiki. Modificare, rinominare o eliminare una pagina protetta richiede il permesso di proteggere le pagine wiki.
- `list_issues`, `search_issues`: campi di riepilogo per impostazione predefinita; descrizione completa tramite `fields` o `get_issue`.
- Gli oggetti issue di `get_issue`, `list_issues`, `search_issues`, `create_issue`, `update_issue` e `copy_issue` includono `url` — un link assoluto all'UI web. L'host proviene dalle impostazioni Redmine «Nome host e percorso» e dal protocollo, come nelle e-mail. Se «Nome host e percorso» è vuoto, `url` è `null` invece di un link non valido. Il riepilogo list/search include `url` per impostazione predefinita. Gli elementi `search_all` con `type` `issues` e i `children` annidati di `get_issue` includono anch'essi `url`. Nel citare una segnalazione all'utente, il client copia `url` dal risultato del tool.
- `create_issue` e `update_issue` accettano attributi **espliciti** dell'issue (`subject`, `description`, `tracker_id`, `status_id`, `custom_fields`, ecc.). Tutti gli attributi passati esplicitamente, inclusi `subject` e `description` in creazione, passano attraverso le stesse regole di scrittura del form web di Redmine. Prima di create/update, l'agente DOVREBBE chiamare `get_issue_form_options` quando i valori consentiti dei campi sono sconosciuti. Un valore passato esplicitamente che Redmine non ha applicato comporta un errore, non un successo parziale.
- Se il client **non ha passato** `start_date` in `create_issue`, e Redmine ha abilitato «data di inizio = data di creazione» (`default_issue_start_date_to_creation_date`), MCP imposta `start_date` al giorno odierno dell'utente — come il form di nuova issue. Un `start_date` esplicito (incluso `null`) disabilita questa sostituzione. `copy_issue` e `update_issue` non sostituiscono la data autonomamente.
- `update_issue` non accetta `notes`, `private_notes` o `watcher_user_ids`. Commenti — `add_issue_note`; watcher — `add_issue_watcher` / `remove_issue_watcher`.
- `update_issue` accetta un `project` opzionale (ID come stringa o identifier) per spostare l'issue in un altro progetto. Valgono le stesse regole del form web di Redmine: l'issue deve essere modificabile dall'utente corrente, il progetto di destinazione deve essere in `Issue#allowed_target_projects`, e serve `add_issues` sul progetto di destinazione (più il progetto corrente è sempre consentito se coincide). Lo spostamento esegue i callback standard di Redmine (`after_project_change`, aggiornamento di time entry e sotto-issue collegati secondo le regole del core). Un progetto non valido passato esplicitamente produce `rejected_fields` con `project_id`, oppure un errore «progetto non trovato» se l'identifier/id non esiste o il progetto non è visibile. `project` non può essere azzerato con `null` — solo cambiato a un altro progetto. In `get_issue_form_options.editable_fields` il campo appare come `project` quando `project_id` è scrivibile sul form.
- `update_issue` supporta anche `uploads` per allegare file a un'issue. Gli allegati vengono elaborati solo dopo la validazione riuscita degli attributi (incluso `rejected_fields`). Una chiamata con solo `uploads` (nessun attributo) è consentita se l'utente può aggiungere allegati all'issue — incluso quando è consentito commentare ma gli attributi non possono essere modificati. L'opzionale `idempotency_key` protegge dai retry dopo una risposta persa (incluso il re-upload degli stessi file). `journal_id` nella risposta è la voce del journal per **questa** chiamata, non l'ultima voce dell'issue.
- Per cancellare un campo opzionale, passare `null` per `assigned_to_id`, `category_id`, `fixed_version_id`, `parent_issue_id`, `start_date`, `due_date` o `estimated_hours`. Stesso per `update_version.due_date` / `wiki_page_title` e `update_issue_category.assigned_to_id`.
- `create_issue` non supporta `uploads`.
- `update_issue` accetta `uploads[*].content_base64` e `uploads[*].filename`. Dopo un upload riuscito, la risposta contiene `added_attachments` — solo i file di questa chiamata, non l'intera lista di allegati dell'issue. Base64 corrotto è un errore di parametro.
- `update_issue` accetta `status_name` e lo risolve in `status_id`.
- `upload_file` accetta `content_base64` (fino a 20 MiB); `project`, `filename` e `content_base64` sono obbligatori.
- `get_attachment` restituisce `attachment_id`, `filename`, `content_type`, `size` e `content_url` e non restituisce i byte del file se `include_content` è assente o `false`. `size` è il `filesize` dell'allegato. Se «Nome host e percorso» è vuoto, `content_url` è `null`. Con `include_content: true` anche `content_base64`; `size` è la dimensione effettiva del contenuto in byte. MIME sconosciuto — `application/octet-stream`. Non incrementa il contatore `downloads`. Il limite di 10 MiB (controlla `File.size` su disco prima della lettura e `bytesize` dopo) si applica solo con `include_content: true`; se superato — `FILE_TOO_LARGE`. Nessun percorso filesystem del server nella risposta. `attachment_id` da `redmine_get_issue` / `redmine_get_wiki_page` con `include_attachments=true` o `redmine_list_project_files`. Per leggere o elaborare l'allegato, passare `include_content: true` e decodificare `content_base64` localmente. Allegato inesistente e inaccessibile — stessa risposta «non trovato».
- `create_time_entry` richiede `hours` e `project` o `issue_id`. `hours` può essere 0; Redmine verifica la validità dello zero e il massimo giornaliero (`timelog_accept_0_hours`, `timelog_max_hours_per_day`).
- `assigned_to_id` in creazione/aggiornamento issue è un ID principal (utente o gruppo da `get_issue_form_options.assignees`); `null` rimuove l'assegnatario. Per `add_issue_watcher` / `remove_issue_watcher` sono obbligatori `issue_id` e `principal_id` (utente o gruppo); la risposta include `issue_id` e `principal_id`. Negli altri tool, `user_id` è un ID utente. Per l'utente corrente usare `assignee_ref` o `user_ref` con valore `me`.
- `expected_updated_at` (opzionale) su update/delete sensibili: se non corrisponde a `updated_on`, restituisce `CONFLICT`.
- `idempotency_key` (opzionale) su `create_issue`, `copy_issue`, `update_issue`, `add_issue_note`, `create_time_entry`, `upload_file`: un nuovo tentativo con la stessa chiave e **lo stesso insieme di argomenti** (eccetto la chiave stessa) restituisce il risultato di successo in cache (TTL 24 h). La stessa chiave con payload diverso — `CONFLICT`, nessuna scrittura duplicata. Mentre la prima richiesta è ancora in esecuzione, un nuovo tentativo con la stessa chiave non esegue un'altra scrittura (il marcatore «in progress» dura le stesse 24 h di un risultato di successo). Una voce in cache senza fingerprint (cache precedente a questa versione) con la stessa chiave viene restituita come prima fino alla scadenza del TTL. Il timeout server di 60 s si applica alle **letture**. Le operazioni di scrittura non sono interrotte dal timeout server così che dopo un salvataggio riuscito il risultato di idempotenza possa essere registrato; il client può riprovare con la stessa chiave se ha perso la connessione.
- `delete_attachment` per impostazione predefinita elimina solo file di progetto/versione; per allegati issue/wiki serve `confirm_delete_any_attachment=true`. Nome completo — `redmine_delete_attachment`. I nomi precedenti (`delete_file`, `redmine_delete_file`) non sono registrati.
- Liste/ricerche usano `limit`/`offset`. Per le query DB, la pagina è limitata a livello di query, non tagliando una lista completa già caricata. Qualsiasi collezione MCP paginata ha un ordine esplicito stabile; l'ultimo criterio è sempre `id` così le pagine non saltano o duplicano elementi.
- La ricerca per sottostringa (`query`, `login`, `name` e `search_issues` testuale) corrisponde ai caratteri letteralmente: `%` e `_` non sono wildcard SQL.
- Limiti MCP: timeout 60 s sugli strumenti di lettura, rate limit 120 richieste/min per utente, corpo HTTP della richiesta MCP 36 MiB, dimensione massima degli argomenti JSON dello strumento 32 MiB, upload base64 fino a 20 MiB, download base64 fino a 10 MiB. Base64 corrotto in qualsiasi `content_base64` è un errore di parametro prima dell'esecuzione dello strumento.
- Ogni chiamata allo strumento, incluso il diniego di accesso, viene scritta in un audit log strutturato (tool, utente, ID target, esito, durata, correlation_id) e conteggiata nel rate limit; il contenuto base64 e le note private non vengono registrati. Gli ID target includono `board_id`, `message_id`, `query_id`, `user_id`, `group_id`, tra gli altri.
- L'`outputSchema` di ogni core tool descrive il livello superiore di `data` (per le liste — campi dell'elemento `items`), non un oggetto arbitrario aperto. L'insieme dei campi dello schema corrisponde alla risposta effettiva: `list_users` con `project` senza `created_on` negli elementi; `list_users` globale dell'amministratore senza `project` include `created_on`; `get_attachment` include `size`, `content_url` e `content_base64` opzionale. I campi che possono essere vuoti nella risposta reale ammettono `null` (inclusi `time_entry.issue`, `*_pagination` senza include, `estimation_accuracy`, `content_type` dell'allegato). I valori dei campi personalizzati e `possible_values` non sono limitati a oggetti. `attachments_not_saved` — array di nomi file.
- `summarize_project_status.days` nello schema: predefinito 30, minimo 1, massimo 365.
- `search_all.resources`: al massimo due valori univoci.
- `version_id`, `file_id`, `tracker_id` sono interi non inferiori a 1.

### `get_project`

- Input: `project` (obbligatorio); opzionalmente `include_modules` (boolean).
- Output: `id`, `name`, `identifier`, `description`, `homepage`, `status`, `is_public`, `inherit_members`, `created_on`, `updated_on`, `parent` (oggetto `id`/`name`/`identifier` o `null`), `subprojects` (breve lista di progetti figli visibili: `id`/`name`/`identifier`), `custom_fields`, `last_activity_date`. Con `include_modules: true`, inoltre `enabled_modules` — array dei nomi dei moduli abilitati.
- `parent` è compilato solo se il progetto genitore è visibile all'utente corrente; altrimenti `null`.
- Non restituisce membri né statistiche delle issue. Per i membri — `list_project_members`; per gli aggregati delle issue — `summarize_project_status`.

### `get_issue_form_options`

- Una chiamata invece di diverse consultazioni di riferimento prima di create/update. Restano disponibili separatamente `list_trackers` (con `project` opzionale), `list_issue_statuses`, `list_issue_priorities`, `list_issue_categories`, `list_versions`, `list_users`, `list_project_issue_custom_fields`.
- Input: `project` (obbligatorio); opzionalmente `tracker_id`, `issue_id`.
- Lo snapshot riflette il **form issue per l'utente corrente**, non la configurazione completa del progetto: gli stessi valori consentiti che offre l'interfaccia Redmine.
- `tracker_id` senza `issue_id` imposta il contesto del form di creazione. Il tracker deve essere disponibile per la selezione dell'utente corrente sul form; altrimenti — errore di parametro.
- `issue_id` imposta il form per un'issue esistente visibile in questo progetto. Con `issue_id`, `tracker_id` è consentito solo se corrisponde al tracker corrente dell'issue; altrimenti — errore di parametro (il cambio di tracker non è modellato tramite questo strumento).
- Output — snapshot del form senza paginazione:
  - `project`: `id`, `name`, `identifier`;
  - `trackers`: tracker che l'utente corrente può selezionare su questo form (`id`, `name`), non tutti i tracker abilitati per il progetto;
  - `priorities`: priorità attive (`id`, `name`, `is_default`);
  - `categories`: categorie del progetto (`id`, `name`);
  - `versions`: versioni disponibili per la selezione su questo form (`id`, `name`, `status`, `due_date`);
  - `assignees`: principal che possono essere assegnati in questo contesto di form. Elemento: `id`, `name`, `type` (`user` o `group`); per `user`, inoltre `login`. I gruppi sono inclusi se Redmine ha abilitato l'assegnazione delle issue ai gruppi;
  - `custom_fields`: solo i campi che l'utente corrente può modificare sul form, considerando progetto/tracker, visibilità, workflow read-only. Elemento: `id`, `name`, `field_format`, `required` (campo obbligatorio o obbligatorio dal workflow), `readonly` (sempre `false` in questa lista), `multiple`, `default_value`, `possible_values`, `trackers`. Contesto del form — issue da `issue_id` o bozza di creazione considerando `tracker_id`;
  - `possible_values` — array di oggetti `{ "label": "...", "value": "..." }`. Per le liste senza etichette separate, `label` corrisponde a `value`. Per user/version/enumeration, `label` è il nome visualizzato, `value` è l'identificatore;
  - `statuses`: stati consentiti dal workflow per l'utente corrente. Con `issue_id` — transizioni per questa issue visibile. Senza `issue_id` — stati iniziali per la creazione (considerando `tracker_id` se impostato);
  - `editable_fields`: nomi degli attributi che questo contratto MCP accetta in create/update che l'utente corrente può impostare sul form, più gli id dei campi personalizzati modificabili come stringhe. Non include `notes`, `private_notes`, `watcher_user_ids` e altri campi del form web assenti dagli strumenti di scrittura MCP;
  - `required_fields`: nomi dei campi obbligatori su questo form per l'utente corrente, nella stessa forma di nome di `editable_fields`.
- `tracker_id` inesistente, tracker non consentito per l'utente, o `issue_id` fuori dal progetto / non visibile — errore di parametro.

### `add_issue_note`

- Aggiunge un commento a un'issue esistente visibile senza modificare gli attributi dell'issue.
- Input: `issue_id` (obbligatorio), `notes` (obbligatorio), opzionalmente `private_notes`, `uploads` e `idempotency_key`.
- Permesso: l'utente può aggiungere commenti a questa issue. `private_notes=true` richiede il permesso di rendere privati i commenti; altrimenti — negato, nessun commento viene creato. Gli allegati nella stessa chiamata sono consentiti se l'utente può aggiungere allegati all'issue.
- Non accetta campi dell'issue o liste di watcher.
- Output: `issue_id`, `journal_id`, `notes`, `private_notes`; con `uploads` — `added_attachments` (solo i file di questa chiamata).
- Non disponibile in modalità read-only.

### `update_issue_note`

- Lavora solo con una voce del journal che l'utente corrente **vede** (commenti privati di un altro utente senza permesso di visualizzare note private sono inaccessibili).
- La voce deve essere modificabile dall'utente corrente (permesso di modificare commenti o propri commenti).
- Input: `journal_id` (obbligatorio); è richiesto almeno uno tra `notes` o `private_notes`.
- `notes` può essere una stringa vuota (cancellare il testo di una voce esistente). Un nuovo commento tramite `add_issue_note` non può essere vuoto.
- Modificare la privacy (`private_notes`) richiede un permesso separato per rendere privati i commenti; altrimenti negato, il testo non viene modificato parzialmente.
- Output — oggetto journal (`JOURNAL`), come quando si modifica il testo.
- Registra chi ha modificato la voce del journal.
- Non disponibile in modalità read-only.
- Non disponibile in modalità read-only.

### `list_trackers`

- Senza `project`: tutti i tracker dell'istanza Redmine (`id`, `name`, `description`).
- Con `project`: solo tracker abilitati per il progetto visibile; `description` è stringa vuota per uno schema di risposta uniforme.
- Un `project` mancante o invisibile restituisce `NOT_FOUND`, non `FORBIDDEN`.

### `list_issues` — filtri estesi

- I filtri piatti esistenti (`project`, `status_id`, `tracker_id`, `assigned_to_id` / `assignee_ref`, `priority_id`, `fixed_version_id`, `sort`, `fields`) sono preservati.
- Opzionale `filters`: array di oggetti `{ "field": "...", "operator": "...", "values": ["..."] }`. `values` è un array di stringhe; un array vuoto è consentito per operatori senza valori.
- `field` consentiti: `status_id`, `tracker_id`, `assigned_to_id`, `priority_id`, `fixed_version_id`, `category_id`, `parent_id`, `subject`, `due_date`, `start_date`, `created_on`, `updated_on`, `estimated_hours`, `done_ratio`, `author_id`, `watcher_id` e `cf_<id>` per i campi personalizzati delle issue.
- Gli operatori sono gli operatori standard delle query Redmine, inclusi `=`, `!`, `>=`, `<=`, `><`, `~`, `!~`, `o`, `c`, `*`, `!*`. L'operatore deve essere valido per il tipo di campo; altrimenti — errore di parametro.
- `field` sconosciuto o `operator` non valido — errore di parametro, la query non viene eseguita.
- I filtri piatti e `filters` sono combinati con AND.
- I filtri si applicano solo alle issue visibili all'utente corrente.
- Sotto-issue dirette: `filters` con `field` `parent_id`, `operator` `=`, uno o più valori — ID issue genitore. Più ID in una stringa separati da virgola (stile Redmine: `"123,456"`), oppure più elementi `values` che MCP unisce in una stringa prima della query. Ogni genitore indicato deve essere visibile all'utente; altrimenti — errore «issue non trovata» (come `get_issue`). Lo strumento separato `list_subtasks` è stato rimosso.


### `list_project_activities`

- Questo è il feed eventi del progetto ("cosa è successo"), non il catalogo dei tipi di attività di lavoro per la registrazione del tempo. I tipi di attività di lavoro — `list_time_entry_activities`.
- Input: `project` (obbligatorio); opzionalmente `from`, `to` (date `YYYY-MM-DD`), `author_id`, `event_types` (array di stringhe), `limit`/`offset`.
- Finestra predefinita — ultimi 7 giorni (`to` = oggi, `from` = oggi meno 6 giorni). Lunghezza massima della finestra — 90 giorni; se superata — errore di parametro.
- Eventi dal feed attività del progetto: tipo, ora, autore (`id`/`name`), `title`, `description`, `url`. Ordine — eventi più recenti prima; per uguale ora — `id` più alto prima.
- Envelope come gli altri `list_*`.
- `event_types` limita i tipi di evento. Un tipo non disponibile per l'utente o disabilitato nel progetto è escluso dalla selezione (senza errore).
- `author_id` inesistente — lista vuota, non un errore.

### `summarize_project_status`

Non è un oggetto Redmine, ma un'aggregazione lato server su issue e registrazioni tempo visibili del progetto.

I campi esistenti sono preservati: `project_id`, `project_name`, `analysis_period_days`, `recent_activity` (`created_count`, `updated_count`), `totals` (`issues_count`, `open_count`, `closed_count`), `status_breakdown`, `priority_breakdown`, `assignee_breakdown`.

La finestra `days` (predefinito 30, intervallo 1–365) influisce ancora su `recent_activity` e sulle metriche del periodo elencate di seguito. Un valore fuori dall'intervallo viene rifiutato dallo schema. `totals` e le breakdown sono calcolati su tutte le issue visibili del progetto senza filtro per data, tramite aggregazione DB, senza caricare tutte le issue in memoria. I sottoprogetti non sono inclusi.

Campi aggiuntivi:

- `overdue_count` — numero di issue aperte visibili con `due_date` strettamente precedente al giorno odierno dell'utente.
- `unassigned_count` — numero di issue aperte visibili senza assegnatario.
- `stale_issues_count` — numero di issue aperte visibili con `updated_on` precedente all'inizio della finestra `days`.
- `issues_closed_during_period` — numero di issue visibili con `closed_on` entro la finestra `days`.
- `estimated_hours` — somma delle stime delle issue visibili del progetto (`null` se nessuna ha una stima, altrimenti un numero incluso 0).
- `spent_hours` — somma del tempo trascorso sulle issue visibili del progetto (0 se nessuna voce). Richiede `view_time_entries` sul progetto; senza permesso il campo è `null`.
- `average_resolution_hours` — media di `(closed_on - created_on)` in ore per le issue chiuse nella finestra `days`; `null` se non ci sono tali issue.
- `estimation_accuracy` — per le issue chiuse nella finestra che hanno sia una stima sia tempo non zero/registrato: `{ "issues_count", "total_estimated", "total_spent" }`. Se non ci sono issue corrispondenti — `{ "issues_count": 0, "total_estimated": 0, "total_spent": 0 }`. Richiede `view_time_entries` sul progetto; senza permesso il campo è `null`.
- `reopened_count` — numero di issue visibili il cui stato nel journal è passato da chiuso ad aperto entro la finestra `days`. Ogni issue viene contata al massimo una volta.

Lo strumento restituisce fatti, non un'analisi testuale dello "stato di salute del progetto".

### `list_versions` / `get_version`

`Version` in questi strumenti è un'entità Redmine (fase roadmap / milestone), non la versione di un prodotto software. `list_versions` restituisce le versioni roadmap del progetto, incluse quelle condivise.

### `get_version`

- Input: `version_id` (obbligatorio); opzionalmente `project`. Se `project` è impostato, la versione è accessibile quando si trova nelle versioni condivise di questo progetto visibile (anche se il progetto sorgente della versione non è visibile all'utente). Senza `project`, la versione deve essere visibile sul suo progetto sorgente.
- Output: campi come un elemento di `list_versions` (`id`, `name`, `description`, `status`, `due_date`, `sharing`, `wiki_page_title`, `project`, `created_on`, `updated_on`) più aggregati: `issues_count`, `open_issues_count`, `closed_issues_count`, `estimated_hours`, `spent_hours`, `completed_percent`.
- Gli aggregati sono calcolati solo sulle issue della versione visibili all'utente corrente.
- La lista delle issue non viene restituita.
- `spent_hours` richiede `view_time_entries` sul progetto della versione; senza permesso — `null`. Somma solo sulle issue visibili della versione e solo sulle registrazioni del tempo che l'utente corrente può vedere (incluso `time_entries_visibility=own`).

### Repository / SCM

- Il modulo Repository del progetto deve essere abilitato; altrimenti errore «Repository module is not enabled for this project».
- `list_repositories` / `get_repository`: permesso `view_changesets` **o** `browse_repository`. Senza `repository_id` il repository è selezionato secondo la regola Redmine: `project.repository || project.repositories.first`.
- `list_revisions` / `get_revision`: permesso `view_changesets`. L'elenco è costruito da changeset in cache (`Changeset.visible`); commit recenti senza fetch possono mancare.
- `get_revision`: lookup tramite `repository.find_changeset_by_name` per numero revisione o hash prefisso; **non** accetta branch/tag (per ref SCM — `get_repository_file` / `get_repository_diff`); issue collegate — solo `Issue.visible`; `file_changes` — solo con `:browse_repository`.
- `get_repository`: metadata (`id`, `scm_type`, `name`, …) restituiti anche se `default_branch` non è disponibile da SCM; in tal caso `default_branch` è `null`.
- `get_repository_file` / `get_repository_diff`: permesso `browse_repository`. Senza `repository_id` si usa il repository predefinito del progetto. Revisione predefinita — `default_branch`; il parametro può essere branch/tag/hash (adattatore SCM). Errore SCM nella risoluzione della revisione predefinita (`revision` omessa) — `REDMINE_API_ERROR`.
- `get_repository_file`: directory — `entries` paginate; file di testo — `content` inline; binario — metadata, opzionalmente `content_base64` (campo separato). La binarietà è determinata dal contenuto: UTF-8 non valido, byte nullo o alta quota di byte di controllo. Un'estensione di testo non sovrascrive questo risultato. Dimensione limitata da `min(Setting.file_max_size_displayed, MCP cap 10 MiB)`.
- `get_repository_diff`: diff unificato con troncamento per `min(Setting.diff_max_lines_displayed, MCP line cap)` e limite byte MCP (512 KiB).
- Repository/revisione/percorso assenti — `NOT_FOUND`; errore adattatore SCM — `REDMINE_API_ERROR`, non `NOT_FOUND` né `INTERNAL_ERROR`.
- Tutti gli strumenti Repository sono visibili in `tools/list` se l'utente vede almeno un progetto. Essere nell'elenco non implica il diritto di chiamata: una chiamata senza il permesso richiesto restituisce `FORBIDDEN` e non nasconde lo strumento. Lo stato del modulo Repository è verificato alla chiamata dopo il controllo del permesso: senza permesso — `FORBIDDEN` (anche con modulo disabilitato); con permesso e modulo disabilitato — `INVALID_STATE`.
- Non restituisce `url`, `root_url`, `login`, `password`, `extra_info`.

### Forum

- Il modulo forum del progetto deve essere abilitato; altrimenti errore "Boards module is not enabled for this project" (analogo wiki).
- Permesso `view_messages`. Nessuna operazione di scrittura sul forum.
- `list_boards`: `project` obbligatorio; paginazione. Elemento: `id`, `name`, `description`, `parent_id` (`null` per la board radice), `topics_count`, `messages_count`.
- `list_board_topics`: `board_id` obbligatorio; paginazione. Solo messaggi radice (senza genitore). Elemento: `id`, `subject`, `author`, `created_on`, `updated_on`, `replies_count`, `board_id`.
- `get_board_message`: `message_id` obbligatorio. Output: `id`, `subject`, `content`, `author`, `created_on`, `updated_on`, `board` (`id`/`name`), `project` (`id`/`name`/`identifier`), `parent_id`, `replies` — breve lista di risposte (`id`, `subject`, `author`, `created_on`) senza testo completo di ogni risposta, con `replies_limit`/`replies_offset` (predefinito e massimo 100) e `replies_pagination`.
- Board/messaggio invisibile o board di un altro progetto — errore "not found".

### `list_users`

- Con `project`: membri attivi del progetto che sono **utenti** (permesso `view_members`). L'appartenenza a un gruppo nel progetto non compare come gruppo; utenti di un gruppo solo se sono membri essi stessi. Senza `project` — solo amministratore.
- Elemento con `project`: `id`, `login`, `firstname`, `lastname`, `mail` (senza `created_on`). L'elenco globale dell'amministratore senza `project` include inoltre `created_on`.
- `query` opzionale: sottostringa senza distinzione maiuscole/minuscole su `login`, `firstname` e `lastname`.
- `login` opzionale è conservato (solo sottostringa su login) per compatibilità. Se sono impostati sia `query` sia `login`, si applicano entrambe le condizioni (AND).
- `name` e `group_id` opzionali — solo amministratore senza `project`. `name` — sottostringa via `User.like` (login, firstname, lastname, email). `group_id` — utenti del gruppo. `name` e `group_id` possono essere combinati; con `query`/`login` le condizioni si combinano con AND. Con `project` o per un non amministratore, `name`/`group_id` — errore di parametro o accesso negato.

### `list_project_files`

- Elenco paginato dei file dalla sezione File del progetto e allegati delle sue versioni. Non include allegati di issue o Wiki — leggerli tramite `get_issue` / `get_wiki_page` con `include_attachments`.
- Input: `project` (obbligatorio), paginazione. Permesso `view_files`.
- Nome completo canonico — `redmine_list_project_files`.
- Il nome precedente `list_files` (`redmine_list_files`) resta un alias invocabile almeno fino alla prossima versione major: stessi permessi, input, output e comportamento; `tools/call` con il vecchio nome esegue la stessa operazione; l'alias non è pubblicato in `tools/list`; le chiamate alias sono distinguibili nell'audit log dal nome dello strumento invocato.
- I link da altri strumenti usano il nome canonico.

### `list_groups`

- Lista paginata di gruppi assegnabili (`id`, `name`), **visibili** all'utente corrente, per selezionare `group_id` in `add_project_member`.
- Opzionale `query`: sottostringa case-insensitive sul nome del gruppo; `%` e `_` corrispondono letteralmente.
- Permesso: amministratore o `manage_members` su almeno un progetto visibile.
- Non restituisce l'appartenenza al gruppo o le membership.

### `list_project_member_candidates`

- Candidati per l'aggiunta al progetto: utenti e gruppi attivi visibili non ancora nel progetto.
- Input: `project` (obbligatorio); opzionalmente `query` (sottostringa, come nel selettore membri di Redmine).
- Envelope della lista di output: `id`, `name`, `type` (`user` o `group`); per l'utente, inoltre `login`.
- Permesso `manage_members` sul progetto.
- `add_project_member`: `user_id` solo per utente, `group_id` solo per gruppo. ID del tipo sbagliato — errore di parametro. Prima dell'aggiunta, prendere gli ID da questo strumento (o da `list_users` / `list_groups` se il candidato è già noto).

### `list_roles`

- Solo i ruoli che l'utente corrente può gestire nel progetto specificato.
- Input: `project` (obbligatorio).
- Permesso `manage_members` sul progetto.
- Per l'amministratore, l'insieme corrisponde ai ruoli di progetto assegnabili (senza Non member / Anonymous).

## Casi limite

- Modalità read-only — `{ "error": "MCP is in read-only mode..." }` per gli strumenti di scrittura **prima** di chiamare l'handler, inclusi gli strumenti Extension API; form options/list/get restano disponibili.
- Modalità read-only — `{ "error": "MCP is in read-only mode..." }` per gli strumenti di scrittura **prima** di chiamare l'handler, inclusi gli strumenti Extension API; validate/form options/list/get restano disponibili.
- Risultato lista/ricerca vuoto — `{ "ok": true, "data": { "items": [] }, "meta": { ... } }`.
- Tutti gli strumenti `list_*` (inclusi riferimenti: tracker, stati, ruoli, query, forum, topic del forum, ecc.) usano lo stesso envelope. `get_issue_form_options`, `get_project`, `get_version`, `get_board_message`, `summarize_project_status` — oggetti singoli, non envelope di lista.
- Tutti gli strumenti `list_*` (inclusi i riferimenti: tracker, stati, ruoli, query, board, topic delle board, ecc.) usano lo stesso envelope. `get_issue_form_options`, `get_project`, `get_version`, `get_board_message`, `summarize_project_status` e gli strumenti validate — oggetti singoli, non envelope di lista.
- `get_attachment`: allegato inesistente e inaccessibile — stesso errore «non trovato»; con `include_content: true`, file illeggibile su disco — errore; dimensione su disco o dopo lettura oltre 10 MiB — `FILE_TOO_LARGE` (il limite non si aggira con un `filesize` DB più basso); richieste solo metadati senza limite di dimensione.
- `list_project_activities`: finestra superiore a 90 giorni — errore di parametro; `from` dopo `to` — errore di parametro.
- `list_issues` con `query_id`: query invisibile — trattata come inesistente; `query_id` insieme a filtri aggiuntivi — errore di parametro.
- `get_issue_form_options` con `issue_id` per un'issue di un altro progetto — errore di parametro.
- Gli strumenti validate non creano un'issue, non aggiornano un'issue, non creano voci del journal e non consumano `idempotency_key`.
- Le scritture tramite MCP passano attraverso i modelli Redmine. I callback del modello vengono eseguiti; gli hook del controller dell'interfaccia web non vengono chiamati.

## Gestione degli errori

- Errori di validazione del modello — `{ "error": "<messages>" }` (per create/update di issue inoltre `missing_required_fields` come nomi di campo dai simboli di errore del modello, senza analizzare il testo di traduzione, e `hint`).
- Errori di validazione del modello — `{ "error": "<messages>" }` (per create/update issue e strumenti validate inoltre `missing_required_fields` come nomi dei campi dai simboli di errore del modello, senza analizzare il testo di traduzione, e `hint`).
- Modulo wiki/boards disabilitato — messaggio di errore separato, non "not found".
- Il codice di errore canonico nell'envelope è impostato esplicitamente dall'handler; il codice non deriva dal testo del messaggio e non dipende dalla lingua dell'utente.

## Scenari di test

1. `list_projects` / `list_issues` restituiscono envelope `data.items` + `meta` con paginazione.
2. `get_issue` senza `include_*` non restituisce journal/allegati; con `include_journals` — journal con paginazione.
3. `search_issues` per testo trova issue; `search_all` include wiki quando si cercano più tipi.
4. `create_issue` / `update_issue` con campi validi hanno successo; senza permesso o in read-only — errore.
4a. `create_issue` senza `start_date` con impostazione data di inizio abilitata imposta la data odierna; `start_date` esplicito o `null` non viene sovrascritto da quell'impostazione.
5. `delete_issue` senza `confirm_delete` restituisce `INVALID_STATE` e impact; con conferma elimina.
6. `create_time_entry` requires `hours` and `project` or `issue_id`.
7. `list_wiki_pages` / `get_wiki_page` / `create_wiki_page` funzionano con il modulo Wiki abilitato.
8. `upload_file` richiede `filename` e `content_base64`; `delete_attachment` per allegato di issue richiede conferma.
9. Utente senza `use_mcp` non supera l'autenticazione MCP; senza permesso per lo strumento non lo vede in `tools/list`.
10. Retry di `create_issue` con la stessa `idempotency_key` e gli stessi argomenti non crea un duplicato; stessa chiave con subject diverso — `CONFLICT`.
11. `get_attachment` con `include_content: true` per allegato issue visibile restituisce `content_base64` e `content_url` con `size` effettiva del contenuto; file > 10 MiB su disco (anche con metadati piccoli) — `FILE_TOO_LARGE`; senza `include_content`, file grandi — solo metadati; inesistente e inaccessibile indistinguibili; `redmine_download_attachment` assente in `tools/list`.
12. `get_project` per identificatore restituisce description, subprojects e `last_activity_date`; progetto inaccessibile — errore.
13. `get_issue_form_options` per progetto restituisce trackers/statuses/priorities/categories/versions/assignees/custom_fields e liste `editable_fields` / `required_fields`; `trackers` — solo quelli disponibili per l'utente corrente; con `issue_id` gli stati riflettono le transizioni consentite per quell'issue; `issue_id` + `tracker_id` diverso — errore; `possible_values` — oggetti `label`/`value`.
14. `create_issue` con tracker o stato non valido restituisce errore e non crea l'issue.
15. `list_issues` con `filters` (`due_date` `<=` data, `priority_id` `!`, `parent_id` `=` per sotto-issue) restituisce solo issue visibili corrispondenti; `field` sconosciuto — errore; `parent_id` `=` con genitore invisibile (incluso qualsiasi ID in un elenco separato da virgole) — errore «issue non trovata».
16. `list_issues` con `query_id` visibile restituisce gli stessi ticket della query salvata nell'UI; query invisibile — errore; `query_id` con `filters` — errore di parametro.
17. `list_project_activities` per 3 giorni restituisce eventi del progetto con paginazione; finestra di 91 giorni — errore.
18. `summarize_project_status` include `overdue_count`, `unassigned_count`, `stale_issues_count`, `issues_closed_during_period` e `reopened_count`.
19. `get_version` restituisce aggregati `open_issues_count` / `completed_percent` senza lista di issue.
20. `list_boards` / `list_board_topics` / `get_board_message` funzionano con il modulo Boards abilitato; quando disabilitato — errore del modulo.
21. `list_users` con `project` e `query` per nome trova il membro senza conoscere il login.
22. `get_issue_form_options` restituisce assignees con `type` user/group e solo campi personalizzati modificabili con `required`/`readonly`.
23. `create_issue` / `update_issue` / `copy_issue` con valore passato esplicitamente che Redmine non applica (inclusi campi base disabilitati/read-only, incluso `description` in creazione) restituiscono errore e non salvano modifiche parziali.
24. `add_issue_note` con `add_issue_notes` riesce senza `edit_issues`; `private_notes` senza `set_notes_private` — negato. `update_issue` con solo `uploads` riesce con permesso di aggiungere allegati senza `edit_issues`.
25. `list_groups` restituisce gruppi assegnabili per utente con `manage_members`.
26. `update_issue` con `assigned_to_id`/`category_id`/`fixed_version_id`/`parent_issue_id`/`start_date`/`due_date`/`estimated_hours` = `null` cancella il campo se scrivibile.
27. `update_issue_note` non modifica il commento privato di un altro utente senza permesso di vedere commenti privati.
28. Utente con permesso di modificare commenti ma non di renderli privati può modificare il testo del commento pubblico e non può modificare il flag di privacy.
29. `add_issue_note` con `uploads` crea commento e allegato in una chiamata; retry con la stessa `idempotency_key` non li duplica.
30. `update_issue` con `uploads` e `idempotency_key`: retry con lo stesso payload non duplica l'allegato; file diverso con la stessa chiave — `CONFLICT`. Base64 corrotto — errore di parametro.
31. `get_issue` non restituisce campi personalizzati nascosti, dettagli del journal invisibili o relazioni con issue invisibili. `get_version` aggrega solo sulle issue visibili.
32. `copy_issue` senza permesso di copiare sul progetto sorgente — negato, anche con `add_issues` sulla destinazione.
33. `add_project_member` / `update_project_member` con ruolo che l'utente non può gestire — negato senza assegnazione parziale.
34. `create_version` / `update_version` con `sharing` non consentito per l'utente — negato. `delete_version` per versione occupata — negato senza eliminazione.
35. Autore della registrazione del tempo con `edit_own_time_entries` può aggiornare la propria voce tramite `update_time_entry`.
36. `search_all` disponibile per utente con permesso wiki senza `view_issues`, se la ricerca include wiki.
37. `list_project_member_candidates` restituisce utenti e gruppi non ancora nel progetto; `add_project_member` con `user_id` di gruppo — errore.
38. `list_roles` per progetto restituisce solo i ruoli che l'utente può gestire; senza `project` — errore di schema. Non include i built-in Non member e Anonymous.
39. Retry di `copy_issue` / `create_time_entry` con la stessa `idempotency_key` non crea duplicato; payload diverso con la stessa chiave — `CONFLICT`.
40. `search_issues` e ricerca utente/gruppo per `%` o `_` corrispondono a quei caratteri letteralmente, non come wildcard.
41. `get_version.spent_hours` con `time_entries_visibility=own` conta solo le proprie registrazioni del tempo.
42. `search_issues` con `scope=subprojects` senza `project` — errore; con `project` trova issue nei discendenti.
43. `list_project_activities` restituisce eventi più recenti prima di quelli più vecchi.
44. L'impact di `delete_issue` non include journal nascosti, relazioni e registrazioni del tempo di altri; le sottoattività nascoste richiedono comunque `confirm_delete_with_children`.
45. `get_project` non restituisce un genitore invisibile all'utente corrente.
46. `update_version` con `due_date`/`wiki_page_title` = `null` cancella il campo.
47. `update_issue_category` con `assigned_to_id` = `null` cancella l'assegnatario predefinito.
48. Lo schema accetta `hours` pari a 0 e valori superiori a 24; solo la validazione Redmine rifiuta.
49. `update_issue_note` con `notes` vuoto cancella il testo del commento esistente.
50. `list_users` con `project` restituisce solo utenti, anche se il progetto ha membership di gruppo.
51. Versione storica di pagina wiki senza `view_wiki_edits` è inaccessibile; pagina protetta non può essere modificata senza permesso di proteggere wiki.
52. `copy_issue` senza permesso di aggiungere watcher non copia i watcher; `link_copied_issue` / `copy_attachments_on_issue_copy` = `no` vietano collegamento e allegati; il genitore nello stesso progetto viene preservato.
53. Strumento di scrittura Extension in read-only mode non invoca l'handler.
54. `delete_attachment` visibile in `tools/list` per utente che può eliminare allegati di issue, senza `manage_files`.
55. `add_issue_watcher` / `remove_issue_watcher` accettano principal di gruppo.
56. `get_version` con `project` restituisce versione condivisa che `list_versions` per quel progetto ha restituito.
57. `get_issue` / `get_wiki_page` / `get_board_message` limitano le liste annidate con `limit`/`offset` e restituiscono `*_pagination`; senza include la paginazione è `null`.
58. Le risposte effettive degli strumenti, inclusi i campi nullable, corrispondono all'`outputSchema` pubblicato.
59. `get_issue` con `include_journals`: journal con solo dettaglio di campo personalizzato nascosto non è nella lista e non è conteggiato in `journal_pagination.total_count`.
60. Journal nascosto tra due visibili non crea un gap di pagina: con `journal_limit=2` vengono restituite due voci visibili, `total_count` corrisponde al conteggio visibile.
61. Il commento privato di un altro utente non viene restituito in `get_issue` senza permesso `view_private_notes`.
62. `get_private_notes` restituisce una pagina per `limit`/`offset` senza caricare l'intera cronologia dell'issue.
63. `get_issue` con journal `attr`, `cf` e `relation` contemporaneamente non fallisce e restituisce solo voci visibili.
64. Journal con dettaglio di campo personalizzato nascosto e note di spazi, tab o interruzioni di riga non è incluso in `get_issue`.
65. `get_private_notes` non restituisce un commento composto solo da spazi, tab o interruzioni di riga.
71. `list_repositories` / `get_repository` sono disponibili con `browse_repository` senza `view_changesets` e viceversa per discovery; `list_revisions` / `get_revision` richiedono `view_changesets`; `get_repository_file` / `get_repository_diff` richiedono `browse_repository`. Senza il permesso richiesto la chiamata restituisce `FORBIDDEN`, lo strumento resta in `tools/list`.
72. `get_repository_file` restituisce testo in `content`, file binario — metadata senza `content`; `include_content_base64` — campo separato. Un file con UTF-8 non valido (inclusa firma PNG senza byte nulli) è trattato come binario. Un `.txt` con NUL è binario nonostante l'estensione.
73. `get_repository_diff` tronca il diff per limiti di righe/byte e restituisce `truncated: true`.
74. Errore adattatore SCM restituisce `REDMINE_API_ERROR`, non `NOT_FOUND`.
75. `list_repositories` / `list_revisions` / strumenti file funzionano con modulo Repository abilitato. Con permesso e modulo disabilitato — `INVALID_STATE`; senza permesso e modulo disabilitato — `FORBIDDEN`.
76. `get_revision` non restituisce `file_changes` senza `:browse_repository`.
77. `get_repository_file` senza `revision` con errore SCM su `default_branch` restituisce `REDMINE_API_ERROR`.
78. `get_repository` con errore SCM su `default_branch` restituisce metadata con `default_branch: null`.
79. Tutti gli strumenti Repository sono visibili in `tools/list` per qualsiasi combinazione di `view_changesets` / `browse_repository`, inclusa nessuna, se l'utente vede almeno un progetto.
80. `update_issue` con `project` sposta l'issue in un progetto di destinazione consentito; identifier sconosciuto — `NOT_FOUND` (non `FORBIDDEN`); progetto di destinazione senza `add_issues` — `rejected_fields` con `project_id`, l'issue non cambia progetto.
81. `get_mcp_info` restituisce `text_formatting` con il formato effettivo (`common_mark`, `textile`, stringa vuota o codice di formato di terze parti registrato).
82. Dopo la modifica del formato di testo senza riavviare Redmine, la successiva chiamata a `get_mcp_info` restituisce il nuovo valore di `text_formatting`.
83. Se le impostazioni indicano un formato non registrato, `get_mcp_info` restituisce `text_formatting: ""`.
