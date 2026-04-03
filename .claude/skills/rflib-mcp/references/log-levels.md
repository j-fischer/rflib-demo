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

| Field | Production | Sandbox |
|-------|------------|---------|
| `General_Log_Level__c` | `INFO` | `INFO` or `DEBUG` |
| `Log_Event_Reporting_Level__c` | `WARN` | `WARN` |
| `Client_Server_Log_Level__c` | `WARN` | `WARN` |
| `Client_Console_Log_Level__c` | `WARN` | `DEBUG` |
| `System_Debug_Log_Level__c` | `WARN` | `DEBUG` |
| `Archive_Log_Level__c` | `ERROR` | `WARN` or `ERROR` |
| `Email_Log_Level__c` | `FATAL` | `NONE` |
| `Log_Aggregation_Log_Level__c` | `ERROR` | `NONE` |
| `Batched_Log_Event_Reporting_Level__c` | `WARN` | `WARN` |

## Restricted Fields

`Log_Aggregation_Log_Level__c` only accepts: `NONE`, `WARN`, `ERROR`, `FATAL`.
Setting it to `TRACE`, `DEBUG`, or `INFO` is a validation error.

## Why Not Go Low at Org Scope?

Setting `Log_Event_Reporting_Level__c` or `Client_Server_Log_Level__c` to
`DEBUG` or `INFO` at the **Organization** scope in production publishes a
platform event for every log statement across every user session. Under any
meaningful load this floods the Salesforce platform event bus and can trigger
governor limit errors or cause event delivery delays for other consumers.

Use **profile-scoped** or **user-scoped** `rflib_Logger_Settings__c` records
to target debug logging at specific users without affecting the rest of the org.
