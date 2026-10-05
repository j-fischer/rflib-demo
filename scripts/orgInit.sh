#!/bin/bash
#
# Creates a scratch org for the RFLIB demo and sets it up.
#
# Usage: scripts/orgInit.sh [org alias]   (default: rflib_demo)
#
# The RFLIB packages are installed as unlocked packages, so that the RFLIB SF CLI plugin can detect
# RFLIB 11.4.0+ in the org and instrument Flow fault paths. The latest package version IDs are read
# from the packageAliases in the RFLIB sfdx-project.json (see scripts/lib/latestRflibPackage.js), which
# is taken from a sibling ../rflib checkout if present, or from GitHub otherwise.
#
# Setup order (every step requires the ones before it):
#   1. RFLIB, RFLIB-FS, RFLIB-TF       RFLIB-TF 4.0.0 requires RFLIB 10.0.0+ and RFLIB-FS 4.0.0+
#   2. Pharos, then RFLIB-PHAROS       RFLIB-PHAROS forwards log events to the pharos__ objects
#   3. Big Object Utility
#   4. Demo source                     Its custom metadata records use RFLIB-FS and RFLIB-TF types
#   5. Permission sets and Apex scripts (pharosPostInstall.apex requires RFLIB-PHAROS)

set -eE

# Third-party AppExchange packages
PHAROS_PACKAGE_ID=04t5a000001g4x9AAA
BIG_OBJECT_UTILITY_PACKAGE_ID=04t7F000003irldQAA
INSTALL_WAIT_MINUTES=30

ORG_ALIAS="${1:-rflib_demo}"

cd "$(dirname "$0")/.."

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

echo "Resolving the latest RFLIB package versions"
resolve_package RFLIB RFLIB
resolve_package RFLIB-FS RFLIB_FS
resolve_package RFLIB-TF RFLIB_TF
resolve_package RFLIB-PHAROS RFLIB_PHAROS

echo "Creating scratch org $ORG_ALIAS"
sf org create scratch --alias "$ORG_ALIAS" --set-default --definition-file config/project-scratch-def.json --duration-days 30

install_package "RFLIB $RFLIB_VERSION" "$RFLIB_ID"
install_package "RFLIB-FS $RFLIB_FS_VERSION" "$RFLIB_FS_ID"
install_package "RFLIB-TF $RFLIB_TF_VERSION" "$RFLIB_TF_ID"
install_package "Pharos" "$PHAROS_PACKAGE_ID"
install_package "RFLIB-PHAROS $RFLIB_PHAROS_VERSION" "$RFLIB_PHAROS_ID"
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
