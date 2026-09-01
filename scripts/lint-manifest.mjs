#!/usr/bin/env node
// Validate narrowstack-core instance manifests against manifest/schema.json.
//
// Usage:
//   node scripts/lint-manifest.mjs [manifest ...]
//   node scripts/lint-manifest.mjs --schema <path> [manifest ...]
//
// With no manifest arguments, every manifest/examples/*.{yaml,yml} file is
// validated. Exits non-zero if any manifest fails schema validation.

import { readFile } from "node:fs/promises";
import { readdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";
import process from "node:process";
import Ajv2020 from "ajv/dist/2020.js";
import addFormats from "ajv-formats";
import { parse as parseYaml } from "yaml";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DEFAULT_SCHEMA = path.join(repoRoot, "manifest", "schema.json");
const EXAMPLES_DIR = path.join(repoRoot, "manifest", "examples");

function parseArgs(argv) {
  const args = { schema: DEFAULT_SCHEMA, manifests: [] };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--schema" || arg === "-s") {
      args.schema = argv[i + 1];
      i += 1;
    } else if (arg === "--help" || arg === "-h") {
      args.help = true;
    } else {
      args.manifests.push(arg);
    }
  }
  return args;
}

function printHelp() {
  process.stdout.write(
    [
      "Validate narrowstack-core instance manifests against a JSON Schema.",
      "",
      "Usage:",
      "  node scripts/lint-manifest.mjs [manifest ...]",
      "  node scripts/lint-manifest.mjs --schema <path> [manifest ...]",
      "",
      "With no manifest arguments, all manifest/examples/*.{yaml,yml} are checked.",
      "",
    ].join("\n"),
  );
}

function discoverExamples() {
  return readdirSync(EXAMPLES_DIR)
    .filter((f) => f.endsWith(".yaml") || f.endsWith(".yml"))
    .sort()
    .map((f) => path.join(EXAMPLES_DIR, f));
}

async function loadValidator(schemaPath) {
  const schema = JSON.parse(await readFile(schemaPath, "utf8"));
  const ajv = new Ajv2020({ allErrors: true, strict: true, strictRequired: false });
  addFormats(ajv);
  return ajv.compile(schema);
}

function formatErrors(errors) {
  if (!errors || errors.length === 0) return "  (unknown validation error)";
  return errors
    .map((e) => {
      const where = e.instancePath || "(root)";
      return `  ${where} ${e.message}`;
    })
    .join("\n");
}

async function validateManifest(validate, manifestPath) {
  const raw = await readFile(manifestPath, "utf8");
  let data;
  try {
    data = parseYaml(raw);
  } catch (err) {
    return { ok: false, reason: `YAML parse error: ${err.message}` };
  }
  const ok = validate(data);
  return { ok, reason: ok ? null : formatErrors(validate.errors) };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    printHelp();
    return 0;
  }

  const manifests = args.manifests.length > 0 ? args.manifests : discoverExamples();
  if (manifests.length === 0) {
    process.stderr.write("No manifests found to validate.\n");
    return 1;
  }

  const validate = await loadValidator(args.schema);
  let failures = 0;

  for (const manifestPath of manifests) {
    const rel = path.relative(repoRoot, manifestPath) || manifestPath;
    const { ok, reason } = await validateManifest(validate, manifestPath);
    if (ok) {
      process.stdout.write(`PASS  ${rel}\n`);
    } else {
      failures += 1;
      process.stdout.write(`FAIL  ${rel}\n${reason}\n`);
    }
  }

  const summary = `\n${manifests.length - failures}/${manifests.length} manifest(s) valid.\n`;
  process.stdout.write(summary);
  return failures === 0 ? 0 : 1;
}

main()
  .then((code) => process.exit(code))
  .catch((err) => {
    process.stderr.write(`lint-manifest: ${err.stack || err.message}\n`);
    process.exit(2);
  });
