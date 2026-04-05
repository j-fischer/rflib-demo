---
name: rflib-instrument
description: >
  Instrument Salesforce source files with RFLIB logging. Use when the user wants to
  add RFLIB logging statements to Apex classes, LWC JavaScript, Aura components, or
  Salesforce Flows, or says things like "instrument my code", "add logging to apex",
  "add rflib to lwc", "instrument flows", "add rflib logging", or "instrument all".
---

# /rflib-instrument — Instrument Source Files with RFLIB Logging

A hybrid agent that combines the `sf rflib logging` CLI commands (fast, regex-based bulk
instrumentation) with direct file editing to cover patterns the CLI engine cannot handle.

## Usage

```
/rflib-instrument [apex|lwc|aura|flow|all] [--sourcepath <path>] [options]
```

## Three-Phase Workflow

### Phase 1 — Argument Resolution

**Determine target type** from `$ARGUMENTS`:
- `apex`  — Apex classes (`.cls`)
- `lwc`   — Lightning Web Component JS/TS files
- `aura`  — Aura Component JS files
- `flow`  — Salesforce Flow XML (`.flow-meta.xml`)
- `all`   — Run all four in sequence

If not specified, infer from context. If still ambiguous, ask:
> "Which component type? (apex / lwc / aura / flow / all)"

**Determine source path** from `--sourcepath` / `-s`. If absent, ask:
> "What is the source path? (e.g., force-app/main/default/classes)"

Common defaults to suggest:
- apex: `force-app/main/default/classes`
- lwc:  `force-app/main/default/lwc`
- aura: `force-app/main/default/aura`
- flow: `force-app/main/default/flows`
- all:  `force-app`

**Resolve options** — defaults if not specified in `$ARGUMENTS`:

| Flag                  | Default | Notes                                                    |
|-----------------------|---------|----------------------------------------------------------|
| `--dryrun` / `-d`     | true    | Always dry-run first; confirm before live run            |
| `--skip-instrumented` | false   | Recommend `true` for partially-instrumented codebases    |
| `--verbose` / `-v`    | false   | Recommend alongside `--dryrun` to see affected files     |
| `--prettier` / `-p`   | false   | Suggest if project uses Prettier                         |
| `--exclude` / `-e`    | none    | Glob pattern for generated or managed package files      |
| `--no-if`             | false   | apex/lwc/aura only — omit if/else condition logging      |
| `--no-catch`          | false   | apex only — omit catch block logging                     |
| `--concurrency` / `-c`| 10      | Increase for large codebases                             |

**Flag compatibility** — do not pass unsupported flags:
- `--no-catch`: apex only
- `--no-if`, `--prettier`: apex, lwc, aura — NOT flow

---

### Phase 2 — CLI Bulk Instrumentation

Run the CLI command(s) which handle the fast, well-tested regex-based cases:
method entry logging, catch blocks, if/else conditions, System.debug/console.log replacement,
promise chain logging, and logger declaration insertion.

**Dry-run gate** — unless the user explicitly opted out, always run with `--dryrun --verbose` first:
```bash
sf rflib logging <type> instrument --sourcepath <path> --dryrun --verbose [flags]
```
Show the output, then ask:
> "X files would be modified. Proceed with instrumentation? (yes/no)"

Do not continue without an affirmative answer.

**Live run** after confirmation:
```bash
sf rflib logging <type> instrument --sourcepath <path> [flags]
```

For `all`, run each type sequentially (skip unsupported flags per type):
```bash
sf rflib logging apex instrument --sourcepath <path> [flags]
sf rflib logging lwc  instrument --sourcepath <path> [flags]
sf rflib logging aura instrument --sourcepath <path> [flags]
sf rflib logging flow instrument --sourcepath <path> [flags]
```

---

### Phase 3 — Agent Gap Analysis and Fill

After the CLI run (or in dry-run mode: after reading the unmodified files), use the Read tool
to scan the modified files and identify patterns the regex engine cannot handle. Use the Edit
tool to add the missing log statements.

Skip Phase 3 if the type is `flow` — Flow instrumentation is XML-only and fully handled by the CLI.

#### Patterns to detect and fix

**Apex:**

| Pattern | What to add |
|---------|-------------|
| `switch on <expr> { when <val> { ... } }` | `LOGGER.debug('switch on <expr>: when <val>');` at the start of each `when` block |
| `return condition ? valueA : valueB;` | `LOGGER.debug('<methodName>() ternary: <condition>');` before the return |
| `for (...) { ... }` / `while (...) { ... }` | `LOGGER.debug('<methodName>() entering <for/while> loop: <condition>');` before the loop |
| Complex generic parameter type not serialized | Ensure `JSON.serialize()` wraps the argument in the existing method entry log |

**LWC / Aura:**

| Pattern | What to add |
|---------|-------------|
| `switch (expr) { case val: ... }` | `logger.debug('<methodName>() switch case: <val>');` at the start of each `case` |
| `return condition ? valueA : valueB;` | `logger.debug('<methodName>() ternary: <condition>');` before the return |
| `for (... of ...) { ... }` / `while (...) { ... }` | `logger.debug('<methodName>() entering loop');` before the loop |
| Parameter with union type (`string \| null`) | Log with just the parameter name (no type annotation in the log message) |

#### Scope guard — do NOT instrument

- Lines already containing `LOGGER.` or `logger.` (already instrumented)
- LWC/Aura lifecycle callbacks (`connectedCallback`, `disconnectedCallback`, `renderedCallback`,
  `errorCallback`) unless they contain user logic beyond `super.*()` calls — for these, only
  add a method entry log, not loop/ternary/switch logs
- Files matching the user's `--exclude` pattern
- Test helper methods or mock functions

#### In dry-run mode

Do not write any files. Instead, list for each file what statements Claude would add:
```
[DRY RUN] Would add to OrderService.cls:
  Line 42: LOGGER.debug('switch on orderType: when STANDARD');
  Line 67: LOGGER.debug('processOrder() ternary: hasDiscount');
```

---

### Phase 4 — Report

Summarize the full instrumentation:

```
Phase 1 (CLI):
  Files processed:  42
  Files modified:   38
  Patterns added:   method entry (38), catch (12), if/else (24), System.debug replaced (7)

Phase 2 (Agent):
  Additional edits: 6 files
  Patterns added:   switch (3), ternary (2), for loop (4)

Total modified: 44 files
```

Group Phase 2 changes by file. Offer to run Prettier if not already applied.

---

## Component Type Guide

| Type | Files          | CLI handles                              | Agent adds                               |
|------|----------------|------------------------------------------|------------------------------------------|
| apex | `*.cls`        | method entry, catch, if/else, debug repl | switch, ternary, loops, generic fix      |
| lwc  | `*.js`, `*.ts` | method entry, catch, if/else, console repl, promise chains | switch, ternary, loops, union type fix |
| aura | `*.js` in aura | method entry, catch, if/else, console repl, promise chains | switch, ternary, loops |
| flow | `*.flow-meta.xml` | log actions, decision branches, layout | nothing (XML-only, fully handled)      |

## Common Workflows

### First-time onboarding
```
/rflib-instrument all --sourcepath force-app
```
Dry-runs CLI, shows preview, confirms, then Claude fills gaps.

### Re-run on partially-instrumented codebase
```
/rflib-instrument apex --sourcepath force-app --skip-instrumented
```

### Exclude generated code
```
/rflib-instrument apex --sourcepath force-app --exclude "**/fflib_*.cls"
```

### Dry-run only (preview both phases, no writes)
```
/rflib-instrument lwc --sourcepath force-app/main/default/lwc --dryrun
```
