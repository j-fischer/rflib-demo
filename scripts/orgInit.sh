#!/bin/bash
#
# Creates a scratch org for the RFLIB demo and sets it up.
#
# Usage: scripts/orgInit.sh [--alias <alias>] [--packages]
#
#   --alias, -a <alias>  Alias of the new scratch org (default: rflib_demo)
#   --packages           Install the latest released RFLIB packages instead of deploying the source code
#                        of the sibling ../rflib checkout
#   --help, -h           Show this help
#
# By default, RFLIB (all of RFLIB, RFLIB-FS, RFLIB-TF and RFLIB-PHAROS) is deployed as unpackaged source
# from ../rflib, so that the org runs the RFLIB code under development. In this mode, the RFLIB SF CLI
# plugin skips Flow fault paths, because they require RFLIB 11.4.0+ installed as a package. Use --packages
# to demo them; the latest package version IDs are then read from the packageAliases in the RFLIB
# sfdx-project.json (see scripts/lib/latestRflibPackage.js).
#
# Setup order (every step requires the ones before it):
#   1. RFLIB                           Source: ../rflib. Packages: RFLIB, RFLIB-FS, RFLIB-TF
#   2. Pharos                          RFLIB-PHAROS forwards log events to the pharos__ objects
#   3. RFLIB-PHAROS (--packages only)  Part of the source deploy in step 1 otherwise
#   4. Big Object Utility
#   5. RFLIB permission sets, demo source (its custom metadata uses RFLIB-FS and RFLIB-TF types)
#   6. Apex scripts                    pharosPostInstall.apex requires RFLIB-PHAROS and Pharos

set -eE

# Third-party AppExchange packages
PHAROS_PACKAGE_ID=04t5a000001g4x9AAA
BIG_OBJECT_UTILITY_PACKAGE_ID=04t7F000003irldQAA
INSTALL_WAIT_MINUTES=30

ORG_ALIAS=rflib_demo
USE_PACKAGES=0

usage() {
    cat <<EOF
Usage: scripts/orgInit.sh [--alias <alias>] [--packages]

  --alias, -a <alias>  Alias of the new scratch org (default: rflib_demo)
  --packages           Install the latest released RFLIB packages instead of deploying the source code
                       of the sibling ../rflib checkout. Required for Flow fault-path instrumentation.
EOF
}

usage_error() {
    echo "ERROR: $1" >&2
    echo "Run \"scripts/orgInit.sh --help\" for usage." >&2
    exit 1
}

while [ $# -gt 0 ]; do
    case "$1" in
        --alias | -a)
            [ -n "$2" ] || usage_error "$1 requires an alias"
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

trap '[ "$BASH_SUBSHELL" = 0 ] && echo "ERROR: Org setup stopped because the previous step failed." >&2' ERR

# Sets <prefix>_ID to the latest package version ID of an RFLIB package and <prefix>_VERSION to its version.
# Usage: resolve_package <package name> <prefix>
resolve_package() {
    local resolved
    resolved="$(node scripts/lib/latestRflibPackage.js "$1")"
    read -r "${2}_ID" "${2}_VERSION" <<<"$resolved"
    echo "  $1 ${resolved#* }: ${resolved%% *}"
}

# Usage: install_package "<display name>" <package version ID>
install_package() {
    echo "Installing $1 ($2)"
    sf package install --package "$2" --target-org "$ORG_ALIAS" --wait "$INSTALL_WAIT_MINUTES" --no-prompt
}

if [ "$USE_PACKAGES" = 1 ]; then
    echo "Resolving the latest RFLIB package versions"
    resolve_package RFLIB RFLIB
    resolve_package RFLIB-FS RFLIB_FS
    resolve_package RFLIB-TF RFLIB_TF
    resolve_package RFLIB-PHAROS RFLIB_PHAROS
elif [ ! -f "$RFLIB_DIR/sfdx-project.json" ]; then
    echo "ERROR: No RFLIB checkout found in $RFLIB_DIR. Clone https://github.com/j-fischer/rflib next to" >&2
    echo "       this repository, or run with --packages to install the released RFLIB packages." >&2
    exit 1
fi

echo "Creating scratch org $ORG_ALIAS"
sf org create scratch --alias "$ORG_ALIAS" --set-default --definition-file config/project-scratch-def.json --duration-days 30

if [ "$USE_PACKAGES" = 1 ]; then
    install_package "RFLIB $RFLIB_VERSION" "$RFLIB_ID"
    install_package "RFLIB-FS $RFLIB_FS_VERSION" "$RFLIB_FS_ID"
    install_package "RFLIB-TF $RFLIB_TF_VERSION" "$RFLIB_TF_ID"
else
    echo "Deploying RFLIB source from $RFLIB_DIR"
    (cd "$RFLIB_DIR" && sf project deploy start --target-org "$ORG_ALIAS" --ignore-conflicts)
fi

install_package "Pharos" "$PHAROS_PACKAGE_ID"
if [ "$USE_PACKAGES" = 1 ]; then
    install_package "RFLIB-PHAROS $RFLIB_PHAROS_VERSION" "$RFLIB_PHAROS_ID"
fi
install_package "Big Object Utility" "$BIG_OBJECT_UTILITY_PACKAGE_ID"

echo "Assigning RFLIB permission sets"
sf org assign permset --target-org "$ORG_ALIAS" --name rflib_Ops_Center_Access --name rflib_Enable_Client_Logging --name rflib_Create_Application_Event

echo "Deploying the demo source"
sf project deploy start --target-org "$ORG_ALIAS" --ignore-conflicts

sf org assign permset --target-org "$ORG_ALIAS" --name dreamhouse

echo "Configuring RFLIB Logger Settings"
sf apex run --target-org "$ORG_ALIAS" --file apex/resetCustomSettings.apex
sf apex run --target-org "$ORG_ALIAS" --file apex/pharosPostInstall.apex

sf project reset tracking --target-org "$ORG_ALIAS" --no-prompt

sf org open --target-org "$ORG_ALIAS" --path /lightning/page/home

echo "Org $ORG_ALIAS is set up"
