# CLAUDE.md — rflib-demo

## Purpose

This is a **demo repository** built on the classic DreamHouse Salesforce sample app. Its primary purpose is to test and showcase:

- **RFLIB** — the RF Logger Framework for Salesforce (Apex, Aura, LWC, Flows)
- **rflib-plugin** — the RFLIB SF CLI plugin that auto-instruments Salesforce metadata with RFLIB logging

The app itself is a real estate management system (properties, brokers, mortgage calculator, bot interface) that serves as a realistic target for instrumentation.

---

## Repository Structure

```
rflib-demo/
├── .claude/skills/        # Claude Code skills: rflib-instrument, rflib-debug
├── apex/                  # Standalone Apex scripts (reset custom settings, Pharos post-install)
├── config/                # Scratch org definition
├── data/                  # Sample data for brokers and properties
├── force-app/main/default # Salesforce metadata (Apex, Aura, LWC, Flows, Objects, etc.)
├── scripts/               # Org setup and plugin runner scripts (.bat for Windows, .sh for macOS/Linux)
│   ├── orgInit.bat/.sh        # Create scratch org, install RFLIB packages, deploy source
│   ├── updateOrg.bat/.sh      # Upgrade RFLIB packages and redeploy source to an existing org
│   ├── runRflibPlugin.bat/.sh # Run the RFLIB SF CLI plugin instrumentation
│   └── lib/                   # Node helpers: latest RFLIB package versions, rflib-plugin version check
├── .circleci/             # CircleCI CI/CD pipeline (outdated, see below)
└── sfdx-project.json      # SFDX project manifest (API v59, package: dreamhouse)
```

---

## Prerequisites

- A default Dev Hub, the `sf` CLI and Node.js on the PATH
- rflib-plugin >= 0.21.0: `sf plugins install rflib-plugin`
- Optional: a sibling `../rflib` checkout (used to look up the latest RFLIB package versions; GitHub otherwise)

---

## Common Commands

### Org Setup

```bash
# Windows — create scratch org (default alias rflib_demo), install packages, deploy source
scripts\orgInit.bat [alias]

# macOS/Linux — same
./scripts/orgInit.sh [alias]

# Upgrade the RFLIB packages (sf rflib packages upgrade) and redeploy the source
scripts\updateOrg.bat [alias]
./scripts/updateOrg.sh [alias]
```

RFLIB is installed as **unlocked packages**, not deployed as source, because the plugin only instruments
Flow fault paths when the target org has the RFLIB 11.4.0+ package. orgInit stops at the first failing step
and runs in this order (each step needs the ones before it):

1. RFLIB → RFLIB-FS → RFLIB-TF (RFLIB-TF 4.0.0 needs RFLIB >= 10.0.0 and RFLIB-FS >= 4.0.0)
2. Pharos (third-party) → RFLIB-PHAROS → Big Object Utility
3. RFLIB permission sets → demo source (its custom metadata uses RFLIB-FS/TF types) → `dreamhouse` permission set
4. `apex/resetCustomSettings.apex`, `apex/pharosPostInstall.apex` (needs RFLIB-PHAROS) → `sf project reset tracking`

The RFLIB package version IDs are **not hardcoded**: `scripts/lib/latestRflibPackage.js` reads the latest
version of each package from `packageAliases` in `../rflib/sfdx-project.json` (or from the RFLIB repository
on GitHub if there is no sibling checkout, or from `RFLIB_PROJECT_JSON` if set) — the same source
`sf rflib packages upgrade` uses. The third-party Pharos and Big Object Utility package IDs are set at the
top of the orgInit scripts.

Orgs created before this setup deployed RFLIB as source; they can't be upgraded with updateOrg. Recreate them.

Known issues:
- rflib-plugin 0.21.0: RFLIB-TF's installed package name is `RFLIB_TF`, so `sf rflib packages upgrade` reports
  it as "not installed" and never upgrades it (the alias in the RFLIB sfdx-project.json is `RFLIB-TF`).
- Windows: use the `.bat` scripts. In Git Bash, `/c/Program Files/sf/bin/sf` calls the bundled client, which
  exits 1 even on success (`sf.cmd` uses the auto-updated client and works), so the `.sh` scripts stop early.

### Running the RFLIB SF CLI Plugin

The primary demo workflow. Instruments the metadata with RFLIB logging calls.

**WARNING:** the runner runs `git reset --hard` unless `--skip-reset` or `--dryrun` is passed. Never run it
without one of those flags while there are uncommitted changes.

```bash
# Windows — preview, then instrument
scripts\runRflibPlugin.bat --dryrun
scripts\runRflibPlugin.bat --skip-reset --prettier

# macOS/Linux — same options
./scripts/runRflibPlugin.sh --skip-reset --prettier

# Options (any order):
#   --target-org, -o <alias>  Org the Flows will be deployed to (default: rflib_demo); required by
#                             flow instrument since rflib-plugin 0.21.0
#   --prettier                Format output with Prettier after instrumentation
#   --debug                   Enable debug output
#   --skip-reset              Don't run git reset --hard first
#   --skip-instrumented       Skip files already marked as instrumented
#   --skip-fault-paths        Don't add error logging to Flow fault paths
#   --dryrun                  Preview only (implies --skip-reset)
```

The runner fails fast if the installed rflib-plugin is older than 0.21.0. If rflib-plugin is linked from a
local checkout (`sf plugins link`), compile it first (`yarn build` in that checkout): the CLI runs the
compiled `lib` folder, which can be older than the version in its package.json.

The plugin instruments:
- **Apex classes** — injects `rflib_Logger` calls
- **Aura components** — adds `rflibLoggerCmp` and logger calls
- **LWC components** — adds logger initialization and calls
- **Flows** — adds `rflib_LoggerFlowAction` elements for flow start, decisions and fault paths. Fault paths
  log the error and then terminate the transaction (`Terminate Transaction` option, RFLIB 11.4.0+). They are
  skipped with a warning if the `--target-org` doesn't have the RFLIB 11.4.0+ package.

### Running Apex Tests

```bash
sf apex run test --target-org <alias> --result-format human --code-coverage
```

### Debugging an Org

The `sf rflib debug` commands (`applicationevents get`, `logarchives get`, `loggersettings get/update`,
`userpermissions get`) read and tune RFLIB telemetry in an org. They need the RFLIB package and the
`rflib_Ops_Center_Access` permission set. Use the `rflib-debug` skill.

Check for newer RFLIB packages with `sf rflib packages upgrade --target-org rflib_demo --dryrun`.

---

## RFLIB Patterns in This Codebase

### Apex
```apex
private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('ClassName');
// Performance timer
rflib_LogTimer logTimer = rflib_LoggerUtil.startLogTimer(LOGGER, 300, 'Operation Name');
```

### Aura
```javascript
// In component helper/controller — logger is injected via rflibLoggerCmp
var logger = component.find('logger');
logger.info('Message with {0}', [value]);
```

### Flows
- Use the `rflib_LoggerFlowAction` element for log statements
- Use `rflib_GetFeatureSwitchValueAction` for feature flags
- See `Verify_Identity_with_App_Event_Logging` flow as a reference

### Retryable Actions
- `rflib_ImportDataActionHandler` implements the RFLIB-TF 4.0.0 `rflib_RetryableActionHandler` interface
  (`execute(List<rflib_RetryableAction>)`)

---

## Key Metadata

| Type | Count | Notes |
|------|-------|-------|
| Apex Classes | ~50 | 8 test classes; BotController is the main entry point for the bot |
| Aura Components | 33 | Core UI; most already have RFLIB logger wired in |
| LWC | 1 | `rflibCustomSettingsEditor` — manages RFLIB Logger Custom Settings |
| Flows | 6 | Several instrumented with RFLIB flow actions |
| Custom Objects | 6 | Property__c, Broker__c, Property_Favorite__c, Bot_Command__c, etc. |

---

## CI/CD (CircleCI)

The pipeline (`.circleci/config.yml`) runs on every push:
1. Creates a scratch org
2. Pushes source
3. Runs Apex tests
4. On `master`: creates and installs an unlocked package
5. Deletes the scratch org

Authentication uses JWT with an encrypted `server.key`. Do not commit unencrypted credentials.

**Known gap:** the pipeline still uses the deprecated `sfdx-cli` / `force:*` commands and pushes the demo
source without installing the RFLIB packages first, so the push fails on the RFLIB references.
`scripts/packagingDeployment.sh` has the same problems, and `sfdx-project.json` declares no package
dependencies on RFLIB for the `dreamhouse` package.

---

## Code Formatting

Prettier with `prettier-plugin-apex` is configured. Run before committing:

```bash
npx prettier --write "force-app/**/*.{cls,trigger,js,html,xml}"
```

Config: `prettier.config.js` — single quotes, 4-space tabs, 120 char line width.

---

## Notes

- Pharos integration: orgInit installs Pharos and RFLIB-PHAROS, then `apex/pharosPostInstall.apex` creates the
  post-processing settings and sets `Pharos_Log_Level__c` to WARN.
- The `rflibCustomSettingsEditor` LWC is the only LWC; the rest of the UI is Aura (by design — this is a demo of an older-generation app being modernized with RFLIB).
- After running the plugin, review the diff carefully — the plugin modifies files in place.
- Skills: `rflib-instrument` (instrumentation) and `rflib-debug` (`sf rflib debug` commands). The old `rflib-mcp`
  skill, the `sf rflib mcp` commands, the `rflib-mcp` package and the `rflib_MCP_Access` permission set no
  longer exist.
- `.bat` files must keep CRLF line endings and `.sh` files LF (enforced by `.gitattributes`).
