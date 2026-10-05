#!/bin/bash
#
# Brings an org created with scripts/orgInit.sh up to date.
#
# Usage: scripts/updateOrg.sh [org alias]   (default: rflib_demo)
#
# Upgrades the installed RFLIB packages to their latest versions with "sf rflib packages upgrade"
# and deploys the demo source. Orgs created by older versions of orgInit, which deployed RFLIB as
# unpackaged source, have no RFLIB packages to upgrade; recreate them with scripts/orgInit.sh.

set -e

MIN_PLUGIN_VERSION=0.21.0
INSTALL_WAIT_MINUTES=30

ORG_ALIAS="${1:-rflib_demo}"

cd "$(dirname "$0")/.."

trap 'echo "ERROR: Org update stopped because the previous step failed." >&2' ERR

node scripts/lib/checkPluginVersion.js "$MIN_PLUGIN_VERSION"

echo "Upgrading the RFLIB packages"
sf rflib packages upgrade --target-org "$ORG_ALIAS" --no-prompt --wait "$INSTALL_WAIT_MINUTES"

echo "Deploying the demo source"
sf project deploy start --target-org "$ORG_ALIAS" --ignore-conflicts

sf apex run --target-org "$ORG_ALIAS" --file apex/resetCustomSettings.apex

sf project reset tracking --target-org "$ORG_ALIAS" --no-prompt

echo "Org $ORG_ALIAS is up-to-date"
