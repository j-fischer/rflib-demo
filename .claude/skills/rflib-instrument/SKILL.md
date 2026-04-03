---
name: rflib-instrument
description: >
  Instrument Salesforce source files with RFLIB logging. Use when the user wants to
  add RFLIB logging statements to Apex classes, LWC JavaScript, Aura components, or
  Salesforce Flows, or says things like "instrument my code", "add logging to apex",
  "add rflib to lwc", "instrument flows", "add rflib logging", or "instrument all".
---

# /rflib-instrument — Instrument Source Files with RFLIB Logging

Adds RFLIB logging statements to Apex classes, LWC components, Aura components, and
Salesforce Flows using the `sf rflib logging` commands.

## Usage

```
/rflib-instrument [apex|lwc|aura|flow|all] [--sourcepath <path>] [options]
```

## Argument Resolution

### Step 1 — Determine the target type

Parse `$ARGUMENTS` for a leading keyword: `apex`, `lwc`, `aura`, `flow`, or `all`.

- `apex` — Apex classes (.cls files)
- `lwc`  — Lightning Web Component JavaScript/TypeScript files
- `aura` — Aura Component JavaScript files
- `flow` — Salesforce Flow XML files (.flow-meta.xml)
- `all`  — Run all four in sequence against the same `--sourcepath`

If no type keyword is present, check the user's surrounding message for context
(e.g., if they mentioned "my Apex classes", use `apex`). If still ambiguous, ask:
> "Which component type do you want to instrument? (apex / lwc / aura / flow / all)"

### Step 2 — Determine the source path

Look for `--sourcepath` or `-s` in `$ARGUMENTS`. If absent, ask:
> "What is the source path to instrument? (e.g., force-app/main/default/classes)"

Common defaults to suggest:
- apex: `force-app/main/default/classes`
- lwc:  `force-app/main/default/lwc`
- aura: `force-app/main/default/aura`
- flow: `force-app/main/default/flows`
- all:  `force-app`

### Step 3 — Determine options

Check `$ARGUMENTS` for any flags below. If not present, apply the listed defaults:

| Flag                | Default | Notes                                                   |
|---------------------|---------|---------------------------------------------------------|
| `--dryrun` / `-d`   | true    | Always dry-run first; confirm before live run           |
| `--skip-instrumented` | false | Recommend `true` if codebase may already have RFLIB     |
| `--prettier` / `-p` | false   | Suggest if project uses Prettier                        |
| `--verbose` / `-v`  | false   | Recommend alongside `--dryrun` to see affected files    |
| `--exclude` / `-e`  | none    | Glob pattern; suggest for generated or managed pkg code |
| `--no-if`           | false   | Apex/LWC/Aura only — omit if/else statement logging     |
| `--no-catch`        | false   | Apex only — omit catch-block logging                    |
| `--concurrency` / `-c` | 10   | Increase for large codebases                            |

### Step 4 — Dry-run gate

Unless the user explicitly passed `--no-dryrun`, said "skip dry run", or "just do it":

1. Run with `--dryrun --verbose`
2. Show the output summary
3. Ask: *"X files would be modified. Proceed with the actual instrumentation? (yes/no)"*

Do not proceed without an affirmative answer.

### Step 5 — Execute

Build and run the appropriate command(s):

**Single type:**
```bash
sf rflib logging <type> instrument --sourcepath <path> [flags]
```

**`all` pseudo-target** — run each type sequentially with the same sourcepath:
```bash
sf rflib logging apex instrument --sourcepath <path> [flags]
sf rflib logging lwc  instrument --sourcepath <path> [flags]
sf rflib logging aura instrument --sourcepath <path> [flags]
sf rflib logging flow instrument --sourcepath <path> [flags]
```

**Flag compatibility rules — do not pass unsupported flags:**
- `--no-catch` is supported by `apex` only
- `--no-if` is supported by `apex`, `lwc`, `aura` — NOT `flow`
- `--prettier` is supported by `apex`, `lwc`, `aura` — NOT `flow`

### Step 6 — Report results

After execution, summarize:
- Total files processed
- Total files modified
- Files formatted (if `--prettier` was used)
- List of modified file paths (if `--verbose` was used)
- Any errors encountered

---

## Component Type Guide

| Type | File Pattern              | What Gets Added                                          |
|------|---------------------------|----------------------------------------------------------|
| apex | `*.cls`                   | Logger declaration, method entry logs, catch logs,       |
|      |                           | if/else condition logs, `System.debug()` replacement     |
| lwc  | `*.js`, `*.ts` in lwc/    | `createLogger` import, method entry logs, catch logs,    |
|      |                           | if/else logs, `console.log/warn/error` replacement       |
| aura | `*.js` in aura/           | Logger helper import, method entry logs, catch logs,     |
|      |                           | if/else logs, `console.*` replacement                    |
| flow | `*.flow-meta.xml`         | RFLIB log actions before flow elements, decision         |
|      |                           | branch logging, AUTO_LAYOUT_CANVAS mode                  |

---

## Common Workflows

### First-time onboarding (safe)
```
/rflib-instrument all --sourcepath force-app --dryrun --verbose
```
Review what would change, then re-run without `--dryrun`.

### Instrument one component type
```
/rflib-instrument apex --sourcepath force-app/main/default/classes
```

### Re-run on a partially-instrumented codebase
Always add `--skip-instrumented` to avoid double-logging:
```
/rflib-instrument lwc --sourcepath force-app --skip-instrumented
```

### Exclude generated or managed package code
```
/rflib-instrument apex --sourcepath force-app --exclude "**/fflib_*.cls"
```

### Instrument with Prettier formatting
```
/rflib-instrument apex --sourcepath force-app/main/default/classes --prettier
```

---

## Flag Reference

| Flag                  | Short | Types          | Description                            |
|-----------------------|-------|----------------|----------------------------------------|
| `--sourcepath`        | `-s`  | all            | Directory to instrument (required)     |
| `--dryrun`            | `-d`  | all            | Preview without modifying files        |
| `--prettier`          | `-p`  | apex, lwc, aura| Format output with Prettier            |
| `--skip-instrumented` |       | all            | Skip files already containing RFLIB    |
| `--verbose`           | `-v`  | all            | Print paths of files that would change |
| `--exclude`           | `-e`  | all            | Glob pattern to exclude files          |
| `--no-if`             |       | apex, lwc, aura| Skip if/else statement instrumentation |
| `--no-catch`          |       | apex only      | Skip catch block instrumentation       |
| `--concurrency`       | `-c`  | all            | Parallel worker count (default: 10)    |
