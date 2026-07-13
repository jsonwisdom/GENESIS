const fs = require('fs');

function loadFixtures(filePath) {
  const data = fs.readFileSync(filePath, 'utf8');
  return JSON.parse(data);
}

function validateTrajectory(trajectory) {
  if (!Array.isArray(trajectory) || trajectory.length === 0) {
    return { valid: false, error: 'V001_EMPTY_INPUT' };
  }

  const trajIds = new Set(trajectory.map(e => e.trajectory_id));
  if (trajIds.size !== 1) {
    return { valid: false, error: 'V015_TRAJECTORY_MISMATCH' };
  }

  const eventIds = new Set();
  for (const e of trajectory) {
    if (eventIds.has(e.event_id)) return { valid: false, error: 'V003_DUPLICATE_EVENT_ID' };
    eventIds.add(e.event_id);
  }

  const origins = trajectory.filter(e => e.type === 'ORIGIN');
  if (origins.length !== 1) return { valid: false, error: 'V014_INVALID_ORIGIN_COUNT' };
  if (origins[0].sequence !== 1) return { valid: false, error: 'V007_SEQUENCE_NOT_CONTIGUOUS' };

  const seqSet = new Set(trajectory.map(e => e.sequence));
  if (seqSet.size !== trajectory.length || Math.max(...seqSet) !== trajectory.length || Math.min(...seqSet) !== 1) {
    return { valid: false, error: 'V007_SEQUENCE_NOT_CONTIGUOUS' };
  }

  const ordered = [...trajectory].sort((a, b) => a.sequence - b.sequence);
  const byId = new Map(ordered.map(e => [e.event_id, e]));

  const childrenCount = new Map();
  for (const e of ordered) {
    if (e.parent_id) {
      const parent = byId.get(e.parent_id);
      if (!parent) return { valid: false, error: 'V005_PARENT_NOT_FOUND' };
      if (parent.sequence >= e.sequence) return { valid: false, error: 'V006_PARENT_NOT_EARLIER' };
      if (parent.timestamp && e.timestamp && new Date(e.timestamp) < new Date(parent.timestamp)) {
        return { valid: false, error: 'V008_TIMESTAMP_REGRESSION' };
      }
      childrenCount.set(parent.event_id, (childrenCount.get(parent.event_id) || 0) + 1);
      if (childrenCount.get(parent.event_id) > 1) return { valid: false, error: 'V017_FORK_NOT_ALLOWED' };
    }
  }

  return { valid: true };
}

function runVerifier() {
  const positive = loadFixtures('fixtures/itp/state-law/positive-fixtures-v0.1.json');
  const negative = loadFixtures('fixtures/itp/state-law/negative-fixtures-v0.1.json');
  const allFixtures = [...positive, ...negative];

  const results = allFixtures.map(fixture => {
    const result = validateTrajectory(fixture.trajectory);
    const passed = result.valid === fixture.expected_valid && 
      (!fixture.expected_error || result.error === fixture.expected_error);
    return {
      name: fixture.name,
      expected_valid: fixture.expected_valid,
      actual_valid: result.valid,
      expected_error: fixture.expected_error || null,
      actual_error: result.error || null,
      passed
    };
  });

  const passedCount = results.filter(r => r.passed).length;
  const report = {
    verifier: "ITP_STATE_VERIFIER_V0_1",
    scope: "STATE_LAW_ONLY",
    shape_validation_required: true,
    trajectory_count: allFixtures.length,
    passed_count: passedCount,
    failed_count: allFixtures.length - passedCount,
    replay_executed: false,
    payload_recomputation_executed: false,
    authority: false,
    results
  };

  fs.writeFileSync('receipts/itp/state-law/state-verifier-report-v0.1.json', JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report, null, 2));
}

runVerifier();