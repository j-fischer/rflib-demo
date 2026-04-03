---
name: rflib-mcp
description: >
  Query or manage a Salesforce org via RFLIB MCP bridge commands. Use when the user
  wants to check log archives, application events, logger settings, or user permissions
  in a Salesforce org, or says things like "check the logs", "why did the batch fail",
  "look at rflib log archives", "get application events", "check logger settings",
  "update log level", "set logging to debug", "check FLS permissions", "check OLS",
  "check APEX permissions", or "debug an org issue with rflib".
---

# /rflib-mcp — Query and Manage Salesforce Org via RFLIB MCP Bridge

Runs `sf rflib mcp` commands to inspect and manage RFLIB telemetry data and
configuration in a connected Salesforce org.

## Prerequisites

- Target org must have the `rflib` and `rflib-mcp` packages installed.
- The authenticated user must have the `rflib_MCP_Access` permission set assigned.

## Usage

```
/rflib-mcp <subcommand> --target-org <alias> [options]
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
> "Which org alias or username should I query? (e.g., staging, dev, myOrg)"

### Step 3 — Gather subcommand-specific flags

#### `logarchives get`
| Flag           | Notes                                            |
|----------------|--------------------------------------------------|
| `--start-date` | ISO 8601. Default: 1 hour ago when debugging.    |
| `--end-date`   | ISO 8601. Optional.                              |

#### `applicationevents get`
| Flag                  | Notes                                       |
|-----------------------|---------------------------------------------|
| `--event-name` / `-e` | Supports `%` wildcard, e.g. `"order-%"`    |
| `--start-date` / `-s` | ISO 8601                                    |
| `--end-date` / `-d`   | ISO 8601                                    |
| `--related-record-id` | Exact match on related record ID            |
| `--record-limit` / `-l` | Default 200, max 2000                     |

#### `loggersettings get`
No additional flags required — only `--target-org`.

#### `loggersettings update`
| Flag                    | Required  | Notes                                     |
|-------------------------|-----------|-------------------------------------------|
| `--field-name` / `-f`   | YES       | API name, e.g. `Log_Event_Reporting_Level__c` |
| `--field-value` / `-v`  | YES       | TRACE, DEBUG, INFO, WARN, ERROR, FATAL, NONE |
| `--record-id` / `-r`    | one of    | ID of existing `rflib_Logger_Settings__c` |
| `--setup-owner-id` / `-s` | one of  | Org ID (00D), Profile ID (00E), or User ID (005) |

Either `--record-id` or `--setup-owner-id` must be provided.
To find existing record IDs, run `loggersettings get` first.

#### `userpermissions get`
| Flag                      | Required  | Notes                                  |
|---------------------------|-----------|----------------------------------------|
| `--user-id` / `-u`        | YES       | 15 or 18-char Salesforce User ID (005…)|
| `--permission-type` / `-t`| YES       | `FLS`, `OLS`, `APEX`, or `ALL`         |
| `--sobject-type` / `-b`   | FLS & OLS | SObject API name, e.g. `Account`       |

Validate `--permission-type` is one of: `FLS`, `OLS`, `APEX`, `ALL`.

### Step 4 — Confirm mutating operations

`loggersettings update` modifies live org configuration. Always confirm before running:
> "This will set **[field-name]** to **[field-value]** on org **[target-org]**. Proceed? (yes/no)"

Do not run without an affirmative response. All other subcommands are read-only.

### Step 5 — Execute

```bash
sf rflib mcp <subcommand-path> --target-org <alias> [flags]
```

Examples:
```bash
sf rflib mcp logarchives get --target-org staging --start-date 2024-03-31T20:00:00Z
sf rflib mcp applicationevents get --target-org staging --event-name "OrderSync%" --record-limit 10
sf rflib mcp loggersettings get --target-org staging
sf rflib mcp loggersettings update --target-org staging --record-id a01abc --field-name Log_Event_Reporting_Level__c --field-value DEBUG
sf rflib mcp userpermissions get --target-org staging --user-id 0057000000XXXXX --permission-type FLS --sobject-type Order
```

### Step 6 — Interpret and report results

Do not dump raw JSON at the user. Parse and summarize:

**`logarchives get`**
- Total record count and time range
- Table: Timestamp | Log Level | Class/Context | Message (truncated)
- Highlight any ERROR or FATAL entries
- For error records, extract and display the full stack trace

**`applicationevents get`**
- Total record count
- Table: Event Name | Occurred On | Related Record ID
- Group by event name if multiple types appear

**`loggersettings get`**
- Table: Record Name | Setup Owner | Log_Level__c | Log_Event_Reporting_Level__c | etc.
- Flag any records where `Log_Event_Reporting_Level__c` is TRACE or DEBUG — note that
  fine-grained logging at org scale may affect performance

**`loggersettings update`**
- Confirm what was changed (field, old concept, new value, record)
- Suggest running `loggersettings get` to verify the change

**`userpermissions get`**
- For FLS/OLS: Table of field/object name, Read Access, Edit Access
- Highlight missing permissions (false/false) that could explain exceptions in log archives
- For APEX: List accessible Apex classes and Visualforce pages

---

## Autonomous Debugging Workflow

When the user describes a failure rather than requesting a specific command, follow this
4-step investigation sequence from the RFLIB MCP debugging playbook:

### Step 1 — Check logger settings
```bash
sf rflib mcp loggersettings get --target-org <alias>
```
Review `Log_Event_Reporting_Level__c`. If it is WARN or coarser, detailed errors may
not be captured. Offer to elevate temporarily:
```bash
sf rflib mcp loggersettings update --target-org <alias> \
  --setup-owner-id <orgId> \
  --field-name Log_Event_Reporting_Level__c \
  --field-value DEBUG
```

### Step 2 — Query log archives for the failure window
```bash
sf rflib mcp logarchives get --target-org <alias> --start-date <ISO8601 failure time>
```
Look for ERROR and FATAL entries. Extract exception class names, stack traces, and
the affected Apex classes. Use the stack trace to pinpoint the failing method.

### Step 3 — Correlate with application events
```bash
sf rflib mcp applicationevents get --target-org <alias> --start-date <ISO8601> --event-name "<pattern>%"
```
Match event timestamps to log archive entries to identify which business event
triggered the failing code path.

### Step 4 — Validate permissions if relevant
If logs show `DmlException`, `QueryException`, or field/object access errors:
```bash
sf rflib mcp userpermissions get --target-org <alias> \
  --user-id <userId> \
  --permission-type FLS \
  --sobject-type <ObjectApiName>
```

After gathering data from all steps, synthesize a root-cause summary and, where
possible, propose a code or configuration fix.

---

## Command Quick Reference

| Goal                                    | Command                                                                               |
|-----------------------------------------|---------------------------------------------------------------------------------------|
| Pull recent error logs (last hour)      | `logarchives get --start-date <1 hour ago>`                                           |
| Find events by name pattern             | `applicationevents get --event-name "prefix-%"`                                       |
| Read current logging config             | `loggersettings get`                                                                  |
| Raise log level for debugging           | `loggersettings update --field-name Log_Event_Reporting_Level__c --field-value DEBUG` |
| Check if user can read/write an object  | `userpermissions get --permission-type OLS --sobject-type <Object>`                   |
| Check field-level access                | `userpermissions get --permission-type FLS --sobject-type <Object>`                   |
| Check Apex class access                 | `userpermissions get --permission-type APEX`                                          |
| Check all permissions at once           | `userpermissions get --permission-type ALL`                                           |
