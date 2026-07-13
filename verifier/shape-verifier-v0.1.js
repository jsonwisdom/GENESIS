// verifier/shape-verifier-v0.1.js
// ITP Shape Law Verifier — Phase 1: schema + fixtures only.
// No trajectory replay, ancestry checks, payload recomputation, or receipt resolution.

'use strict';

const fs = require('fs');
const path = require('path');
const Ajv2020 = require('ajv/dist/2020');
const addFormats = require('ajv-formats');

const ROOT = path.resolve(__dirname, '..');
const SCHEMA_PATH = path.join(ROOT, 'TRAJECTORY_EVENT_V0_1.schema.json');
const NEGATIVE_FIXTURES_PATH = path.join(
  ROOT,
  'fixtures',
  'itp',
  'negative-fixtures-v0.1.json'
);
const POSITIVE_FIXTURES_PATH = path.join(
  ROOT,
  'fixtures',
  'itp',
  'positive-fixtures-v0.1.json'
);

function readJson(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (error) {
    console.error(`FATAL: unable to load JSON: ${filePath}`);
    console.error(error.message);
    process.exit(1);
  }
}

function normalizeErrors(errors) {
  return (errors || [])
    .map((error) => ({
      instancePath: error.instancePath || '',
      schemaPath: error.schemaPath || '',
      keyword: error.keyword || '',
      message: error.message || ''
    }))
    .sort((a, b) => {
      const left = `${a.instancePath}|${a.schemaPath}|${a.keyword}|${a.message}`;
      const right = `${b.instancePath}|${b.schemaPath}|${b.keyword}|${b.message}`;
      return left.localeCompare(right);
    });
}

function validateFixtureSet(validate, fixtures, setName) {
  const results = [];

  for (const fixture of fixtures) {
    const actualValid = Boolean(validate(fixture.data));
    const expectedValid = fixture.expected_valid === true;
    const passed = actualValid === expectedValid;

    results.push({
      set: setName,
      name: fixture.name,
      expected_valid: expectedValid,
      actual_valid: actualValid,
      passed,
      errors: actualValid ? [] : normalizeErrors(validate.errors)
    });
  }

  return results;
}

function runVerifier() {
  const schema = readJson(SCHEMA_PATH);
  const negatives = readJson(NEGATIVE_FIXTURES_PATH);
  const positives = readJson(POSITIVE_FIXTURES_PATH);

  const ajv = new Ajv2020({
    strict: true,
    allErrors: true,
    validateFormats: true
  });
  addFormats(ajv);

  let validate;
  try {
    validate = ajv.compile(schema);
  } catch (error) {
    console.error('FATAL: schema compilation failed');
    console.error(error.message);
    process.exit(1);
  }

  const results = [
    ...validateFixtureSet(validate, negatives, 'negative'),
    ...validateFixtureSet(validate, positives, 'positive')
  ];

  const failures = results.filter((result) => !result.passed);
  const report = {
    verifier: 'ITP_SHAPE_VERIFIER_V0_1',
    scope: 'SHAPE_LAW_ONLY',
    replay_executed: false,
    payload_recomputation_executed: false,
    authority: false,
    fixture_count: results.length,
    passed_count: results.length - failures.length,
    failed_count: failures.length,
    results
  };

  process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);
  process.exit(failures.length === 0 ? 0 : 1);
}

runVerifier();