#!/bin/bash
#
# Instruments the demo source in force-app with the RFLIB SF CLI plugin (rflib-plugin).
#
# Usage: scripts/runRflibPlugin.sh [options]
#
#   --target-org, -o <alias>  Org the instrumented Flows will be deployed to (default: rflib_demo).
#                             Fault paths are only instrumented if it has RFLIB 11.4.0+ installed as a package.
#   --prettier                Format the instrumented Apex, Aura and LWC files with Prettier
#   --debug                   Enable debug output of the plugin
#   --skip-reset              Do not run "git reset --hard" before instrumenting
#   --skip-instrumented       Skip files that already contain RFLIB logging
#   --skip-fault-paths        Do not add error logging to Flow fault paths
#   --dryrun                  Preview the changes without modifying any files (implies --skip-reset)
#   --help, -h                Show this help
#
# WARNING: Unless --skip-reset or --dryrun is passed, all uncommitted changes are discarded with "git reset --hard".

set -e

MIN_PLUGIN_VERSION=0.21.0
TARGET_ORG=rflib_demo
PRETTIER=0
DEBUG_MODE=0
SKIP_RESET=0
SKIP_INSTRUMENTED=0
SKIP_FAULT_PATHS=0
DRYRUN=0

usage() {
    cat <<EOF
Usage: scripts/runRflibPlugin.sh [--target-org <alias>] [--prettier] [--debug] [--skip-reset]
                                 [--skip-instrumented] [--skip-fault-paths] [--dryrun]

  --target-org, -o <alias>  Org the instrumented Flows will be deployed to (default: rflib_demo)
  --prettier                Format the instrumented Apex, Aura and LWC files with Prettier
  --debug                   Enable debug output of the plugin
  --skip-reset              Do not run "git reset --hard" before instrumenting
  --skip-instrumented       Skip files that already contain RFLIB logging
  --skip-fault-paths        Do not add error logging to Flow fault paths
  --dryrun                  Preview the changes without modifying any files (implies --skip-reset)
EOF
}

usage_error() {
    echo "ERROR: $1" >&2
    echo "Run \"scripts/runRflibPlugin.sh --help\" for usage." >&2
    exit 1
}

while [ $# -gt 0 ]; do
    case "$1" in
        --target-org | -o)
            [ -n "$2" ] || usage_error "$1 requires an org alias or username"
            TARGET_ORG="$2"
            shift
            ;;
        --prettier) PRETTIER=1 ;;
        --debug) DEBUG_MODE=1 ;;
        --skip-reset) SKIP_RESET=1 ;;
        --skip-instrumented) SKIP_INSTRUMENTED=1 ;;
        --skip-fault-paths) SKIP_FAULT_PATHS=1 ;;
        --dryrun) DRYRUN=1 ;;
        --help | -h)
            usage
            exit 0
            ;;
        *) usage_error "Unknown option \"$1\"" ;;
    esac
    shift
done

cd "$(dirname "$0")/.."

trap 'echo "ERROR: Instrumentation stopped because the previous step failed." >&2' ERR

echo "Checking rflib-plugin version"
node scripts/lib/checkPluginVersion.js "$MIN_PLUGIN_VERSION"

if [ "$DEBUG_MODE" = 1 ]; then
    echo "Enabling debug output"
    export SF_LOG_LEVEL=debug
    export DEBUG='sf:Rflib*'
fi

[ "$DRYRUN" = 1 ] && SKIP_RESET=1
if [ "$SKIP_RESET" = 0 ]; then
    echo "Resetting git: discarding all uncommitted changes"
    git reset --hard
fi

COMMON_ARGS=(--sourcepath force-app)
[ "$SKIP_INSTRUMENTED" = 1 ] && COMMON_ARGS+=(--skip-instrumented)
[ "$DRYRUN" = 1 ] && COMMON_ARGS+=(--dryrun --verbose)

CODE_ARGS=("${COMMON_ARGS[@]}")
[ "$PRETTIER" = 1 ] && CODE_ARGS+=(--prettier)

FLOW_ARGS=("${COMMON_ARGS[@]}" --target-org "$TARGET_ORG")
[ "$SKIP_FAULT_PATHS" = 1 ] && FLOW_ARGS+=(--skip-fault-paths)

echo "Running Apex instrumentation"
sf rflib logging apex instrument "${CODE_ARGS[@]}"

echo "Running Aura instrumentation"
sf rflib logging aura instrument "${CODE_ARGS[@]}"

echo "Running LWC instrumentation"
sf rflib logging lwc instrument "${CODE_ARGS[@]}"

echo "Running Flow instrumentation against org $TARGET_ORG"
sf rflib logging flow instrument "${FLOW_ARGS[@]}"

echo "Instrumentation complete. Review the changes with \"git diff\" before deploying."
