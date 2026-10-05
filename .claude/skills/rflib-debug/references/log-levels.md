# RFLIB Log Level Reference

Log levels are ordered by severity (lowest to highest). A setting of level X
means only messages at level X **and above** are processed.

| Level | Severity | Typical Use |
|-------|----------|-------------|
| `TRACE` | 1 — lowest | Fine-grained execution tracing; development only |
| `DEBUG` | 2 | Targeted debugging of specific flows; use user-scope records, not org-wide |
| `INFO` | 3 | Key business milestones and state transitions; safe default |
| `WARN` | 4 | Unexpected but recoverable conditions; recommended production minimum for reporting/client levels |
| `ERROR` | 5 | Failures that affect a single operation but not the whole transaction |
| `FATAL` | 6 | Unrecoverable failures; typically causes full transaction rollback |
| `NONE` | 7 — highest | Disables the channel entirely |

## Production vs. Sandbox Recommendations

These match the `bestPractices` returned by `sf rflib debug loggersettings get`, which is the
authoritative source if they ever differ.

| Field | Production | Sandbox |
|-------|------------|---------|
| `General_Log_Level__c` | `INFO` | `INFO` |
| `Log_Event_Reporting_Level__c` | `WARN` | `WARN` |
| `Client_Server_Log_Level__c` | `WARN` | `WARN` |
| `Client_Console_Log_Level__c` | `WARN` | `DEBUG` |
| `System_Debug_Log_Level__c` | `INFO` | `DEBUG` |
| `Archive_Log_Level__c` | `ERROR` | Dev: `NONE`, UAT: `WARN` |
| `Email_Log_Level__c` | `FATAL` | `NONE` |
| `Log_Aggregation_Log_Level__c` | `WARN` | `WARN` |
| `Batched_Log_Event_Reporting_Level__c` | `NONE` | `NONE` |

The RFLIB demo org is configured by `apex/resetCustomSettings.apex` (org defaults:
`Client_Console_Log_Level__c` = DEBUG, `Log_Event_Reporting_Level__c`, `Archive_Log_Level__c` and
`Log_Aggregation_Log_Level__c` = WARN) and `apex/pharosPostInstall.apex` (`Pharos_Log_Level__c` = WARN).

## How the Settings Interact

- `General_Log_Level__c` decides which messages are kept in the transaction's log cache.
- A message at or above `Log_Event_Reporting_Level__c` (or `Client_Server_Log_Level__c` for
  client-side loggers) publishes a log event containing the cached messages.
- The log event is stored in the log archive if the level of the message that triggered it is at
  or above `Archive_Log_Level__c`.

## Restricted Fields

`Log_Aggregation_Log_Level__c` only accepts: `NONE`, `WARN`, `ERROR`, `FATAL`.
`sf rflib debug loggersettings update` rejects `TRACE`, `DEBUG` or `INFO` for it.

When `Batched_Log_Event_Reporting_Level__c` is set, `rflib_Logger.publishBatchedLogEvents()` must
be called explicitly, otherwise the batched events are never published.

## Why Not Go Low at Org Scope?

Setting `Log_Event_Reporting_Level__c` or `Client_Server_Log_Level__c` to
`DEBUG` or `INFO` at the **Organization** scope in production publishes a
platform event for every log statement across every user session. Under any
meaningful load this floods the Salesforce platform event bus and can trigger
governor limit errors or cause event delivery delays for other consumers.
`sf rflib debug loggersettings update` prints a warning in this case.

Use **profile-scoped** or **user-scoped** `rflib_Logger_Settings__c` records
to target debug logging at specific users without affecting the rest of the org.
Settings are evaluated in hierarchy order: User overrides Profile overrides Organization.
