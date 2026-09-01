// Schema validation tests for the instance manifest.
// Run with: npm test  (node --test)

import { test } from "node:test";
import assert from "node:assert/strict";
import { readFile, readdir } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";
import Ajv2020 from "ajv/dist/2020.js";
import addFormats from "ajv-formats";
import { parse as parseYaml } from "yaml";

const here = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(here, "..");
const schemaPath = path.join(repoRoot, "manifest", "schema.json");
const examplesDir = path.join(repoRoot, "manifest", "examples");
const fixturesDir = path.join(here, "fixtures");

async function makeValidator() {
  const schema = JSON.parse(await readFile(schemaPath, "utf8"));
  const ajv = new Ajv2020({ allErrors: true, strict: true, strictRequired: false });
  addFormats(ajv);
  return ajv.compile(schema);
}

async function loadYaml(p) {
  return parseYaml(await readFile(p, "utf8"));
}

test("schema.json is itself valid JSON Schema and compiles", async () => {
  const validate = await makeValidator();
  assert.equal(typeof validate, "function");
});

test("all example manifests are valid", async () => {
  const validate = await makeValidator();
  const files = (await readdir(examplesDir)).filter(
    (f) => f.endsWith(".yaml") || f.endsWith(".yml"),
  );
  assert.ok(files.length >= 2, "expected local and external warehouse examples");
  for (const f of files) {
    const data = await loadYaml(path.join(examplesDir, f));
    const ok = validate(data);
    assert.ok(ok, `${f} should be valid, got: ${JSON.stringify(validate.errors)}`);
  }
});

test("invalid fixtures are all rejected", async () => {
  const validate = await makeValidator();
  const files = (await readdir(fixturesDir)).filter((f) => f.startsWith("invalid-"));
  assert.ok(files.length >= 4, "expected invalid fixtures to be present");
  for (const f of files) {
    const data = await loadYaml(path.join(fixturesDir, f));
    const ok = validate(data);
    assert.equal(ok, false, `${f} should be rejected by the schema`);
  }
});

test("local warehouse without backup is rejected", async () => {
  const validate = await makeValidator();
  const data = await loadYaml(path.join(fixturesDir, "invalid-local-missing-backup.yaml"));
  assert.equal(validate(data), false);
});

test("literal secret value (non op://) is rejected", async () => {
  const validate = await makeValidator();
  const data = await loadYaml(path.join(fixturesDir, "invalid-literal-secret.yaml"));
  assert.equal(validate(data), false);
});
