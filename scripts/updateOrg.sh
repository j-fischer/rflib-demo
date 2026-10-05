#!/bin/bash
#
# Brings an org created with scripts/orgInit.sh up to date.
#
# Usage: scripts/updateOrg.sh [--target-org <alias>] [--packages]
#
#   --target-org, -o <alias>  Org to update (default: rflib_demo)
#   --packages                Upgrade the installed RFLIB packages with "sf rflib packages upgrade" instead of
#                             deploying the source code of the sibling ../rflib checkout. Use this for orgs
#                             created with "orgInit.sh --packages".
#   --help, -h                Show this help
#
# Then deploys the demo source, resets the RFLIB Logger Settings and resets source tracking.

set -eE

MIN_PLUGIN_VERSION=0.21.0
INSTALL_WAIT_MINUTES=30

ORG_ALIAS=rflib_demo
USE_PACKAGES=0

usage() {
    cat <<EOF
Usage: scripts/updateOrg.sh [--target-org <alias>] [--packages]

  --target-org, -o <alias>  Org to update (default: rflib_demo)
  --packages                Upgrade the installed RFLIB packages instead of deploying the ../rflib source
EOF
}

usage_error() {
    echo "ERROR: $1" >&2
    echo "Run \"scripts/updateOrg.sh --help\" for usage." >&2
    exit 1
}

while [ $# -gt 0 ]; do
    case "$1" in
        --target-org | -o)
            [ -n "$2" ] || usage_error "$1 requires an org alias or username"
            ORG_ALIAS="$2"
            shift
            ;;
        --packages) USE_PACKAGES=1 ;;
        --help | -h)
            usage
            exit 0
            ;;
        *) usage_error "Unknown option \"$1\"" ;;
    esac
    shift
done

cd "$(dirname "$0")/.."
RFLIB_DIR="$(cd .. && pwd)/rflib"

trap '[ "$BASH_SUBSHELL" = 0 ] && echo "ERROR: Org update stopped because the previous step failed." >&2' ERR

if [ "$USE_PACKAGES" = 1 ]; then
    node scripts/lib/checkPluginVersion.js "$MIN_PLUGIN_VERSION"

    echo "Upgrading the RFLIB packages"
    sf rflib packages upgrade --target-org "$ORG_ALIAS" --no-prompt --wait "$INSTALL_WAIT_MINUTES"
else
    if [ ! -f "$RFLIB_DIR/sfdx-project.json" ]; then
        echo "ERROR: No RFLIB checkout found in $RFLIB_DIR. Run with --packages for orgs using the RFLIB packages." >&2
        exit 1
    fi
    echo "Deploying RFLIB source from $RFLIB_DIR"
    (cd "$RFLIB_DIR" && sf project deploy start --target-org "$ORG_ALIAS" --ignore-conflicts)
fi

echo "Deploying the demo source"
sf project deploy start --target-org "$ORG_ALIAS" --ignore-conflicts

sf apex run --target-org "$ORG_ALIAS" --file apex/resetCustomSettings.apex

sf project reset tracking --target-org "$ORG_ALIAS" --no-prompt

echo "Org $ORG_ALIAS is up-to-date"
