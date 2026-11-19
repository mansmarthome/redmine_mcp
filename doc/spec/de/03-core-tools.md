# Eingebaute Tools (Core-Tools)

[Deutsch](03-core-tools.md) | [English](../en/03-core-tools.md) | [Español](../es/03-core-tools.md) | [Français](../fr/03-core-tools.md) | [Italiano](../it/03-core-tools.md) | [日本語](../ja/03-core-tools.md) | [한국어](../ko/03-core-tools.md) | [Polski](../pl/03-core-tools.md) | [Português (Brasil)](../pt-BR/03-core-tools.md) | [Русский](../ru/03-core-tools.md) | [中文](../zh/03-core-tools.md)

## Überblick

Das Redmine-MCP-Plugin stellt eine Reihe von Tools für die Arbeit mit Redmine-Projekten, Vorgängen, Zeiterfassung, Wiki, Foren, Dateien und Referenzdaten bereit (Lesen und Schreiben).

## Ziel

AI-Clients erhalten Projektmanagement, Vorgangsoperationen, Zeiterfassung, Entdeckung, Suche & Wiki, Foren, Dateioperationen und Meta-Operationen, ohne zusätzliche Plugins zu installieren.

## Betroffene Gebiete

- Projekte
- Versionen
- Mitglieder / Rollen
- Probleme (CRUD, Beziehungen, Beobachter, Notizen, Kategorien, Formularoptionen, gespeicherte Abfragen)
- Zeiteinträge
- Tracker, Status, Prioritäten, Abfragen
- Projektaktivität
- Wiki-Seiten
- Foren / Nachrichten
- Projektdateien/Anhänge
- Benutzer
- Berechtigungen
- Einstellungen (schreibgeschützter Modus)

## Geschäftsregeln

### Allgemeine Regeln

- Vollständiger Toolname: `redmine_<name>` (zum Beispiel `redmine_get_issue`).
- Das Ergebnis wird als JSON-Umschlag in `structuredContent` zurückgegeben und als Text in `content` dupliziert.
- Daten werden durch Sichtbarkeit und Berechtigungen von Redmine-Projekten/-Vorgängen gefiltert.
- Der Parameter `project` ist eine Zeichenfolge: numerische ID als Zeichenfolge (z. B. `"1"`) oder Projektkennung (z. B. `"ecookbook"`).
- Ein explizit angegebenes fehlendes oder unsichtbares `project` liefert `NOT_FOUND` vor der Tool-Berechtigungsprüfung (siehe [02-authentication.md](02-authentication.md)); ein sichtbares Projekt ohne erforderliche Berechtigung liefert `FORBIDDEN`. Tools ohne `project` sind nicht betroffen.
- Wenn der **Schreibgeschützte Modus** aktiviert ist, geben Schreibtools einen Fehler zurück. Schreibgeschützte Tools, einschließlich `list_issue_relations` und `get_issue_form_options`, bleiben weiterhin verfügbar.

### Projektmanagement

| Tool | L/S | Berechtigung |
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

### Vorgangsoperationen

| Tool | L/S | Berechtigung |
|------|-----|------------|
| `get_issue` | R | `view_issues` |
| `list_issues` | R | `view_issues` |
| `search_issues` | R | `view_issues` |
| `get_issue_form_options` | R | `view_issues` |
| `create_issue` | W | `add_issues` |
| `update_issue` | W | Attribute — wenn bearbeitbar; `uploads` nur — wenn Anhänge hinzugefügt werden können |
| `add_issue_note` | W | `add_issue_notes`; `private_notes=true` erfordert zusätzlich `set_notes_private` |
| `delete_issue` | W | `delete_issues` |
| `copy_issue` | W | `copy_issues` für das Quellprojekt und `add_issues` für das Ziel |
| `list_issue_relations` | R | `view_issues` |
| `create_issue_relation` | W | `manage_issue_relations` |
| `delete_issue_relation` | W | `manage_issue_relations` |
| `add_issue_watcher` | W | `add_issue_watchers` |
| `remove_issue_watcher` | W | `delete_issue_watchers` |
| `update_issue_note` | W | Journaleintrag sichtbar und bearbeitbar (`edit_issue_notes` / `edit_own_issue_notes`); Änderung von `private_notes` erfordert zusätzlich `set_notes_private` |
| `get_private_notes` | R | `view_private_notes` |
| `list_issue_categories` | R | `view_issues` |
| `create_issue_category` | W | `manage_categories` |
| `update_issue_category` | W | `manage_categories` |
| `delete_issue_category` | W | `manage_categories` |

### Benutzer

| Tool | L/S | Berechtigung |
|------|-----|------------|
| `list_users` | R | `view_members` + `project`; ohne `project` – nur Administrator |
| `list_groups` | R | `manage_members` (für jedes Projekt) oder admin |

### Zeiterfassung

| Tool | L/S | Berechtigung |
|------|-----|------------|
| `list_time_entries` | R | `view_time_entries` |
| `create_time_entry` | W | `log_time` |
| `update_time_entry` | W | Eintrag kann vom aktuellen Benutzer bearbeitet werden (`edit_time_entries` / `edit_own_time_entries`) |
| `list_time_entry_activities` | R | `log_time` |

`list_time_entry_activities` — Katalog der Arbeitsaktivitätstypen für die Zeiterfassung, nicht der Projekt-Ereignisfeed (`list_project_activities`).

### Entdeckung / Aufzählung

| Tool | L/S | Berechtigung |
|------|-----|------------|
| `list_trackers` | R | `view_issues` |
| `list_issue_statuses` | R | `view_issues` |
| `list_issue_priorities` | R | `view_issues` |
| `get_current_user` | R | `use_mcp` |
| `list_queries` | R | `view_issues` |

### Suche & Wiki

| Tool | L/S | Berechtigung |
|------|-----|------------|
| `search_all` | R | Zugriff auf mindestens einen der durchsuchten Typen (`view_issues` und/oder `view_wiki_pages`) |
| `list_wiki_pages` | R | `view_wiki_pages` |
| `get_wiki_page` | R | `view_wiki_pages`; historische `version` erfordert zusätzlich `view_wiki_edits` |
| `create_wiki_page` | W | `edit_wiki_pages` und die Seite muss bearbeitbar sein |
| `update_wiki_page` | W | `edit_wiki_pages` und die Seite muss bearbeitbar sein |
| `delete_wiki_page` | W | `delete_wiki_pages` und die Seite muss bearbeitbar sein |
| `rename_wiki_page` | W | `rename_wiki_pages` und die Seite muss bearbeitbar sein |

### Repository / SCM

| Tool | L/S | Berechtigung |
|------|-----|------------|
| `list_repositories` | R | `view_changesets` **oder** `browse_repository` |
| `get_repository` | R | `view_changesets` **oder** `browse_repository` |
| `list_revisions` | R | `view_changesets` |
| `get_revision` | R | `view_changesets` |
| `get_repository_file` | R | `browse_repository` |
| `get_repository_diff` | R | `browse_repository` |

### Foren

| Tool | L/S | Berechtigung |
|------|-----|------------|
| `list_boards` | R | `view_messages` |
| `list_board_topics` | R | `view_messages` |
| `get_board_message` | R | `view_messages` |

### Dateioperationen

| Tool | L/S | Berechtigung |
|------|-----|------------|
| `list_project_files` | R | `view_files` |
| `upload_file` | W | `manage_files` |
| `delete_attachment` | W | `manage_files` (oder Container-Berechtigungen) |
| `get_attachment` | R | Berechtigungen für den Anhangscontainer |

### Meta

| Tool | L/S | Berechtigung |
|------|-----|------------|
| `get_mcp_info` | R | `use_mcp` |

`get_mcp_info` gibt Metadaten des MCP-Plugins der aktuellen Sitzung zurück, nicht die Redmine-Version und nicht beliebige Anwendungseinstellungen: `server_version` (MCP-Plugin-Version), `read_only_mode`, `auth_mode`, kurze aktuelle Benutzerdaten, `capabilities.issue_search` und `text_formatting`. Die Plugin-Installation von Drittanbietern wird in der Antwort nicht aufgeführt: Ihre MCP-Tools sind über `tools/list` und über `capabilities` sichtbar, die Erweiterungen selbst registrieren.

`text_formatting` ist eine Ausnahme: Es ist die aktuelle Redmine-Textformatierungseinstellung (`Setting.text_formatting`), die bei jedem Aufruf gelesen wird. Clients nutzen sie für Ticketbeschreibungen, Notizen und Wiki-Text. Typische Werte: `common_mark`, `textile`; bei deaktivierter Formatierung — leere Zeichenkette (Klartext); ein registriertes Drittanbieter-Format — dessen Code. Ist in den Einstellungen ein nicht registriertes Format angegeben (z. B. Plugin entfernt), wird eine leere Zeichenkette zurückgegeben — wie die Anzeige in Redmine ohne verfügbare Formatierung. Eine Formatänderung in der Administration ohne Neustart von Redmine ist beim nächsten `get_mcp_info`-Aufruf sichtbar.

Vollständiger Tool-Name — `redmine_get_mcp_info`. Frühere Namen (`get_server_info`, `redmine_get_server_info` und andere aufrufbare Core-Tool-Aliase) sind in dieser Major-Version nicht registriert und werden in `tools/call` nicht akzeptiert.

`capabilities.issue_search` enthält Suchmodi:

| Modus | Standard | Hinweis |
|------|---------|------|
| `keyword` | `available: true`, Tool `redmine_search_issues` | Immer |
| `cross_resource` | `available: true`, Tool `redmine_search_all` | Immer |
| `semantic` | `available: false` | Plugins können via `register_capability(:issue_search, :semantic)` überschreiben |

Wenn `semantic.available: true` lautet, MUSS die Funktion `tool`, `provider` und `use_when` / `avoid_when` enthalten – kurze Hinweise, wann die semantische Suche ausgewählt werden sollte. `Registry#apply_capabilities` normalisiert die Antwort des Anbieters: Wenn der Vertrag verletzt wird, wird `{ available: false }` veröffentlicht.

### Klarstellungen

- `delete_issue` ohne `confirm_delete` gibt eine Auswirkungsvorschau zurück; Wenn es **irgendwelche** Unteraufgaben gibt (einschließlich derjenigen, die für den Benutzer unsichtbar sind), ist `confirm_delete_with_children` erforderlich. Zähler in `impact` decken nur Journale, Beziehungen, Zeiteinträge, untergeordnete Elemente und Anhänge ab, die für den aktuellen Benutzer sichtbar sind.
- `search_issues` mit `scope=subprojects` erfordert `project` und sucht in diesem Projekt und seinen Nachkommen. Ohne `project` ist dieser Bereich ein Parameterfehler. `scope=my_project` beschränkt die Suche auf Projekte, bei denen der Benutzer Mitglied ist.
- `get_issue`: Journale, Anhänge, Beobachter, Beziehungen, untergeordnete Felder und benutzerdefinierte Felder werden nur mit explizitem `include_*` eingebunden. Verschachtelte Listen haben ein separates `limit`/`offset` und ein `*_pagination`-Feld (Zeitschriften: Standardlimit 25, maximal 100; andere verschachtelte Listen: Standard und maximal 100). Ohne das entsprechende `include_*` ist die Liste leer und die Paginierung ist `null`. Optionale Felder (`custom_fields`, `journals`, `attachments`, `watchers`, `relations`, `children`) sind in der Antwort immer vorhanden. Benutzerdefinierte Felder – nur diejenigen, die für den aktuellen Benutzer sichtbar sind. Zeitschriften – gleiche Sichtbarkeit wie der Heftverlauf in Redmine: Ein Eintrag erscheint in `journals` und `journal_pagination` nur, wenn er Text oder mindestens eine Detailänderung enthält, die für den Benutzer sichtbar ist. Text, der nur aus Leerzeichen, Tabulatoren oder Zeilenumbrüchen besteht, wird als leer behandelt. Leere Einträge und Einträge mit nur versteckten Details (einschließlich versteckter benutzerdefinierter Felder) werden sowohl von der Liste als auch von `total_count` / `offset` / `has_more` ausgeschlossen. Private Kommentare – eigene Kommentare oder mit der Berechtigung `view_private_notes`. Journalelemente enthalten nur sichtbare Detailänderungen. Beziehungen – nur Links, bei denen beide Seiten für den Benutzer sichtbar sind. Die gleiche Sichtbarkeitsregel für Beziehungen gilt für `list_issue_relations`.
- `get_private_notes` gibt nur private Kommentare mit nicht leerem Text zurück (Leerzeichen, Tabulatoren und Zeilenumbrüche ohne anderen Inhalt zählen als leerer Text). Die Seite wird durch `limit`/`offset` begrenzt, ohne dass der vollständige Problemverlauf geladen wird.
- `list_project_issue_custom_fields` gibt Felder zurück, die für den Benutzer im Projekt sichtbar sind. Wenn `tracker_id` gesetzt ist, muss der Tracker zum Projekt gehören.
- `copy_issue` erfordert die Berechtigung zum Kopieren von Vorgängen im **Quellprojekt** und die Berechtigung zum Erstellen von Vorgängen im **Ziel**. Beobachter werden nur kopiert, wenn der Benutzer die Berechtigung zum Hinzufügen von Beobachtern zum Zielprojekt hat. Der Link zum Original und das Kopieren des Anhangs folgen den Redmine-Einstellungen `link_copied_issue` und `copy_attachments_on_issue_copy` (`yes` / `no` / `ask`). Ohne Feldüberschreibungen durchläuft die Kopie weiterhin die Formularschreibregeln. Das übergeordnete Problem des Quellproblems bleibt erhalten, wenn dies zulässig ist (auch beim Kopieren innerhalb desselben Projekts).
- `create_issue_relation` wendet nur zulässige Beziehungsattribute an und schreibt die Änderung in das Ausgabejournal. `delete_issue_relation` ist nur zulässig, wenn die Beziehung vom aktuellen Benutzer gelöscht werden kann (beide Probleme sind sichtbar und der Benutzer hat die Berechtigung, Beziehungen auf mindestens einer Seite zu verwalten); Die Löschung wird ebenfalls in das Journal geschrieben.
- `add_project_member` / `update_project_member` akzeptiert nur Rollen, die der aktuelle Benutzer im Projekt verwalten kann. Eine Rolle außerhalb dieser Menge wird abgelehnt; Rollen werden teilweise nicht zugewiesen.
- `create_issue_category` / `update_issue_category`: `assigned_to_id` ist eine Principal-ID (Benutzer oder Gruppe), nicht nur ein Benutzer.
- `delete_attachment` für einen Issue-Anhang folgt der Regel „Können Anhänge zu diesem Issue gelöscht werden“ (einschließlich eigener Issues und Tracker-Berechtigungen), nicht nur global `edit_issues`. In `tools/list` ist das Tool sichtbar, wenn der Benutzer mindestens einen Anhang (Projektdateien, Issues oder Wiki) löschen darf, nicht nur mit globalen `manage_files`.
- `get_wiki_page`: `attachments` ist immer in der Antwort; standardmäßig `[]` und `attachments_pagination: null`; mit `include_attachments=true` – eine paginierte Anhangsliste mit `attachment_limit`/`attachment_offset` (Standard und maximal 100). Für die historische `version` ist die Berechtigung zum Anzeigen von Wiki-Änderungen erforderlich. Das Ändern, Umbenennen oder Löschen einer geschützten Seite erfordert die Erlaubnis zum Schutz von Wiki-Seiten.
- `list_issues`, `search_issues`: standardmäßig Zusammenfassungsfelder; vollständige Beschreibung über `fields` oder `get_issue`.
- Issue-Objekte von `get_issue`, `list_issues`, `search_issues`, `create_issue`, `update_issue` und `copy_issue` enthalten `url` — einen absoluten Web-UI-Link. Der Host stammt aus den Redmine-Einstellungen „Hostname und Pfad“ und dem Protokoll, wie in E-Mails. Wenn „Hostname und Pfad“ leer ist, ist `url` `null` statt eines defekten Links. Die Summary von list/search enthält `url` standardmäßig. `search_all`-Einträge mit `type` `issues` und verschachtelte `children` in `get_issue` enthalten ebenfalls `url`. Beim Zitieren eines Tickets kopiert der Client `url` aus dem Tool-Ergebnis.
- `create_issue` und `update_issue` akzeptieren explizite Problem-**Attribute** (`subject`, `description`, `tracker_id`, `status_id`, `custom_fields` usw.). Alle beim Erstellen explizit übergebenen Attribute, einschließlich `subject` und `description`, durchlaufen dieselben Schreibregeln wie das Redmine-Webformular. Vor dem Erstellen/Aktualisieren SOLLTE der Agent `get_issue_form_options` aufrufen, wenn die zulässigen Feldwerte unbekannt sind. Ein explizit übergebener Wert, den Redmine nicht angewendet hat, führt zu einem Fehler und nicht zu einem Teilerfolg.
- Wenn der Client `start_date` in `create_issue` **nicht übergeben** hat und Redmine „Startdatum = Erstellungsdatum“ aktiviert hat (`default_issue_start_date_to_creation_date`), setzt MCP `start_date` auf den heutigen Tag des Benutzers – wie das neue Ausgabeformular. Ein explizites `start_date` (einschließlich `null`) deaktiviert diese Ersetzung. `copy_issue` und `update_issue` ersetzen nicht das Datum selbst.
- `update_issue` akzeptiert keine `notes`, `private_notes` oder `watcher_user_ids`. Kommentare – `add_issue_note`; Beobachter – `add_issue_watcher` / `remove_issue_watcher`.
- `update_issue` akzeptiert optionales `project` (ID als Zeichenkette oder Identifier), um die Aufgabe in ein anderes Projekt zu verschieben. Es gelten dieselben Regeln wie im Redmine-Webformular: die Aufgabe muss für den aktuellen Benutzer bearbeitbar sein, das Zielprojekt in `Issue#allowed_target_projects` liegen, und es braucht `add_issues` im Zielprojekt (plus das aktuelle Projekt ist immer erlaubt, wenn es übereinstimmt). Die Verschiebung führt die Standard-Callbacks von Redmine aus (`after_project_change`, Aktualisierung verknüpfter Zeiteinträge und Unteraufgaben nach Kernregeln). Ein explizit übergebenes ungültiges Projekt liefert `rejected_fields` mit `project_id` oder einen Fehler „Projekt nicht gefunden“, wenn Identifier/ID nicht existiert oder das Projekt nicht sichtbar ist. `project` kann nicht über `null` geleert werden — nur Wechsel zu einem anderen Projekt. In `get_issue_form_options.editable_fields` erscheint das Feld als `project`, wenn `project_id` auf dem Formular schreibbar ist.
- `update_issue` unterstützt auch `uploads` zum Anhängen von Dateien an ein Problem. Anhänge werden erst nach erfolgreicher Attributvalidierung verarbeitet (einschließlich `rejected_fields`). Ein Aufruf nur mit `uploads` (keine Attribute) ist zulässig, wenn der Benutzer Anhänge zum Problem hinzufügen kann – auch wenn das Kommentieren erlaubt ist, Attribute aber nicht bearbeitet werden können. Der optionale `idempotency_key` schützt vor Wiederholungsversuchen nach einer verlorenen Antwort (einschließlich des erneuten Hochladens derselben Dateien). `journal_id` in der Antwort ist der Journaleintrag für **diesen** Aufruf, nicht der letzte Ausgabeeintrag.
- Um ein optionales Feld zu löschen, übergeben Sie `null` für `assigned_to_id`, `category_id`, `fixed_version_id`, `parent_issue_id`, `start_date`, `due_date` oder `estimated_hours`. Gleiches gilt für `update_version.due_date` / `wiki_page_title` und `update_issue_category.assigned_to_id`.
- `create_issue` unterstützt keine `uploads`.
- `update_issue` akzeptiert `uploads[*].content_base64` und `uploads[*].filename`. Nach einem erfolgreichen Upload enthält die Antwort `added_attachments` – nur Dateien aus diesem Aufruf, nicht die vollständige Liste der Problemanhänge. Beschädigtes Base64 ist ein Parameterfehler.
- `update_issue` akzeptiert `status_name` und löst ihn in `status_id` auf.
- `upload_file` akzeptiert `content_base64` (bis zu 20 MiB); `project`, `filename` und `content_base64` sind erforderlich.
- `get_attachment` liefert `attachment_id`, `filename`, `content_type`, `size` und `content_url` und gibt keine Dateibytes zurück, wenn `include_content` fehlt oder `false` ist. `size` ist die Anhangs-`filesize`. Ist „Hostname und Pfad“ leer, ist `content_url` `null`. Mit `include_content: true` zusätzlich `content_base64`; `size` ist die tatsächliche Inhaltsgröße in Bytes. Unbekanntes MIME — `application/octet-stream`. Erhöht den `downloads`-Zähler nicht. Das 10-MiB-Limit (Prüfung von `File.size` auf der Platte vor dem Lesen und `bytesize` danach) gilt nur bei `include_content: true`; bei Überschreitung — `FILE_TOO_LARGE`. Keine Server-Dateisystempfade in der Antwort. `attachment_id` aus `redmine_get_issue` / `redmine_get_wiki_page` mit `include_attachments=true` oder `redmine_list_project_files`. Zum Lesen oder Verarbeiten `include_content: true` setzen und `content_base64` lokal dekodieren. Nicht vorhandene und unzugängliche Anhänge — gleiche Antwort „nicht gefunden“.
- `create_time_entry` erfordert `hours` und entweder `project` oder `issue_id`. `hours` darf 0 sein; Gültigkeit von Null und Tagesmaximum prüft Redmine (`timelog_accept_0_hours`, `timelog_max_hours_per_day`).
- `assigned_to_id` bei Issue-Erstellung/-Aktualisierung ist eine Prinzipal-ID (Benutzer oder Gruppe aus `get_issue_form_options.assignees`); `null` löscht den Beauftragten. Für `add_issue_watcher` / `remove_issue_watcher` sind `issue_id` und `principal_id` (Benutzer oder Gruppe) erforderlich; die Antwort enthält `issue_id` und `principal_id`. In anderen Tools ist `user_id` eine Benutzer-ID. Verwenden Sie für den aktuellen Benutzer `assignee_ref` oder `user_ref` mit dem Wert `me`.
- `expected_updated_at` (optional) bei sensibler Aktualisierung/Löschung: Wenn es nicht mit `updated_on` übereinstimmt, wird `CONFLICT` zurückgegeben.
- `idempotency_key` (optional) bei `create_issue`, `copy_issue`, `update_issue`, `add_issue_note`, `create_time_entry`, `upload_file`: Wiederholung mit demselben Schlüssel und **demselben Argumentensatz** (außer dem Schlüssel selbst) liefert das gecachte erfolgreiche Ergebnis (TTL 24 h). Derselbe Schlüssel mit anderem Payload — `CONFLICT`, kein doppelter Schreibvorgang. Solange die erste Anfrage noch läuft, führt eine Wiederholung mit demselben Schlüssel keinen weiteren Schreibvorgang aus (der Marker „in progress“ lebt dieselben 24 h wie ein erfolgreiches Ergebnis). Ein Cache-Eintrag ohne Fingerprint (Cache vor dieser Version) mit demselben Schlüssel wird wie zuvor bis zum Ablauf der TTL zurückgegeben. Server-Timeout 60 s gilt für **Lese**vorgänge. Schreibvorgänge werden nicht durch Server-Timeout abgebrochen, damit nach erfolgreichem Speichern das Idempotenz-Ergebnis geschrieben werden kann; der Client kann mit demselben Schlüssel wiederholen, wenn er die Verbindung verloren hat.
- `delete_attachment` löscht standardmäßig nur Projekt-/Versionsdateien; für Issue-/Wiki-Anhänge ist `confirm_delete_any_attachment=true` erforderlich. Vollständiger Tool-Name — `redmine_delete_attachment`. Frühere Namen (`delete_file`, `redmine_delete_file`) sind nicht registriert.
- Liste/Suche verwenden `limit`/`offset`. Bei DB-Abfragen wird die Seite auf Abfrageebene eingeschränkt, nicht durch Beschneiden einer bereits geladenen vollständigen Liste. Jede paginierte MCP-Sammlung hat eine explizite stabile Reihenfolge; Das letzte Kriterium ist immer `id`, damit Seiten keine Elemente überspringen oder duplizieren.
- Die Teilzeichenfolgensuche (`query`, `login`, `name` und der Text `search_issues`) entspricht den Zeichen wörtlich: `%` und `_` sind keine SQL-Platzhalter.
- MCP-Grenzwerte: Timeout 60 s bei Lesetools, Ratenlimit 120 Anfragen/Minute pro Benutzer, MCP-Anfrage-HTTP-Körper 36 MiB, maximale Größe der JSON-Tool-Argumente 32 MiB, Base64-Upload bis zu 20 MiB, Base64-Download bis zu 10 MiB. Beschädigtes Base64 in jedem `content_base64` ist ein Parameterfehler vor der Ausführung des Tools.
- Jeder Tool-Aufruf, einschließlich Zugriffsverweigerung, wird in ein strukturiertes Audit-Protokoll geschrieben (Tool, Benutzer, Ziel-IDs, Ergebnis, Dauer, Korrelations-ID) und auf das Ratenlimit angerechnet; Base64-Inhalte und private Notizen werden nicht protokolliert. Zu den Ziel-IDs gehören unter anderem `board_id`, `message_id`, `query_id`, `user_id`, `group_id`.
- Das `outputSchema` jedes Core-Tools beschreibt die oberste Ebene von `data` (bei Listen — Felder der `items`-Elemente), nicht ein offenes beliebiges Objekt. Die Feldmenge des Schemas entspricht der tatsächlichen Antwort: `list_users` mit `project` ohne `created_on` in Elementen; globaler `list_users` des Administrators ohne `project` enthält `created_on`; `get_attachment` enthält `size`, `content_url` und optionales `content_base64`. Felder, die in der realen Antwort leer sein können, erlauben `null` (einschließlich `time_entry.issue`, `*_pagination` ohne include, `estimation_accuracy`, `content_type` des Anhangs). Werte benutzerdefinierter Felder und `possible_values` sind nicht auf Objekte beschränkt. `attachments_not_saved` — Array von Dateinamen.
- `summarize_project_status.days` im Schema: Standard 30, Minimum 1, Maximum 365.
- `search_all.resources`: höchstens zwei eindeutige Werte.
- `version_id`, `file_id`, `tracker_id` sind Ganzzahlen nicht kleiner als 1.

### `get_project`

- Eingabe: `project` (erforderlich); optional `include_modules` (boolean).
- Ausgabe: `id`, `name`, `identifier`, `description`, `homepage`, `status`, `is_public`, `inherit_members`, `created_on`, `updated_on`, `parent` (Objekt `id`/`name`/`identifier` oder `null`), `subprojects` (kurze Liste sichtbarer Unterprojekte: `id`/`name`/`identifier`), `custom_fields`, `last_activity_date`. Bei `include_modules: true` zusätzlich `enabled_modules` — Array der Namen aktivierter Module.
- `parent` wird nur ausgefüllt, wenn das übergeordnete Projekt für den aktuellen Benutzer sichtbar ist; andernfalls `null`.
- Gibt keine Mitglieder und keine Issue-Statistiken zurück. Für Mitglieder — `list_project_members`; für Issue-Aggregate — `summarize_project_status`.

### `get_issue_form_options`

- Ein Aufruf statt mehrerer Referenzsuchen vor dem Erstellen/Aktualisieren. Separate `list_trackers` (optional `project`), `list_issue_statuses`, `list_issue_priorities`, `list_issue_categories`, `list_versions`, `list_users`, `list_project_issue_custom_fields` bleiben verfügbar.
- Eingabe: `project` (erforderlich); optional `tracker_id`, `issue_id`.
- Der Snapshot spiegelt das **Problemformular für den aktuellen Benutzer** wider, nicht die vollständige Projektkonfiguration: dieselben zulässigen Werte, die die Redmine-Benutzeroberfläche bietet.
- `tracker_id` ohne `issue_id` legt den Kontext zum Erstellen des Formulars fest. Der Tracker muss für den aktuellen Benutzer zur Auswahl im Formular verfügbar sein; andernfalls – Parameterfehler.
- `issue_id` legt das Formular für ein vorhandenes sichtbares Problem in diesem Projekt fest. Bei `issue_id` ist `tracker_id` nur zulässig, wenn sie mit dem aktuellen Tracker des Problems übereinstimmt; andernfalls – Parameterfehler (Tracker-Änderung wird nicht durch dieses Tool modelliert).
- Ausgabe – Formular-Snapshot ohne Paginierung:
- `project`: `id`, `name`, `identifier`;
- `trackers`: Tracker, die der aktuelle Benutzer in diesem Formular auswählen kann (`id`, `name`), nicht alle Tracker sind für das Projekt aktiviert;
- `priorities`: aktive Prioritäten (`id`, `name`, `is_default`);
- `categories`: Projektkategorien (`id`, `name`);
- `versions`: Versionen, die in diesem Formular zur Auswahl stehen (`id`, `name`, `status`, `due_date`);
- `assignees`: Auftraggeber, die in diesem Formularkontext zugewiesen werden können. Element: `id`, `name`, `type` (`user` oder `group`); für `user` zusätzlich `login`. Gruppen sind enthalten, wenn Redmine die Problemzuweisung zu Gruppen aktiviert hat;
- `custom_fields`: Nur Felder, die der aktuelle Benutzer im Formular bearbeiten kann, unter Berücksichtigung von Projekt/Tracker, Sichtbarkeit und schreibgeschütztem Workflow. Element: `id`, `name`, `field_format`, `required` (Feld erforderlich oder vom Workflow erforderlich), `readonly` (in dieser Liste immer `false`), `multiple`, `default_value`, `possible_values`, `trackers`. Formularkontext – Ausgabe von `issue_id` oder Erstellen eines Entwurfs unter Berücksichtigung von `tracker_id`;
- `possible_values` — Array von Objekten `{ "label": "...", "value": "..." }`. Bei Listen ohne separate Beschriftung stimmt `label` mit `value` überein. Für Benutzer/Version/Aufzählung ist `label` der Anzeigename, `value` die Kennung;
- `statuses`: vom Workflow für den aktuellen Benutzer zulässige Status. Mit `issue_id` – Übergänge für dieses sichtbare Problem. Ohne `issue_id` – Anfangsstatus für die Erstellung (unter Berücksichtigung von `tracker_id`, falls festgelegt);
- `editable_fields`: Attributnamen, die dieser MCP-Vertrag beim Erstellen/Aktualisieren akzeptiert und die der aktuelle Benutzer im Formular festlegen kann, sowie bearbeitbare benutzerdefinierte Feld-IDs als Zeichenfolgen. Enthält nicht `notes`, `private_notes`, `watcher_user_ids` und andere Webformularfelder, die in den MCP-Schreibtools fehlen;
- `required_fields`: Feldnamen, die in diesem Formular für den aktuellen Benutzer erforderlich sind, im gleichen Namensformat wie `editable_fields`.
- Nicht vorhandene `tracker_id`, Tracker für den Benutzer nicht zulässig oder `issue_id` außerhalb des Projekts / nicht sichtbar – Parameterfehler.

### `add_issue_note`

- Fügt einen Kommentar zu einem vorhandenen sichtbaren Problem hinzu, ohne die Problemattribute zu ändern.
- Eingabe: `issue_id` (erforderlich), `notes` (erforderlich), optional `private_notes`, `uploads` und `idempotency_key`.
- Berechtigung: Der Benutzer kann Kommentare zu diesem Problem hinzufügen. `private_notes=true` erfordert die Erlaubnis, private Kommentare abzugeben; andernfalls – abgelehnt, es wird kein Kommentar erstellt. Anhänge im selben Anruf sind zulässig, wenn der Benutzer dem Problem Anhänge hinzufügen kann.
- Akzeptiert keine Issue-Felder oder Watcher-Listen.
- Ausgabe: `issue_id`, `journal_id`, `notes`, `private_notes`; mit `uploads` – `added_attachments` (nur Dateien aus diesem Aufruf).
- Im schreibgeschützten Modus nicht verfügbar.

### `update_issue_note`

- Arbeitet nur mit einem Journaleintrag, den der aktuelle Benutzer **sieht** (private Kommentare anderer ohne Berechtigung zum Anzeigen privater Notizen sind nicht zugänglich).
- Der Eintrag muss für den aktuellen Benutzer bearbeitbar sein (Berechtigung zum Bearbeiten von Kommentaren oder eigener Kommentare).
- Eingabe: `journal_id` (erforderlich); mindestens eines von `notes` oder `private_notes` ist erforderlich.
- `notes` darf leer sein (Text eines vorhandenen Eintrags löschen). Neuer Kommentar über `add_issue_note` darf nicht leer sein.
- Änderung der Privatsphäre (`private_notes`) erfordert gesonderte Berechtigung; andernfalls Abbruch ohne teilweise Textänderung.
- Ausgabe — Journalobjekt (`JOURNAL`), wie bei Textbearbeitung.
- Speichert, wer den Journaleintrag bearbeitet hat.
- Im schreibgeschützten Modus nicht verfügbar.

### `list_trackers`

- Ohne `project`: alle Tracker der Redmine-Instanz (`id`, `name`, `description`).
- Mit `project`: nur für das sichtbare Projekt aktivierte Tracker; `description` ist leerer String für einheitliches Antwortschema.
- Ein fehlendes oder unsichtbares `project` liefert `NOT_FOUND`, nicht `FORBIDDEN`.

### `list_issues` — erweiterte Filter

- Vorhandene flache Filter (`project`, `status_id`, `tracker_id`, `assigned_to_id` / `assignee_ref`, `priority_id`, `fixed_version_id`, `sort`, `fields`) bleiben erhalten.
- Optionale `filters`: Array von Objekten `{ "field": "...", "operator": "...", "values": ["..."] }`. `values` ist ein Array von Strings; Für Operatoren ohne Werte ist ein leeres Array zulässig.
- Erlaubte `field`: `status_id`, `tracker_id`, `assigned_to_id`, `priority_id`, `fixed_version_id`, `category_id`, `parent_id`, `subject`, `due_date`, `start_date`, `created_on`, `updated_on`, `estimated_hours`, `done_ratio`, `author_id`, `watcher_id` und `cf_<id>` für benutzerdefinierte Problemfelder.
- Operatoren sind standardmäßige Redmine-Abfrageoperatoren, einschließlich `=`, `!`, `>=`, `<=`, `><`, `~`, `!~`, `o`, `c`, `*`, `!*`. Der Operator muss für den Feldtyp gültig sein; andernfalls – Parameterfehler.
- Unbekanntes `field` oder ungültiger `operator` – Parameterfehler, Abfrage wird nicht ausgeführt.
- Flache Filter und `filters` werden mit UND verknüpft.
- Filter gelten nur für Probleme, die für den aktuellen Benutzer sichtbar sind.
- Direkte Unteraufgaben: `filters` mit `field` `parent_id`, `operator` `=`, ein oder mehrere Werte — Parent-Issue-ID(s). Mehrere IDs in einer Zeichenkette durch Komma getrennt (Redmine-Stil: `"123,456"`), oder mehrere `values`-Elemente, die MCP vor der Abfrage zu einer Zeichenkette zusammenführt. Jeder genannte Parent muss für den Benutzer sichtbar sein; sonst Fehler „Issue nicht gefunden“ (wie `get_issue`). Separates Tool `list_subtasks` entfernt.


### `list_project_activities`

- Dies ist der Projekt-Ereignisfeed („was passiert ist“), nicht der Katalog der Arbeitsaktivitätstypen für die Zeiterfassung. Arbeitsaktivitätstypen — `list_time_entry_activities`.
- Eingabe: `project` (erforderlich); optional `from`, `to` (Daten `YYYY-MM-DD`), `author_id`, `event_types` (Array von Zeichenfolgen), `limit`/`offset`.
- Standardfenster – letzte 7 Tage (`to` = heute, `from` = heute minus 6 Tage). Maximale Fensterlänge – 90 Tage; bei Überschreitung: Parameterfehler.
- Ereignisse aus dem Projektaktivitäts-Feed: Typ, Zeit, Autor (`id`/`name`), `title`, `description`, `url`. Reihenfolge – neuere Ereignisse zuerst; für gleiche Zeit – höhere `id` zuerst.
- Umschlag wie andere `list_*`.
- `event_types` begrenzt Ereignistypen. Ein für den Benutzer nicht verfügbarer oder im Projekt deaktivierter Typ wird (ohne Fehler) von der Auswahl ausgeschlossen.
- Nicht vorhandene `author_id` – leere Liste, kein Fehler.

### `summarize_project_status`

Dies ist kein Redmine-Objekt, sondern eine serverseitige Aggregation über sichtbare Projekt-Issues und Zeiteinträge.

Vorhandene Felder bleiben erhalten: `project_id`, `project_name`, `analysis_period_days`, `recent_activity` (`created_count`, `updated_count`), `totals` (`issues_count`, `open_count`, `closed_count`), `status_breakdown`, `priority_breakdown`, `assignee_breakdown`.

Das Fenster `days` (Standard 30, Bereich 1–365) wirkt sich weiterhin auf `recent_activity` und die unten aufgeführten Zeitraummetriken aus. Ein Wert außerhalb des Bereichs wird vom Schema abgelehnt. `totals` und Aufschlüsselungen werden über alle sichtbaren Projektprobleme ohne Datumsfilter über DB-Aggregation berechnet, ohne dass alle Probleme in den Speicher geladen werden. Teilprojekte sind nicht enthalten.

Zusätzliche Felder:

- `overdue_count` – Anzahl der offenen sichtbaren Probleme mit `due_date` genau vor dem heutigen Tag des Benutzers.
- `unassigned_count` – Anzahl der offenen sichtbaren Probleme ohne Beauftragten.
- `stale_issues_count` – Anzahl der offenen sichtbaren Probleme, deren `updated_on` älter als der Beginn des `days`-Fensters ist.
- `issues_closed_during_period` – Anzahl der sichtbaren Probleme mit `closed_on` innerhalb des `days`-Fensters.
- `estimated_hours` – Summe der Schätzungen sichtbarer Projektprobleme (`null`, wenn keine Schätzung vorhanden ist, andernfalls eine Zahl einschließlich 0).
- `spent_hours` – Summe der Zeit, die für sichtbare Projektprobleme aufgewendet wurde (0, wenn keine Einträge vorhanden sind). Erfordert `view_time_entries` für das Projekt; Ohne Erlaubnis ist das Feld `null`.
- `average_resolution_hours` – Durchschnitt `(closed_on - created_on)` in Stunden für Probleme, die im Fenster `days` geschlossen wurden; `null`, wenn keine derartigen Probleme vorliegen.
- `estimation_accuracy` — für im Fenster geschlossene Probleme, die sowohl eine Schätzung als auch eine ungleich Null/protokollierte Zeit haben: `{ "issues_count", "total_estimated", "total_spent" }`. Wenn keine passenden Probleme vorliegen — `{ "issues_count": 0, "total_estimated": 0, "total_spent": 0 }`. Erfordert `view_time_entries` für das Projekt; ohne Erlaubnis ist das Feld `null`.
- `reopened_count` – Anzahl der sichtbaren Ausgaben, deren Journalstatus sich innerhalb des `days`-Fensters von „geschlossen“ zu „offen“ geändert hat. Jede Ausgabe wird höchstens einmal gezählt.

Das Tool liefert Fakten, keine textliche „Projektgesundheitsanalyse“.

### `list_versions` / `get_version`

`Version` in diesen Tools ist eine Redmine-Entität (Roadmap-Stufe / Meilenstein), nicht eine Softwareproduktversion. `list_versions` gibt Roadmap-Versionen des Projekts zurück, einschließlich freigegebener.

### `get_version`

- Eingabe: `version_id` (erforderlich); optional `project`. Wenn `project` festgelegt ist, ist die Version zugänglich, wenn sie sich in den freigegebenen Versionen dieses sichtbaren Projekts befindet (auch wenn das Quellprojekt der Version für den Benutzer nicht sichtbar ist). Ohne `project` muss die Version in ihrem Quellprojekt sichtbar sein.
- Ausgabe: Felder wie ein `list_versions`-Element (`id`, `name`, `description`, `status`, `due_date`, `sharing`, `wiki_page_title`, `project`, `created_on`, `updated_on`) plus Aggregate: `issues_count`, `open_issues_count`, `closed_issues_count`, `estimated_hours`, `spent_hours`, `completed_percent`.
- Aggregate werden nur für Versionsprobleme berechnet, die für den aktuellen Benutzer sichtbar sind.
- Die Vorgangsliste wird nicht zurückgegeben.
- `spent_hours` erfordert `view_time_entries` für das Projekt der Version; ohne Erlaubnis – `null`. Summieren Sie nur sichtbare Versionsprobleme und nur Zeiteinträge, die der aktuelle Benutzer sehen kann (einschließlich `time_entries_visibility=own`).

### Repository / SCM

- Das Repository-Modul des Projekts muss aktiviert sein; andernfalls Fehler „Repository-Modul ist für dieses Projekt nicht aktiviert“.
- `list_repositories` / `get_repository`: Berechtigung `view_changesets` **oder** `browse_repository`. Ohne `repository_id` wird das Repository nach Redmine-Regel gewählt: `project.repository || project.repositories.first`.
- `list_revisions` / `get_revision`: Berechtigung `view_changesets`. Die Liste basiert auf gecachten Changesets (`Changeset.visible`); frische Commits ohne Fetch können fehlen.
- `get_revision`: Lookup über `repository.find_changeset_by_name` nach Revisionsnummer oder Prefix-Hash; akzeptiert **keine** Branch/Tag (für SCM-Refs — `get_repository_file` / `get_repository_diff`); verknüpfte Issues — nur `Issue.visible`; `file_changes` — nur mit `:browse_repository`.
- `get_repository`: Metadaten (`id`, `scm_type`, `name`, …) werden auch zurückgegeben, wenn `default_branch` aus dem SCM nicht verfügbar ist; in diesem Fall ist `default_branch` `null`.
- `get_repository_file` / `get_repository_diff`: Berechtigung `browse_repository`. Ohne `repository_id` wird das Standard-Repository des Projekts verwendet. Standard-Revision ist `default_branch`; der Parameter kann Branch/Tag/Hash sein (SCM-Adapter). SCM-Fehler beim Auflösen der Standard-Revision (weggelassene `revision`) — `REDMINE_API_ERROR`.
- `get_repository_file`: Verzeichnis — paginierte `entries`; Textdatei — inline `content`; Binärdatei — Metadaten, optional `content_base64` (separates Feld). Die Binärheit wird am Inhalt bestimmt: ungültiges UTF-8, Nullbyte oder hoher Anteil von Steuerbytes. Eine Texterweiterung überschreibt dieses Ergebnis nicht. Größe begrenzt durch `min(Setting.file_max_size_displayed, MCP cap 10 MiB)`.
- `get_repository_diff`: Unified Diff mit Truncation nach `min(Setting.diff_max_lines_displayed, MCP line cap)` und MCP-Byte-Cap (512 KiB).
- Fehlendes Repository/Revision/Pfad — `NOT_FOUND`; SCM-Adapter-Fehler — `REDMINE_API_ERROR`, nicht `NOT_FOUND` und nicht `INTERNAL_ERROR`.
- Alle Repository-Tools sind in `tools/list` sichtbar, wenn der Benutzer mindestens ein Projekt sehen kann. Sichtbarkeit in der Liste bedeutet kein Aufrufrecht: ein Aufruf ohne erforderliche Berechtigung gibt `FORBIDDEN` zurück und versteckt das Tool nicht. Der Repository-Modulstatus wird beim Aufruf nach der Berechtigungsprüfung geprüft: ohne Berechtigung — `FORBIDDEN` (auch bei deaktiviertem Modul); mit Berechtigung und deaktiviertem Modul — `INVALID_STATE`.
- Es werden nicht zurückgegeben: `url`, `root_url`, `login`, `password`, `extra_info`.

### Foren

- Das Modul Projektforen muss aktiviert sein; andernfalls Fehler „Boards-Modul ist für dieses Projekt nicht aktiviert“ (Wiki-Analogon).
- Berechtigung `view_messages`. Keine Forum-Schreibvorgänge.
- `list_boards`: `project` erforderlich; Pagination. Element: `id`, `name`, `description`, `parent_id` (`null` für Root-Board), `topics_count`, `messages_count`.
- `list_board_topics`: `board_id` erforderlich; Pagination. Nur Stammnachrichten (kein übergeordnetes Element). Element: `id`, `subject`, `author`, `created_on`, `updated_on`, `replies_count`, `board_id`.
- `get_board_message`: `message_id` erforderlich. Ausgabe: `id`, `subject`, `content`, `author`, `created_on`, `updated_on`, `board` (`id`/`name`), `project` (`id`/`name`/`identifier`), `parent_id`, `replies` – kurze Antwortliste (`id`, `subject`, `author`, `created_on`) ohne vollständigen Text von jede Antwort, mit `replies_limit`/`replies_offset` (Standard und maximal 100) und `replies_pagination`.
- Unsichtbares Board/Nachricht oder Board aus einem anderen Projekt – Fehler „nicht gefunden“.

### `list_users`

- Mit `project`: aktive **Benutzer**-Projektmitglieder (Berechtigung `view_members`). Gruppen-Membership im Projekt erscheint nicht als Gruppe; Benutzer aus einer Gruppe nur, wenn sie selbst Mitglieder sind. Ohne `project` — nur Administrator.
- Element mit `project`: `id`, `login`, `firstname`, `lastname`, `mail` (ohne `created_on`). Die globale Administratorliste ohne `project` enthält zusätzlich `created_on`.
- Optionale `query`: registrierungsunabhängiger Substring über `login`, `firstname` und `lastname`.
- Optionales `login` bleibt erhalten (nur Substring über login) aus Kompatibilitätsgründen. Sind sowohl `query` als auch `login` gesetzt, gelten beide Bedingungen (AND).
- Optionale `name` und `group_id` — nur Administrator ohne `project`. `name` — Substring via `User.like` (login, firstname, lastname, email). `group_id` — Benutzer der Gruppe. `name` und `group_id` kombinierbar; mit `query`/`login` Bedingungen per AND. Mit `project` oder für Nicht-Administrator — Parameterfehler oder Zugriff verweigert.

### `list_project_files`

- Paginierte Liste der Dateien aus dem Projektabschnitt „Dateien“ und Anhänge seiner Versionen. Enthält keine Issue- oder Wiki-Anhänge — diese lesen Sie über `get_issue` / `get_wiki_page` mit `include_attachments`.
- Eingabe: `project` (erforderlich), Paginierung. Berechtigung `view_files`.
- Vollständiger Tool-Name — `redmine_list_project_files`. Der frühere Name `list_files` ist nicht registriert.

### `list_groups`

- Paginierte Liste der vergebbaren Gruppen (`id`, `name`), **sichtbar** für den aktuellen Benutzer, zur Auswahl von `group_id` in `add_project_member`.
- Optionale `query`: Teilzeichenfolge ohne Berücksichtigung der Groß-/Kleinschreibung für den Gruppennamen; `%` und `_` werden wörtlich abgeglichen.
- Berechtigung: Administrator oder `manage_members` für mindestens ein sichtbares Projekt.
- Gruppenmitgliedschaften oder Mitgliedschaften werden nicht zurückgegeben.

### `list_project_member_candidates`

- Kandidaten für das Hinzufügen zum Projekt: aktive sichtbare Benutzer und Gruppen, die noch nicht im Projekt sind.
- Eingabe: `project` (erforderlich); optional `query` (Teilzeichenfolge, wie in der Redmine-Mitgliederauswahl).
- Umschlag der Ausgabeliste: `id`, `name`, `type` (`user` oder `group`); für Benutzer zusätzlich `login`.
- Berechtigung `manage_members` für das Projekt.
- `add_project_member`: `user_id` nur für Benutzer, `group_id` nur für Gruppen. ID vom falschen Typ – Parameterfehler. Übernehmen Sie vor dem Hinzufügen die IDs aus diesem Tool (oder aus `list_users` / `list_groups`, wenn der Kandidat bereits bekannt ist).

### `list_roles`

- Nur Rollen, die der aktuelle Benutzer im angegebenen Projekt verwalten kann.
- Eingabe: `project` (erforderlich).
- Berechtigung `manage_members` für das Projekt.
- Für Administratoren entspricht das Set den zuweisbaren Projektrollen (ohne Nichtmitglied/Anonym).

## Randfälle

- Nicht vorhandenes/nicht zugängliches Projekt oder Vorgang — `{ "error": "..." }`.
- Schreibgeschützter Modus — `{ "error": "MCP is in read-only mode..." }` für Schreibtools **bevor** der Handler aufgerufen wird, einschließlich Erweiterungs-API-Tools; Formularoptionen/Liste/Get bleiben verfügbar.
- Leere Liste/Suchergebnis – `{ "ok": true, "data": { "items": [] }, "meta": { ... } }`.
- Liste/Suche mit Paginierung gibt immer `data.items` und `meta` zurück (`total_count`, `limit`, `offset`, `has_more`, `next_offset`). Standardlimit 25, maximal 100.
- Alle `list_*`-Tools (einschließlich Referenzen: Tracker, Status, Rollen, Abfragen, Boards, Board-Themen usw.) verwenden denselben Umschlag. `get_issue_form_options`, `get_project`, `get_version`, `get_board_message`, `summarize_project_status` — einzelne Objekte, kein Listenumschlag.
- `get_attachment`: nicht vorhandener und nicht zugänglicher Anhang — gleicher „not found“-Fehler; bei `include_content: true` Datei auf der Platte nicht lesbar — Fehler; Größe auf der Platte oder nach dem Lesen über 10 MiB — `FILE_TOO_LARGE` (Limit nicht durch niedrigere DB-`filesize` umgehbar); reine Metadaten-Anfragen unterliegen keinem Größenlimit.
- `list_project_activities`: Fenster länger als 90 Tage – Parameterfehler; `from` nach `to` – Parameterfehler.
- `list_issues` mit `query_id`: unsichtbare Abfrage — wie nicht vorhanden behandelt; `query_id` zusammen mit zusätzlichen Filtern — Parameterfehler.
- `get_issue_form_options` mit `issue_id` für ein Problem aus einem anderen Projekt – Parameterfehler.
- `get_issue_form_options` mit `issue_id` und `tracker_id`, die nicht mit dem Tracker dieses Problems übereinstimmen – Parameterfehler.
- Schreibvorgänge über MCP laufen über Redmine-Modelle. Model-Callbacks werden ausgeführt; Controller-Hooks der Web-Oberfläche werden nicht aufgerufen.

## Fehlerbehandlung

- Fehlende Berechtigung — Tool nicht in `tools/list` sichtbar oder „Permission denied“.
- Modellvalidierungsfehler — `{ "error": "<messages>" }` (für Issue create/update zusätzlich `missing_required_fields` als Feldnamen aus Modellfehlersymbolen, ohne Übersetzungstext zu analysieren, und `hint`).
- Wiki/Boards-Modul deaktiviert – separate Fehlermeldung, nicht „nicht gefunden“.
- Der kanonische Fehlercode im Umschlag wird explizit vom Handler festgelegt. Der Code wird nicht vom Nachrichtentext abgeleitet und ist nicht von der Benutzersprache abhängig.

## Testszenarien

1. `list_projects` / `list_issues` Rückgabeumschlag `data.items` + `meta` mit Paginierung.
2. `get_issue` ohne `include_*` gibt keine Zeitschriften/Anhänge zurück; mit `include_journals` – Zeitschriften mit Paginierung.
3. `search_issues` nach Text findet Probleme; `search_all` schließt Wiki ein, wenn mehrere Typen durchsucht werden.
4. `create_issue` / `update_issue` mit gültigen Feldern ist erfolgreich; ohne Erlaubnis oder im schreibgeschützten Zustand – Fehler.
4a. `create_issue` ohne `start_date` mit aktivierter Startdatumseinstellung legt das heutige Datum fest; explizites `start_date` oder `null` wird durch diese Einstellung nicht überschrieben.
5. `delete_issue` ohne `confirm_delete` gibt `INVALID_STATE` und Auswirkungen zurück; mit Bestätigung löscht.
6. `create_time_entry` requires `hours` and `project` or `issue_id`.
7. `list_wiki_pages` / `get_wiki_page` / `create_wiki_page` funktionieren mit aktiviertem Wiki-Modul.
8. `upload_file` erfordert `filename` und `content_base64`; `delete_attachment` für den Problemanhang erfordert eine Bestätigung.
9. Benutzer ohne `use_mcp` bestehen die MCP-Authentifizierung nicht; Ohne Tool-Berechtigung wird es nicht in `tools/list` angezeigt.
10. Wenn Sie `create_issue` mit demselben `idempotency_key` und denselben Argumenten erneut versuchen, wird kein Duplikat erstellt. Gleicher Schlüssel mit unterschiedlichem Betreff – `CONFLICT`.
11. `get_attachment` mit `include_content: true` für sichtbare Issue-Anhänge liefert `content_base64` und `content_url` mit tatsächlicher Inhalts-`size`; Datei > 10 MiB auf der Platte (auch bei kleinen Metadaten) — `FILE_TOO_LARGE`; ohne `include_content` nur Metadaten bei großen Dateien; nicht vorhandene und unzugängliche Anhänge nicht unterscheidbar; `redmine_download_attachment` fehlt in `tools/list`.
12. `get_project` nach Kennung gibt Beschreibung, Unterprojekte und `last_activity_date` zurück; unzugängliches Projekt – Fehler.
13. `get_issue_form_options` für Projektrückgabe-Tracker/Status/Prioritäten/Kategorien/Versionen/Assignees/Custom_fields und `editable_fields`/`required_fields`-Listen; `trackers` – nur diejenigen, die dem aktuellen Benutzer zur Verfügung stehen; mit `issue_id` spiegeln Status zulässige Übergänge für dieses Problem wider; `issue_id` + andere `tracker_id` – Fehler; `possible_values` – `label`-/`value`-Objekte.
14. `create_issue` mit ungültigem Tracker oder Status gibt einen Fehler zurück und erstellt kein Issue.
15. `list_issues` mit `filters` (`due_date` `<=` Datum, `priority_id` `!`, `parent_id` `=` für Unteraufgaben) gibt nur passende sichtbare Issues zurück; unbekanntes `field` — Fehler; `parent_id` `=` bei nicht sichtbarem Parent (einschließlich jedes IDs in einer kommagetrennten Liste) — Fehler „Issue nicht gefunden“.
16. `list_issues` mit sichtbarem `query_id` liefert dieselben Vorgänge wie die gespeicherte Abfrage in der UI; unsichtbare Abfrage — Fehler; `query_id` mit `filters` — Parameterfehler.
17. `list_project_activities` für 3 Tage gibt Projektereignisse mit Paginierung zurück; 91-Tage-Fenster – Fehler.
18. `summarize_project_status` enthält `overdue_count`, `unassigned_count`, `stale_issues_count`, `issues_closed_during_period` und `reopened_count`.
19. `get_version` gibt die Aggregate `open_issues_count` / `completed_percent` ohne Problemliste zurück.
20. `list_boards` / `list_board_topics` / `get_board_message` funktionieren mit aktiviertem Boards-Modul; wenn deaktiviert – Modulfehler.
21. `list_users` mit `project` und `query` nach Namen findet Mitglied, ohne die Anmeldung zu kennen.
22. `get_issue_form_options` gibt Beauftragte mit `type` Benutzer/Gruppe und nur bearbeitbare benutzerdefinierte Felder mit `required`/`readonly` zurück.
23. `create_issue` / `update_issue` / `copy_issue` mit explizit übergebenem Wert, den Redmine nicht anwendet (einschließlich deaktivierter/schreibgeschützter Kernfelder, einschließlich `description` beim Erstellen), geben einen Fehler zurück und speichern keine Teiländerung.
24. `add_issue_note` mit `add_issue_notes` gelingt ohne `edit_issues`; `private_notes` ohne `set_notes_private` – abgelehnt. `update_issue` mit nur `uploads` ist mit der Berechtigung zum Hinzufügen von Anhängen ohne `edit_issues` erfolgreich.
25. `list_groups` gibt vergebbare Gruppen für Benutzer mit `manage_members` zurück.
26. `update_issue` mit `assigned_to_id`/`category_id`/`fixed_version_id`/`parent_issue_id`/`start_date`/`due_date`/`estimated_hours` = `null` löscht das Feld, wenn es beschreibbar ist.
27. `update_issue_note` ändert fremde private Kommentare nicht ohne Berechtigung zum Anzeigen privater Kommentare.
28. Benutzer mit der Berechtigung, Kommentare zu bearbeiten, aber nicht privat zu machen, können den öffentlichen Kommentartext ändern und die Datenschutzmarkierung nicht ändern.
29. `add_issue_note` mit `uploads` erstellt Kommentar und Anhang in einem Aufruf; Bei einem erneuten Versuch mit demselben `idempotency_key` werden sie nicht dupliziert.
30. `update_issue` mit `uploads` und `idempotency_key`: Bei einem erneuten Versuch mit derselben Nutzlast wird der Anhang nicht dupliziert. andere Datei mit demselben Schlüssel – `CONFLICT`. Beschädigtes Base64 – Parameterfehler.
31. `get_issue` gibt keine versteckten benutzerdefinierten Felder, unsichtbaren Journaldetails oder Beziehungen zu unsichtbaren Problemen zurück. `get_version` aggregiert nur über sichtbare Probleme.
32. `copy_issue` ohne Berechtigung zum Kopieren im Quellprojekt – verweigert, auch mit `add_issues` im Ziel.
33. `add_project_member` / `update_project_member` mit einer Rolle, die der Benutzer nicht verwalten kann – ohne teilweise Zuweisung abgelehnt.
34. `create_version` / `update_version` mit `sharing` für Benutzer nicht zulässig – abgelehnt. `delete_version` für ausgelastete Version – ohne Löschung abgelehnt.
35. Der Autor von Zeiteinträgen mit `edit_own_time_entries` kann seinen eigenen Eintrag über `update_time_entry` aktualisieren.
36. `search_all` steht Benutzern mit Wiki-Berechtigung ohne `view_issues` zur Verfügung, wenn die Suche Wiki umfasst.
37. `list_project_member_candidates` gibt Benutzer und Gruppen zurück, die noch nicht im Projekt sind; `add_project_member` mit der Gruppe `user_id` – Fehler.
38. `list_roles` für Projekte gibt nur Rollen zurück, die der Benutzer verwalten kann; ohne `project` – Schemafehler. Enthält nicht die integrierten Funktionen „Nicht-Mitglied“ und „Anonym“.
39. Wiederholen Sie `copy_issue` / `create_time_entry` mit demselben `idempotency_key`. Es wird kein Duplikat erstellt. unterschiedliche Nutzlast mit demselben Schlüssel – `CONFLICT`.
40. `search_issues` und Benutzer-/Gruppensuche nach `%` oder `_` entsprechen diesen Zeichen wörtlich, nicht als Platzhalter.
41. `get_version.spent_hours` mit `time_entries_visibility=own` zählt nur eigene Zeiteinträge.
42. `search_issues` mit `scope=subprojects` ohne `project` – Fehler; mit `project` findet Probleme in Nachkommen.
43. `list_project_activities` gibt neuere Ereignisse vor älteren zurück.
44. Die Auswirkung von `delete_issue` umfasst keine versteckten Journale, Beziehungen und Zeiteinträge anderer; Versteckte Unteraufgaben erfordern weiterhin `confirm_delete_with_children`.
45. `get_project` gibt kein übergeordnetes Element zurück, das für den aktuellen Benutzer unsichtbar ist.
46. `update_version` mit `due_date`/`wiki_page_title` = `null` löscht das Feld.
47. `update_issue_category` mit `assigned_to_id` = `null` löscht den Standardbeauftragten.
48. Schema akzeptiert `hours` von 0 und Werte über 24; nur die Redmine-Validierung lehnt ab.
49. `update_issue_note` mit leeren `notes` löscht den Text des vorhandenen Kommentars.
50. `list_users` mit `project` gibt nur Benutzer zurück, auch wenn das Projekt über eine Gruppenmitgliedschaft verfügt.
51. Auf die historische Wiki-Seitenversion ohne `view_wiki_edits` kann nicht zugegriffen werden. Die geschützte Seite kann nicht ohne die Erlaubnis zum Schutz des Wikis geändert werden.
52. `copy_issue` ohne Erlaubnis zum Hinzufügen von Beobachtern kopiert keine Beobachter; `link_copied_issue` / `copy_attachments_on_issue_copy` = `no` Link und Anhänge verbieten; Das übergeordnete Element im selben Projekt bleibt erhalten.
53. Das Erweiterungsschreibtool im schreibgeschützten Modus ruft den Handler nicht auf.
54. `delete_attachment` sichtbar in `tools/list` für Benutzer, die Problemanhänge ohne `manage_files` löschen können.
55. `add_issue_watcher` / `remove_issue_watcher` akzeptieren Gruppen-Principal über `principal_id` oder den veralteten `user_id`.
56. `get_version` mit `project` gibt die gemeinsame Version zurück, die `list_versions` für dieses Projekt zurückgegeben hat.
57. `get_issue` / `get_wiki_page` / `get_board_message` begrenzen verschachtelte Listen mit `limit`/`offset` und geben `*_pagination` zurück; ohne Include-Paginierung ist `null`.
58. Tatsächliche Tool-Antworten, einschließlich nullbarer Felder, stimmen mit dem veröffentlichten `outputSchema` überein.
59. `get_issue` mit `include_journals`: Journal mit nur versteckten benutzerdefinierten Felddetails ist nicht in der Liste und wird nicht in `journal_pagination.total_count` gezählt.
60. Ein verstecktes Journal zwischen zwei sichtbaren erzeugt keine Seitenlücke: Bei `journal_limit=2` werden zwei sichtbare Einträge zurückgegeben, `total_count` entspricht der sichtbaren Anzahl.
61. Der private Kommentar eines anderen Benutzers wird in `get_issue` nicht ohne `view_private_notes`-Berechtigung zurückgegeben.
62. `get_private_notes` gibt eine Seite nach `limit`/`offset` zurück, ohne den vollständigen Issue-Verlauf zu laden.
63. `get_issue` mit den Journalen `attr`, `cf` und `relation` gleichzeitig schlägt nicht fehl und gibt nur sichtbare Einträge zurück.
64. Journal mit versteckten benutzerdefinierten Felddetails und Notizen zu Leerzeichen, Tabulatoren oder Zeilenumbrüchen ist nicht in `get_issue` enthalten.
65. `get_private_notes` gibt keinen Kommentar zurück, der nur aus Leerzeichen, Tabulatoren oder Zeilenumbrüchen besteht.
71. `list_repositories` / `get_repository` sind mit `browse_repository` ohne `view_changesets` und umgekehrt für Discovery verfügbar; `list_revisions` / `get_revision` erfordern `view_changesets`; `get_repository_file` / `get_repository_diff` erfordern `browse_repository`. Ohne erforderliche Berechtigung gibt der Aufruf `FORBIDDEN` zurück, das Tool bleibt in `tools/list`.
72. `get_repository_file` gibt Text in `content` zurück, Binärdatei — Metadaten ohne `content`; `include_content_base64` — separates Feld. Eine Datei mit ungültigem UTF-8 (einschließlich PNG-Signatur ohne Nullbytes) gilt als binär. Eine `.txt` mit NUL ist trotz Erweiterung ebenfalls binär.
73. `get_repository_diff` kürzt Diff nach Line-/Byte-Limits und gibt `truncated: true` zurück.
74. SCM-Adapter-Fehler gibt `REDMINE_API_ERROR` zurück, nicht `NOT_FOUND`.
75. `list_repositories` / `list_revisions` / File-Tools funktionieren bei aktiviertem Repository-Modul. Mit Berechtigung und deaktiviertem Modul — `INVALID_STATE`; ohne Berechtigung und deaktiviertem Modul — `FORBIDDEN`.
76. `get_revision` gibt `file_changes` ohne `:browse_repository` nicht zurück.
77. `get_repository_file` ohne `revision` bei SCM-Fehler für `default_branch` gibt `REDMINE_API_ERROR` zurück.
78. `get_repository` bei SCM-Fehler für `default_branch` gibt Metadaten mit `default_branch: null` zurück.
79. Alle Repository-Tools sind in `tools/list` bei jeder Kombination von `view_changesets` / `browse_repository` sichtbar, einschließlich keiner von beiden, wenn der Benutzer mindestens ein Projekt sieht.
80. `update_issue` mit `project` verschiebt die Aufgabe in ein zulässiges Zielprojekt; unbekannter Identifier — `NOT_FOUND` (nicht `FORBIDDEN`); Zielprojekt ohne `add_issues` — `rejected_fields` mit `project_id`, die Aufgabe wechselt das Projekt nicht.
81. `get_mcp_info` liefert `text_formatting` mit dem effektiven Format (`common_mark`, `textile`, leere Zeichenkette oder Code eines registrierten Drittanbieter-Formats).
82. Nach Änderung der Textformatierung ohne Neustart von Redmine liefert der nächste `get_mcp_info`-Aufruf den neuen Wert von `text_formatting`.
83. Wenn in den Einstellungen ein nicht registriertes Format angegeben ist, liefert `get_mcp_info` `text_formatting: ""`.
