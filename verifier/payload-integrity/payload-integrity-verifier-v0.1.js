const fs = require('fs');
const crypto = require('crypto');

const FIXTURES =
  'fixtures/itp/payload-integrity/payload-fixtures-v0.1.json';

const REPORT =
  'receipts/itp/payload-integrity/payload-integrity-report-v0.1.json';

function verifyPayload(fixture) {
  const result = {
    valid: false,
    error: null,
    payload_bytes_read: false,
    recomputation_executed: false,
    actual_size: null,
    actual_digest: null
  };

  if (fixture.algorithm !== 'sha256') {
    result.error = 'P002_UNSUPPORTED_DIGEST_ALGORITHM';
    return result;
  }

  if (!fs.existsSync(fixture.payload_path)) {
    result.error = 'P001_PAYLOAD_FILE_NOT_FOUND';
    return result;
  }

  const payload = fs.readFileSync(fixture.payload_path);

  result.payload_bytes_read = true;
  result.actual_size = payload.length;

  if (payload.length !== fixture.expected_size) {
    result.error = 'P003_PAYLOAD_SIZE_MISMATCH';
    return result;
  }

  result.actual_digest = crypto
    .createHash('sha256')
    .update(payload)
    .digest('hex');

  result.recomputation_executed = true;

  if (result.actual_digest !== fixture.expected_digest) {
    result.error = 'P004_PAYLOAD_DIGEST_MISMATCH';
    return result;
  }

  result.valid = true;
  return result;
}

const fixtures = JSON.parse(
  fs.readFileSync(FIXTURES, 'utf8')
);

const results = fixtures.map(fixture => {
  const actual = verifyPayload(fixture);

  const passed =
    actual.valid === fixture.expected_valid &&
    actual.error === fixture.expected_error &&
    actual.payload_bytes_read ===
      fixture.expected_payload_bytes_read &&
    actual.recomputation_executed ===
      fixture.expected_recomputation_executed;

  return {
    name: fixture.name,
    expected_valid: fixture.expected_valid,
    actual_valid: actual.valid,
    expected_error: fixture.expected_error,
    actual_error: actual.error,
    payload_bytes_read: actual.payload_bytes_read,
    recomputation_executed: actual.recomputation_executed,
    actual_size: actual.actual_size,
    actual_digest: actual.actual_digest,
    passed
  };
});

const passedCount =
  results.filter(result => result.passed).length;

const report = {
  verifier: 'ITP_PAYLOAD_INTEGRITY_VERIFIER_V0_1',
  scope: 'RAW_BYTE_PAYLOAD_INTEGRITY_ONLY',
  fixture_count: fixtures.length,
  passed_count: passedCount,
  failed_count: fixtures.length - passedCount,
  raw_buffer_read: true,
  text_decode_executed: false,
  normalization_executed: false,
  payload_recomputation_executed: true,
  payload_execution_executed: false,
  replay_executed: false,
  authority: false,
  results
};

fs.mkdirSync('receipts/itp/payload-integrity', {
  recursive: true
});

fs.writeFileSync(
  REPORT,
  JSON.stringify(report, null, 2) + '\n'
);

console.log(JSON.stringify(report, null, 2));

if (report.failed_count !== 0) {
  process.exitCode = 1;
}
