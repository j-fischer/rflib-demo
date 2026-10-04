#!/usr/bin/env node
/*
 * Fails unless the installed rflib-plugin is at least the given version.
 *
 * Usage: node scripts/lib/checkPluginVersion.js <minVersion>
 */
'use strict';

const { execSync } = require('node:child_process');

const PLUGIN_NAME = 'rflib-plugin';

function fail(message) {
    console.error(`ERROR: ${message}`);
    process.exit(1);
}

function parseVersion(version) {
    const parts = String(version).split('-')[0].split('.').map(Number);
    return [parts[0] || 0, parts[1] || 0, parts[2] || 0];
}

function compareVersions(a, b) {
    const left = parseVersion(a);
    const right = parseVersion(b);
    return left[0] - right[0] || left[1] - right[1] || left[2] - right[2];
}

const minVersion = process.argv[2];
if (!minVersion) {
    fail('Usage: node scripts/lib/checkPluginVersion.js <minVersion>');
}

let output;
try {
    output = execSync('sf plugins --json', {
        encoding: 'utf8',
        maxBuffer: 64 * 1024 * 1024,
        stdio: ['ignore', 'pipe', 'ignore']
    });
} catch (error) {
    fail(`Unable to list the installed Salesforce CLI plugins. Is the sf CLI installed? (${error.message})`);
}

let plugins;
try {
    const parsed = JSON.parse(output);
    plugins = Array.isArray(parsed) ? parsed : parsed.result || [];
} catch (error) {
    fail(`Unable to parse the output of 'sf plugins --json': ${error.message}`);
}

const plugin = plugins.find((p) => p.name === PLUGIN_NAME);
if (!plugin) {
    fail(`${PLUGIN_NAME} is not installed. Install it with: sf plugins install ${PLUGIN_NAME}`);
}

if (compareVersions(plugin.version, minVersion) < 0) {
    fail(
        `${PLUGIN_NAME} ${plugin.version} is installed, but this demo requires ${minVersion} or later. ` +
            `Update it with: sf plugins install ${PLUGIN_NAME}@latest`
    );
}

console.log(`Found ${PLUGIN_NAME} ${plugin.version} (requires >= ${minVersion})`);

if (plugin.type === 'link') {
    // A linked plugin reports the version from its package.json, but runs its compiled lib folder.
    console.warn(
        `WARNING: ${PLUGIN_NAME} is linked from ${plugin.root || 'a local checkout'}. ` +
            'Make sure it is compiled (yarn build), otherwise older behavior may run despite the version above.'
    );
}
