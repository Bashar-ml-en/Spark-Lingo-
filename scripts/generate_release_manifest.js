#!/usr/bin/env node
/*
 * Creates non-secret, immutable-release evidence from a clean annotated tag.
 *
 * Example (run in CI from the tagged checkout):
 *   node scripts/generate_release_manifest.js \
 *     --tag v1.0.0 \
 *     --output release-evidence/release-manifest.json \
 *     --artifact build/app/outputs/bundle/release/app-release.aab
 *
 * This script deliberately does not create tags, build artifacts, upload
 * files, inspect secret values, or call external services.
 */

'use strict';

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

function fail(message) {
  process.stderr.write(`release-manifest: ${message}\n`);
  process.exitCode = 1;
  throw new Error(message);
}

function usage() {
  process.stdout.write(
    'Usage: node scripts/generate_release_manifest.js --tag <annotated-tag> --output <repo-relative-json> [--artifact <repo-relative-file>]...\n',
  );
}

function parseArguments(argv) {
  const options = { artifacts: [] };
  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === '--help' || argument === '-h') {
      usage();
      process.exit(0);
    }
    if (argument === '--tag' || argument === '--output' || argument === '--artifact') {
      const value = argv[index + 1];
      if (!value || value.startsWith('--')) {
        fail(`${argument} requires a value`);
      }
      index += 1;
      if (argument === '--tag') options.tag = value;
      if (argument === '--output') options.output = value;
      if (argument === '--artifact') options.artifacts.push(value);
      continue;
    }
    fail(`unknown argument ${argument}`);
  }
  if (!options.tag || !options.output) {
    usage();
    fail('--tag and --output are required');
  }
  if (!/^v?[0-9A-Za-z][0-9A-Za-z._-]{0,127}$/.test(options.tag)) {
    fail('tag has an unsupported format');
  }
  return options;
}

function git(args) {
  try {
    return execFileSync('git', args, { encoding: 'utf8' }).trim();
  } catch (_) {
    fail(`git ${args.join(' ')} failed`);
  }
}

function pathWithinRepository(repositoryRoot, candidate, label) {
  if (path.isAbsolute(candidate)) {
    fail(`${label} must be relative to the repository`);
  }
  const resolved = path.resolve(repositoryRoot, candidate);
  const relative = path.relative(repositoryRoot, resolved);
  if (!relative || relative.startsWith(`..${path.sep}`) || path.isAbsolute(relative)) {
    fail(`${label} must name a file inside the repository`);
  }
  return resolved;
}

function sha256File(filePath) {
  const digest = crypto.createHash('sha256');
  digest.update(fs.readFileSync(filePath));
  return digest.digest('hex');
}

function filesRecursively(rootDirectory) {
  if (!fs.existsSync(rootDirectory)) return [];
  const result = [];
  const visit = (directory) => {
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      const entryPath = path.join(directory, entry.name);
      if (entry.isDirectory()) {
        visit(entryPath);
      } else if (entry.isFile()) {
        result.push(entryPath);
      }
    }
  };
  visit(rootDirectory);
  return result.sort((left, right) => left.localeCompare(right));
}

function treeDigest(rootDirectory) {
  const digest = crypto.createHash('sha256');
  const files = filesRecursively(rootDirectory);
  for (const filePath of files) {
    const relative = path.relative(rootDirectory, filePath).replaceAll(path.sep, '/');
    digest.update(relative);
    digest.update('\0');
    digest.update(sha256File(filePath));
    digest.update('\n');
  }
  return { sha256: digest.digest('hex'), fileCount: files.length };
}

function releaseVersion(repositoryRoot) {
  const pubspecPath = path.join(repositoryRoot, 'pubspec.yaml');
  const match = fs.readFileSync(pubspecPath, 'utf8').match(/^version:\s*([^\s#]+)$/m);
  if (!match) fail('pubspec.yaml does not contain a valid version field');
  const [name, build = null] = match[1].trim().split('+', 2);
  return { name, build };
}

function nonSecretConfigurationNames(repositoryRoot) {
  const names = new Set();
  const roots = [
    path.join(repositoryRoot, 'lib'),
    path.join(repositoryRoot, 'supabase', 'functions'),
  ];
  const expression = /(?:Deno\.env\.get|String\.fromEnvironment)\(\s*['\"]([^'\"]+)['\"]/g;
  for (const root of roots) {
    for (const filePath of filesRecursively(root)) {
      if (!/\.(?:dart|ts|js)$/.test(filePath)) continue;
      const source = fs.readFileSync(filePath, 'utf8');
      for (const match of source.matchAll(expression)) {
        names.add(match[1]);
      }
    }
  }
  return [...names].sort();
}

function main() {
  const options = parseArguments(process.argv.slice(2));
  const repositoryRoot = git(['rev-parse', '--show-toplevel']);
  const status = git(['status', '--porcelain=v1']);
  if (status) fail('the checkout is not clean; create the manifest from a clean tagged checkout');

  const tagRef = `refs/tags/${options.tag}`;
  git(['rev-parse', '--verify', tagRef]);
  if (git(['cat-file', '-t', tagRef]) !== 'tag') {
    fail('the release tag must be annotated and immutable');
  }
  const head = git(['rev-parse', 'HEAD']);
  const taggedCommit = git(['rev-list', '-n', '1', options.tag]);
  if (head !== taggedCommit) {
    fail('the supplied tag does not point to the checked-out commit');
  }

  const outputPath = pathWithinRepository(repositoryRoot, options.output, '--output');
  const artifactHashes = options.artifacts.map((artifact) => {
    const artifactPath = pathWithinRepository(repositoryRoot, artifact, '--artifact');
    if (!fs.existsSync(artifactPath) || !fs.statSync(artifactPath).isFile()) {
      fail(`artifact does not exist or is not a file: ${artifact}`);
    }
    return { path: artifact.replaceAll(path.sep, '/'), sha256: sha256File(artifactPath) };
  });

  const migrationsDirectory = path.join(repositoryRoot, 'supabase', 'migrations');
  const migrations = fs.readdirSync(migrationsDirectory)
    .filter((name) => name.endsWith('.sql'))
    .sort((left, right) => left.localeCompare(right))
    .map((name) => ({
      name,
      sha256: sha256File(path.join(migrationsDirectory, name)),
    }));
  if (migrations.length === 0) fail('no Supabase SQL migrations were found');

  const functionsDirectory = path.join(repositoryRoot, 'supabase', 'functions');
  const edgeFunctions = fs.existsSync(functionsDirectory)
    ? fs.readdirSync(functionsDirectory, { withFileTypes: true })
      .filter((entry) => entry.isDirectory())
      .map((entry) => ({ name: entry.name, ...treeDigest(path.join(functionsDirectory, entry.name)) }))
      .sort((left, right) => left.name.localeCompare(right.name))
    : [];

  const manifest = {
    schema_version: 1,
    generated_at: new Date().toISOString(),
    git: {
      annotated_tag: options.tag,
      commit_sha: head,
    },
    application: releaseVersion(repositoryRoot),
    database: {
      latest_migration: migrations[migrations.length - 1].name,
      migrations,
    },
    edge_functions: edgeFunctions,
    artifacts: artifactHashes,
    configuration_names: nonSecretConfigurationNames(repositoryRoot),
    notes: [
      'This manifest intentionally contains configuration names but never configuration values.',
      'Hosted deployment IDs, policy approvals, SBOMs, and dashboard evidence are separate release evidence.',
    ],
  };

  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, `${JSON.stringify(manifest, null, 2)}\n`, 'utf8');
  process.stdout.write(`Wrote ${path.relative(repositoryRoot, outputPath)}\n`);
}

main();
