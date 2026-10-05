# RFLIB Demo

A demo and test bed for [RFLIB](https://github.com/j-fischer/rflib), the open-source logging framework for Salesforce, and for [rflib-plugin](https://github.com/j-fischer/rflib-plugin), the Salesforce CLI plugin that automatically instruments Salesforce metadata with RFLIB logging.

The app is the classic Aura version of the DreamHouse real estate sample app (see [About DreamHouse](#about-dreamhouse)). Its Apex classes, Aura components, Lightning Web Component and Flows give the plugin a realistic code base to instrument, and the org setup installs the RFLIB packages so all RFLIB features can be shown:

- Logging from Apex, Aura, LWC and Flows, viewed in the RFLIB Ops Center (Log Monitor, Log Archive, Management Dashboard)
- Application Events, Feature Switches (RFLIB-FS), the Trigger Framework and Retryable Actions (RFLIB-TF)
- Log forwarding to [Pharos](https://pharos.ai/) (RFLIB-PHAROS)
- Automatic instrumentation with `sf rflib logging ... instrument`, including Flow fault-path logging
- Debugging an org with the `sf rflib debug` commands, e.g. from Claude Code (see [`.claude/skills`](.claude/skills))

## Prerequisites

- A [Dev Hub](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_enable_devhub.htm) org, authorized as your default Dev Hub (`sf org login web --set-default-dev-hub`)
- The [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli) (`sf`)
- [Node.js](https://nodejs.org/) on your `PATH`; the setup scripts use it to read package versions and check the plugin version
- rflib-plugin **0.21.0 or later**:
    ```bash
    sf plugins install rflib-plugin
    ```
- Optional: a checkout of [rflib](https://github.com/j-fischer/rflib) next to this repository (`../rflib`). The setup reads the latest RFLIB package versions from `../rflib/sfdx-project.json` if it exists, and from the RFLIB repository on GitHub otherwise. Set `RFLIB_PROJECT_JSON` to a path or URL to use a different `sfdx-project.json`.

## Setup

The setup script creates a scratch org (default alias `rflib_demo`, 30 days) and then:

1. Installs the latest **RFLIB**, **RFLIB-FS** and **RFLIB-TF** packages, in dependency order
2. Installs **Pharos** and then **RFLIB-PHAROS**
3. Installs **Big Object Utility**
4. Assigns the RFLIB permission sets, deploys the demo source and assigns the `dreamhouse` permission set
5. Configures the RFLIB Logger Settings (`apex/resetCustomSettings.apex`, `apex/pharosPostInstall.apex`) and resets source tracking

RFLIB is installed as packages rather than deployed as source because the plugin only instruments Flow fault paths when the target org has RFLIB 11.4.0 or later installed as a package. The script stops at the first step that fails.

Windows:

```bash
scripts\orgInit.bat
```

macOS/Linux:

```bash
./scripts/orgInit.sh
```

Pass an alias to use a different name, e.g. `scripts\orgInit.bat my_demo`. The new org becomes the default org of this project.

On Windows, use the `.bat` scripts. In Git Bash, the `sf` wrapper of the Windows installer can return a non-zero exit code for successful commands, which stops the `.sh` scripts.

To bring an existing org up to date later, run `scripts\updateOrg.bat` or `./scripts/updateOrg.sh` (optionally with the org alias). It upgrades the installed RFLIB packages with `sf rflib packages upgrade` and redeploys the demo source. Orgs created by older versions of this repository, which deployed RFLIB as source, can't be upgraded this way; create a new org instead.

> **Known issue (rflib-plugin 0.21.0):** the RFLIB-TF package is installed under the name `RFLIB_TF`, so `sf rflib packages upgrade` reports it as not installed and won't upgrade it. When a new RFLIB-TF version is released, install it with `sf package install --package <04t ID> --target-org rflib_demo --wait 30`.

To check for newer RFLIB packages at any time:

```bash
sf rflib packages upgrade --target-org rflib_demo --dryrun
```

## Running the Plugin

`scripts/runRflibPlugin.bat` (Windows) and `scripts/runRflibPlugin.sh` (macOS/Linux) instrument the Apex classes, Aura components, LWC and Flows in `force-app` with RFLIB logging.

> **Warning:** Unless `--skip-reset` or `--dryrun` is passed, the scripts first run `git reset --hard` and discard **all** uncommitted changes, so that every run starts from the uninstrumented source.

Preview the changes first:

```bash
scripts\runRflibPlugin.bat --dryrun
```

Then instrument the source:

```bash
scripts\runRflibPlugin.bat --skip-reset --prettier
```

| Option | Description |
|--------|-------------|
| `--target-org`, `-o <alias>` | Org the instrumented Flows will be deployed to (default: `rflib_demo`). Fault paths are only instrumented if this org has RFLIB 11.4.0+ installed as a package; otherwise they are skipped with a warning. |
| `--prettier` | Format the instrumented Apex, Aura and LWC files with Prettier |
| `--debug` | Enable debug output of the plugin |
| `--skip-reset` | Don't run `git reset --hard` before instrumenting |
| `--skip-instrumented` | Skip files that already contain RFLIB logging |
| `--skip-fault-paths` | Don't add error logging to Flow fault paths |
| `--dryrun` | Preview the changes without modifying any files (implies `--skip-reset`) |

Options can be passed in any order. The scripts stop if the installed rflib-plugin is older than 0.21.0.

Review the result with `git diff`, then deploy it and run the tests:

```bash
sf project deploy start --target-org rflib_demo
```

```bash
sf apex run test --target-org rflib_demo --result-format human --code-coverage --wait 20
```

See the [rflib-plugin README](https://github.com/j-fischer/rflib-plugin#readme) for all plugin commands.

## Resetting the Demo

The instrumentation only changes files in `force-app`, so git restores the original source:

```bash
git reset --hard
```

Running the plugin scripts without `--skip-reset` does the same before instrumenting. To restore the org as well, redeploy the source with `scripts\updateOrg.bat` / `./scripts/updateOrg.sh`, or delete the scratch org (`sf org delete scratch --target-org rflib_demo`) and run the setup script again.

## Claude Code Skills

The [`.claude/skills`](.claude/skills) folder contains two skills for [Claude Code](https://claude.com/claude-code):

- `rflib-instrument` combines the plugin's instrument commands with edits for patterns the plugin doesn't cover
- `rflib-debug` uses the `sf rflib debug` commands to investigate issues from log archives, application events, logger settings and user permissions

## About DreamHouse

DreamHouse is a Salesforce sample application for the real estate business that lets brokers manage their properties and customers find their dream house. This repository is based on the Aura version, [dreamhouseapp/dreamhouse-sfdx](https://github.com/dreamhouseapp/dreamhouse-sfdx); see that repository for the original documentation and code highlights. A Lightning Web Components version is available at [dreamhouseapp/dreamhouse-lwc](https://github.com/dreamhouseapp/dreamhouse-lwc).

After setting up the org, select **DreamHouse** in the App Launcher, open the **Sample Data Import** tab and click **Import Sample Data** to load the sample data. **Import Sample Data using Retryable Action** does the same asynchronously through the RFLIB-TF Retryable Action framework.
