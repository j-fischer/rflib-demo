#!/usr/bin/env node
/*
 * Prints the latest package version ID and version number of an RFLIB package, e.g.
 *
 *   $ node scripts/lib/latestRflibPackage.js RFLIB-FS
 *   04tKY0000005SfyYAE 4.0.0-1
 *
 * The versions are read from the packageAliases of the RFLIB sfdx-project.json, the same
 * source `sf rflib packages upgrade` uses, so no package IDs are hardcoded in this repository.
 * The project file is taken from, in order:
 *   1. the RFLIB_PROJECT_JSON environment variable (a local path or an http(s) URL)
 *   2. ../rflib/sfdx-project.json (a sibling checkout of https://github.com/j-fischer/rflib)
 *   3. the master branch of the RFLIB repository on GitHub
 *
 * Usage: node scripts/lib/latestRflibPackage.js <RFLIB|RFLIB-FS|RFLIB-TF|RFLIB-PHAROS>
 */
'use strict';

const fs = require('node:fs');
const path = require('node:path');

const RFLIB_PROJECT_URL = 'https://raw.githubusercontent.com/j-fischer/rflib/master/sfdx-project.json';
const SIBLING_PROJECT_PATH = path.resolve(__dirname, '..', '..', '..', 'rflib', 'sfdx-project.json');

const PACKAGE_VERSION_ALIAS = /^(?<name>.+)@(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)-(?<build>\d+)$/;
const PACKAGE_VERSION_ID = /^04t(?:[a-zA-Z0-9]{12}|[a-zA-Z0-9]{15})$/;

function fail(message) {
    console.error(`ERROR: ${message}`);
    process.exit(1);
}

function resolveProjectSource() {
    if (process.env.RFLIB_PROJECT_JSON) {
        return process.env.RFLIB_PROJECT_JSON;
    }
    if (fs.existsSync(SIBLING_PROJECT_PATH)) {
        return SIBLING_PROJECT_PATH;
    }
    return RFLIB_PROJECT_URL;
}

async function loadProject(source) {
    if (/^https?:\/\//i.test(source)) {
        const response = await fetch(source);
        if (!response.ok) {
            throw new Error(`HTTP ${response.status} ${response.statusText}`);
        }
        return response.json();
    }
    return JSON.parse(fs.readFileSync(source, 'utf8'));
}

function compareVersions(a, b) {
    return a.major - b.major || a.minor - b.minor || a.patch - b.patch || a.build - b.build;
}

function findLatestVersion(project, packageName) {
    let latest;
    for (const [alias, versionId] of Object.entries(project.packageAliases || {})) {
        const match = PACKAGE_VERSION_ALIAS.exec(alias);
        if (!match || match.groups.name.toLowerCase() !== packageName.toLowerCase()) continue;
        if (typeof versionId !== 'string' || !PACKAGE_VERSION_ID.test(versionId)) continue;

        const version = {
            major: Number(match.groups.major),
            minor: Number(match.groups.minor),
            patch: Number(match.groups.patch),
            build: Number(match.groups.build)
        };
        if (!latest || compareVersions(version, latest.version) > 0) {
            latest = { versionId, version };
        }
    }
    return latest;
}

async function main() {
    const packageName = process.argv[2];
    if (!packageName) {
        fail('Usage: node scripts/lib/latestRflibPackage.js <RFLIB|RFLIB-FS|RFLIB-TF|RFLIB-PHAROS>');
    }

    const source = resolveProjectSource();
    let project;
    try {
        project = await loadProject(source);
    } catch (error) {
        fail(`Unable to read the RFLIB project definition from ${source}: ${error.message}`);
    }

    const latest = findLatestVersion(project, packageName);
    if (!latest) {
        fail(`No released version of package ${packageName} found in ${source}`);
    }

    const { major, minor, patch, build } = latest.version;
    console.log(`${latest.versionId} ${major}.${minor}.${patch}-${build}`);
}

main();
