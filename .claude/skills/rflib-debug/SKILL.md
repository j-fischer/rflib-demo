---
name: rflib-debug
description: >
  Query or tune RFLIB telemetry in a Salesforce org with the `sf rflib debug` commands of the
  rflib-plugin. Use when the user wants to check log archives, application events, logger settings,
  or user permissions in a Salesforce org, or says things like "check the logs", "why did the batch
  fail", "look at rflib log archives", "get application events", "check logger settings",
  "update log level", "set logging to debug", "check FLS permissions", "check OLS",
  "check APEX permissions", or "debug an org issue with rflib".
---

# /rflib-debug — Query and Tune RFLIB Telemetry in a Salesforce Org

Runs the `sf rflib debug` commands of the [rflib-plugin](https://github.com/j-fischer/rflib-plugin)
to read RFLIB log archives, application events and logger settings, adjust logger settings, and
check user permissions. The commands call the Salesforce REST API directly.

## Prerequisites

- rflib-plugin installed: `sf plugins install rflib-plugin` (the debug commands require 0.19.0+;
  this demo requires 0.21.0+ for Flow instrumentation)
- **RFLIB** is installed in the target org, as the RFLIB package or deployed from source (the commands only
  query the RFLIB objects). No other package is needed.
- The running user is assigned the `rflib_Ops_Center_Access` permission set (or has equivalent read
  access to `rflib_Logs_Archive__b`, `rflib_Application_Event__c` and `rflib_Logger_Settings__c`,
  plus update access on Logger Settings for `loggersettings update`).

In this demo, `scripts/orgInit` sets all of this up (from the `../rflib` source by default, or with
`--packages`); the default org alias is `rflib_demo`.

If a command fails with `RflibNotInstalled` ("The object ... was not found in the target org"),
RFLIB is missing or the user lacks read access — report that instead of retrying.

## Usage

```
/rflib-debug <subcommand> --target-org <alias> [options]
```

## Argument Resolution

### Step 1 — Determine the subcommand

Parse `$ARGUMENTS` for one of the following intent keywords and map to a subcommand:

| User says…                                               | Subcommand              |
|----------------------------------------------------------|-------------------------|
| `logarchives`, `logs`, `log archives`, `log archive`     | `logarchives get`       |
| `applicationevents`, `events`, `app events`, `appevents` | `applicationevents get` |
| `loggersettings get`, `settings get`, `get settings`     | `loggersettings get`    |
| `loggersettings update`, `settings update`, `update setting`, `set log level`, `update log level` | `loggersettings update` |
| `userpermissions`, `permissions`, `FLS`, `OLS`, `APEX permissions`, `user permissions` | `userpermissions get`   |

If the user described a goal rather than a command (e.g., "why did the batch fail",
"find the error in staging"), start with the **Autonomous Debugging Workflow** below.

### Step 2 — Determine the target org

Look for `--target-org` or `-o` in `$ARGUMENTS`. If absent, check if the user mentioned
an org alias in their message. If still absent, ask:
> "Which org alias or username should I query? (e.g., rflib_demo, staging)"

`--target-org` is required by every `sf rflib debug` command.

### Step 3 — Gather subcommand-specific flags

#### `logarchives get`
Queries the `rflib_Logs_Archive__b` big object. Returns at most 1,000 records; check `truncated`
in the result and narrow the date range if it is `true`.

| Flag                  | Notes                                                        |
|-----------------------|--------------------------------------------------------------|
| `--start-date` / `-s` | ISO 8601. Defaults to 24 hours ago. Use the failure window when debugging. |
| `--end-date` / `-d`   | ISO 8601. Defaults to now.                                   |

#### `applicationevents get`
| Flag                         | Notes                                        |
|------------------------------|----------------------------------------------|
| `--event-name` / `-e`        | Exact match, or `LIKE` when it contains `%`, e.g. `"order-%"` |
| `--start-date` / `-s`        | ISO 8601, matches `Occurred_On__c`           |
| `--end-date` / `-d`          | ISO 8601                                     |
| `--related-record-id` / `-r` | Exact match on `Related_Record_ID__c`        |
| `--record-limit` / `-l`      | Default 200, min 1, max 2000                 |

#### `loggersettings get`
No additional flags — only `--target-org`. The result includes every
`rflib_Logger_Settings__c` record with its scope (Organization, Profile or User), plus
`bestPractices` and `notes` that are useful when recommending changes.

#### `loggersettings update`
| Flag                        | Required  | Notes                                     |
|-----------------------------|-----------|-------------------------------------------|
| `--field-name` / `-f`       | YES       | Custom field API name, e.g. `Log_Event_Reporting_Level__c` |
| `--field-value` / `-v`      | YES       | For log level fields: TRACE, DEBUG, INFO, WARN, ERROR, FATAL, NONE |
| `--record-id` / `-r`        | one of    | ID of an existing `rflib_Logger_Settings__c` record |
| `--setup-owner-id` / `-s`   | one of    | Org ID (00D), Profile ID (00E) or User ID (005). Updates that owner's record, or creates it if none exists |

Pass `--record-id` or `--setup-owner-id`. Run `loggersettings get` first to find record IDs.
To look up IDs:
- Org ID: `sf org display --target-org <alias> --json` → `result.id`
- Current user ID: `sf org display user --target-org <alias> --json` → `result.id`

The command rejects unknown fields and non-custom fields, enforces valid log levels
(`Log_Aggregation_Log_Level__c` only accepts NONE, WARN, ERROR, FATAL), and warns when
`Log_Event_Reporting_Level__c` or `Client_Server_Log_Level__c` is set below WARN at org scope.
See [references/log-levels.md](references/log-levels.md).

#### `userpermissions get`
| Flag                         | Required  | Notes                                  |
|------------------------------|-----------|----------------------------------------|
| `--user-id` / `-u`           | YES       | 15 or 18-char Salesforce User ID (005…)|
| `--permission-type` / `-t`   | YES       | `FLS`, `OLS`, `APEX`, or `ALL`         |
| `--sobject-type` / `-b`      | no        | SObject API name to filter FLS or OLS results, e.g. `Account` |

### Step 4 — Confirm mutating operations

`loggersettings update` modifies live org configuration. Always confirm before running:
> "This will set **[field-name]** to **[field-value]** for **[scope]** on org **[target-org]**. Proceed? (yes/no)"

Do not run without an affirmative response. All other subcommands are read-only.
Note the previous value (from `loggersettings get`) so it can be restored afterwards.

### Step 5 — Execute

Add `--json` so the result can be parsed reliably:

```bash
sf rflib debug <subcommand> --target-org <alias> [flags] --json
```

Examples:
```bash
sf rflib debug logarchives get --target-org rflib_demo --start-date 2026-03-31T20:00:00Z --json
sf rflib debug applicationevents get --target-org rflib_demo --event-name "property-%" --record-limit 10 --json
sf rflib debug loggersettings get --target-org rflib_demo --json
sf rflib debug loggersettings update --target-org rflib_demo --record-id a01abc --field-name Log_Event_Reporting_Level__c --field-value DEBUG --json
sf rflib debug userpermissions get --target-org rflib_demo --user-id 0057000000XXXXX --permission-type FLS --sobject-type Property__c --json
```

### Step 6 — Interpret and report results

Do not dump raw JSON at the user. Parse and summarize:

**`logarchives get`**
- Record count, time range, and whether the result was truncated
- Table: CreatedDate__c | Log_Level__c | Context__c | Request_ID__c | message (truncated)
- Highlight any ERROR or FATAL entries
- For error records, show the exception and stack trace contained in `Log_Messages__c`
- Use `Request_ID__c` to group the messages of one transaction

**`applicationevents get`**
- Record count (and whether the limit was hit)
- Table: Event_Name__c | Occurred_On__c | Related_Record_ID__c | Created_By_ID__c
- Group by event name if multiple types appear

**`loggersettings get`**
- Table: Scope | Owner | General_Log_Level__c | Log_Event_Reporting_Level__c | Archive_Log_Level__c | etc.
- Flag any org-scope records where `Log_Event_Reporting_Level__c` or `Client_Server_Log_Level__c`
  is TRACE, DEBUG or INFO — this can flood the platform event bus

**`loggersettings update`**
- Confirm what was changed (field, previous value, new value, record and scope) and relay any warnings
- Suggest running `loggersettings get` to verify the change

**`userpermissions get`**
- For FLS/OLS: table of object/field, read and edit access, and the profile or permission set granting it
- Highlight missing permissions that could explain exceptions in the log archives
- For APEX: list the accessible Apex classes and Visualforce pages

---

## Autonomous Debugging Workflow

When the user describes a failure rather than requesting a specific command, follow this
investigation sequence:

### Step 1 — Check logger settings
```bash
sf rflib debug loggersettings get --target-org <alias> --json
```
How the settings decide what ends up in the log archive:
- A log statement at or above `Log_Event_Reporting_Level__c` publishes a log event (lowest: INFO).
- The event is archived if the level of that statement is at or above `Archive_Log_Level__c`
  (`NONE` disables the archive).
- The event, and so the archive record, contains the cached messages of the transaction at or
  above `General_Log_Level__c`.

So: if errors occur but the archive is empty, check `Archive_Log_Level__c`. If archive records
exist but lack detail, offer to lower `General_Log_Level__c` temporarily, preferably for the
affected user rather than the org (confirm first, see Step 4 above):
```bash
sf rflib debug loggersettings update --target-org <alias> \
  --setup-owner-id <userId> \
  --field-name General_Log_Level__c \
  --field-value DEBUG --json
```
Then ask the user to reproduce the issue before continuing.

### Step 2 — Query log archives for the failure window
```bash
sf rflib debug logarchives get --target-org <alias> --start-date <ISO 8601 failure time> --end-date <ISO 8601> --json
```
Look for ERROR and FATAL entries. Extract exception class names, stack traces and the affected
Apex classes from `Log_Messages__c`. Use `Request_ID__c` to collect all messages of the failing
transaction and the stack trace to pinpoint the failing method.

### Step 3 — Correlate with application events
```bash
sf rflib debug applicationevents get --target-org <alias> --start-date <ISO 8601> --event-name "<pattern>%" --json
```
Match event timestamps (and `Related_Record_ID__c`) to the log archive entries to identify which
business event triggered the failing code path.

### Step 4 — Validate permissions if relevant
If logs show `DmlException`, `QueryException`, `NoAccessException` or field/object access errors:
```bash
sf rflib debug userpermissions get --target-org <alias> \
  --user-id <userId> \
  --permission-type FLS \
  --sobject-type <ObjectApiName> --json
```

### Step 5 — Restore settings and report
Restore any logger setting changed in Step 1 to its previous value (confirm first). Then
synthesize a root-cause summary and, where possible, propose a code or configuration fix.

---

## Command Quick Reference

All commands take `--target-org <alias>`; add `--json` for machine-readable output.

| Goal                                    | Command                                                                               |
|-----------------------------------------|---------------------------------------------------------------------------------------|
| Pull archived logs (last 24 hours)      | `sf rflib debug logarchives get`                                                      |
| Pull archived logs for a time window    | `sf rflib debug logarchives get --start-date <ISO> --end-date <ISO>`                  |
| Find events by name pattern             | `sf rflib debug applicationevents get --event-name "prefix-%"`                        |
| Find events for a record                | `sf rflib debug applicationevents get --related-record-id <id>`                       |
| Read current logging config             | `sf rflib debug loggersettings get`                                                   |
| Capture more detail for one user        | `sf rflib debug loggersettings update --setup-owner-id <userId> --field-name General_Log_Level__c --field-value DEBUG` |
| Check if user can read/write an object  | `sf rflib debug userpermissions get --user-id <id> --permission-type OLS --sobject-type <Object>` |
| Check field-level access                | `sf rflib debug userpermissions get --user-id <id> --permission-type FLS --sobject-type <Object>` |
| Check Apex class access                 | `sf rflib debug userpermissions get --user-id <id> --permission-type APEX`            |
| Check all permissions at once           | `sf rflib debug userpermissions get --user-id <id> --permission-type ALL`             |
