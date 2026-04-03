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
├── apex/                  # Standalone Apex scripts (post-install, reset custom settings)
├── config/                # Scratch org definition
├── data/                  # Sample data for brokers and properties
├── force-app/main/default # Salesforce metadata (Apex, Aura, LWC, Flows, Objects, etc.)
├── scripts/               # Org setup and RFLIB plugin runner scripts
│   ├── orgInit.sh/.bat    # Create scratch org and push source
│   ├── updateOrg.bat      # Push updates to existing scratch org
│   └── runRflibPlugin.bat # Run the RFLIB SF CLI plugin instrumentation
├── .circleci/             # CircleCI CI/CD pipeline
└── sfdx-project.json      # SFDX project manifest (API v59, package: dreamhouse)
```

---

## Common Commands

### Org Setup

```bash
# Unix/Linux — create scratch org, push source, import data
./scripts/orgInit.sh

# Windows — same
scripts\orgInit.bat

# Push updates to an existing scratch org
scripts\updateOrg.bat
```

### Running the RFLIB SF CLI Plugin

The primary demo workflow. Instruments the metadata with RFLIB logging calls.

```bash
# Windows — run with default settings
scripts\runRflibPlugin.bat

# Flags (edit the .bat file or run the plugin directly):
#   --prettier           Format output with Prettier after instrumentation
#   --debug              Enable debug output
#   --skip-reset         Skip resetting previously instrumented files first
#   --skip-instrumented  Skip files already marked as instrumented
```

The plugin instruments:
- **Apex classes** — injects `rflib_Logger` calls
- **Aura components** — adds `rflibLoggerCmp` and logger calls
- **LWC components** — adds logger initialization and calls
- **Flows** — adds `rflib_LoggerFlowAction` elements

### Running Apex Tests

```bash
sf apex run test --target-org <alias> --result-format human --code-coverage
```

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

---

## Code Formatting

Prettier with `prettier-plugin-apex` is configured. Run before committing:

```bash
npx prettier --write "force-app/**/*.{cls,trigger,js,html,xml}"
```

Config: `prettier.config.js` — single quotes, 4-space tabs, 120 char line width.

---

## Notes

- The `README.md` is the original DreamHouse README (2019) and does not reflect RFLIB additions.
- Pharos integration is present in `apex/pharosPostInstall.apex` for advanced log monitoring demos.
- The `rflibCustomSettingsEditor` LWC is the only LWC; the rest of the UI is Aura (by design — this is a demo of an older-generation app being modernized with RFLIB).
- After running the plugin, review the diff carefully — the plugin modifies files in place.
