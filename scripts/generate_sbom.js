#!/usr/bin/env node
/*
 * Generate a deterministic CycloneDX dependency inventory from pubspec.lock.
 * It is intentionally dependency-free so a tagged CI checkout can create an
 * SBOM before any external tooling is installed. It records package names and
 * resolved versions only; it never reads environment variables or secrets.
 */

"use strict";

const fs = require("node:fs");
const path = require("node:path");

const repositoryRoot = path.resolve(__dirname, "..");

function usage() {
  return "Usage: node scripts/generate_sbom.js --output <repo-relative-json>";
}

function argumentValue(name) {
  const index = process.argv.indexOf(name);
  if (index === -1 || index + 1 >= process.argv.length) return undefined;
  return process.argv[index + 1];
}

function repositoryPath(value, label) {
  if (!value || path.isAbsolute(value)) {
    throw new Error(`${label} must be a repository-relative path.`);
  }
  const resolved = path.resolve(repositoryRoot, value);
  if (!resolved.startsWith(`${repositoryRoot}${path.sep}`)) {
    throw new Error(`${label} must stay inside the repository.`);
  }
  return resolved;
}

function requiredMatch(source, expression, label) {
  const match = source.match(expression);
  if (!match?.[1]) throw new Error(`Unable to read ${label}.`);
  return match[1].trim();
}

function parsePackages(lockfile) {
  const lines = lockfile.replace(/\r\n/g, "\n").split("\n");
  const components = [];

  for (let index = 0; index < lines.length; index += 1) {
    const packageMatch = lines[index].match(/^  ([A-Za-z0-9_.-]+):\s*$/);
    if (!packageMatch) continue;

    const name = packageMatch[1];
    let version;
    for (let cursor = index + 1; cursor < lines.length; cursor += 1) {
      if (/^  [A-Za-z0-9_.-]+:\s*$/.test(lines[cursor])) break;
      const versionMatch = lines[cursor].match(/^    version:\s*["']?([^"'\s]+)["']?\s*$/);
      if (versionMatch) {
        version = versionMatch[1];
        break;
      }
    }
    if (!version) throw new Error(`No resolved version found for ${name}.`);
    components.push({ type: "library", name, version });
  }

  if (components.length === 0) {
    throw new Error("pubspec.lock did not contain resolved packages.");
  }
  return components.sort((left, right) => left.name.localeCompare(right.name));
}

function main() {
  if (process.argv.includes("--help")) {
    process.stdout.write(`${usage()}\n`);
    return;
  }

  const output = repositoryPath(argumentValue("--output"), "--output");
  const pubspec = fs.readFileSync(path.join(repositoryRoot, "pubspec.yaml"), "utf8");
  const lockfile = fs.readFileSync(path.join(repositoryRoot, "pubspec.lock"), "utf8");
  const appName = requiredMatch(pubspec, /^name:\s*([^\s#]+)\s*$/m, "application name");
  const appVersion = requiredMatch(pubspec, /^version:\s*([^\s#]+)\s*$/m, "application version");

  const sbom = {
    bomFormat: "CycloneDX",
    specVersion: "1.5",
    version: 1,
    metadata: {
      component: { type: "application", name: appName, version: appVersion },
    },
    components: parsePackages(lockfile),
  };

  fs.mkdirSync(path.dirname(output), { recursive: true });
  fs.writeFileSync(output, `${JSON.stringify(sbom, null, 2)}\n`, "utf8");
  process.stdout.write(`Wrote deterministic SBOM with ${sbom.components.length} components.\n`);
}

try {
  main();
} catch (error) {
  process.stderr.write(`SBOM generation failed: ${error.message}\n`);
  process.exitCode = 1;
}
