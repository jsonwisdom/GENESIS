const fs = require('fs');

function loadFixtures(filePath) {
  const data = fs.readFileSync(filePath, 'utf8');
  return JSON.parse(data);
}

function isCanonicalTimestamp(value) {
  if (typeof value !== 'string') return false;
  const pattern =
    /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{3})?Z$/;
  return pattern.test(value) && Number.isFinite(Date.parse(value));
}

function validateState(trajectory) {
  if (!Array.isArray(trajectory) || trajectory.length === 0) {
    return { valid: false, error: 'V001_EMPTY_INPUT' };
  }

  const trajectoryIds = new Set(trajectory.map(event => event.trajectory_id));
  if (trajectoryIds.size !== 1) {
    return { valid: false, error: 'V016_TRAJECTORY_ID_MISMATCH' };
  }

  const eventIds = new Set();
  for (const event of trajectory) {
    if (eventIds.has(event.event_id)) {
      return { valid: false, error: 'V003_DUPLICATE_EVENT_ID' };
    }
    eventIds.add(event.event_id);
  }

  for (const event of trajectory) {
    if (!isCanonicalTimestamp(event.timestamp)) {
      return { valid: false, error: 'V015_INVALID_TIMESTAMP_FORMAT' };
    }
  }

  const origins = trajectory.filter(event => event.type === 'ORIGIN');
  if (origins.length !== 1) {
    return { valid: false, error: 'V014_INVALID_ORIGIN_COUNT' };
  }
  if (origins[0].sequence !== 1) {
    return { valid: false, error: 'V007_SEQUENCE_NOT_CONTIGUOUS' };
  }

  const sequences = trajectory.map(event => event.sequence);
  const sequenceSet = new Set(sequences);
  if (
    sequenceSet.size !== trajectory.length ||
    Math.min(...sequences) !== 1 ||
    Math.max(...sequences) !== trajectory.length
  ) {
    return { valid: false, error: 'V007_SEQUENCE_NOT_CONTIGUOUS' };
  }

  const ordered = [...trajectory].sort((a, b) => a.sequence - b.sequence);
  const byId = new Map(ordered.map(event => [event.event_id, event]));
  const childCounts = new Map();

  for (const event of ordered) {
    if (!event.parent_id) continue;

    const parent = byId.get(event.parent_id);
    if (!parent) {
      return { valid: false, error: 'V005_PARENT_NOT_FOUND' };
    }
    if (parent.sequence >= event.sequence) {
      return { valid: false, error: 'V006_PARENT_NOT_EARLIER' };
    }
    if (Date.parse(event.timestamp) < Date.parse(parent.timestamp)) {
      return { valid: false, error: 'V008_TIMESTAMP_REGRESSION' };
    }

    childCounts.set(parent.event_id, (childCounts.get(parent.event_id) || 0) + 1);
    if (childCounts.get(parent.event_id) > 1) {
      return { valid: false, error: 'V017_FORK_NOT_ALLOWED' };
    }
  }

  return {
    valid: true,
    ordered,
    canonical_event_ids: ordered.map(event => event.event_id)
  };
}

function replayTrajectory(trajectory, requestedTrace = null) {
  const stateResult = validateState(trajectory);
  if (!stateResult.valid) {
    return {
      verdict: 'REPLAY_REJECTED',
      reason: 'STATE_PREREQUISITE_FAILED',
      state_validation_result: 'FAIL',
      state_error: stateResult.error,
      trace: [],
      trace_emitted: false,
      replay_executed: false,
      payload_bytes_read: false,
      payload_recomputation_executed: false,
      authority: false
    };
  }

  const canonicalOrder = stateResult.canonical_event_ids;
  const suppliedOrder = trajectory.map(event => event.event_id);

  if (!requestedTrace && JSON.stringify(suppliedOrder) !== JSON.stringify(canonicalOrder)) {
    return {
      verdict: 'REPLAY_REJECTED',
      reason: 'TRACE_ORDER_MISMATCH',
      state_validation_result: 'PASS',
      canonical_event_ids: canonicalOrder,
      supplied_event_ids: suppliedOrder,
      trace: [],
      trace_emitted: false,
      replay_executed: true,
      payload_bytes_read: false,
      payload_recomputation_executed: false,
      authority: false
    };
  }

  const byId = new Map(trajectory.map(event => [event.event_id, event]));
  const traversal = requestedTrace || suppliedOrder;
  const trace = [];

  for (let index = 0; index < traversal.length; index += 1) {
    const eventId = traversal[index];
    const event = byId.get(eventId);
    const previousId = index > 0 ? traversal[index - 1] : null;

    if (!event) {
      trace.push({
        step: index + 1,
        event_id: eventId,
        transition: previousId ? `${previousId}→${eventId}` : 'START',
        status: 'MISSING'
      });
      return {
        verdict: 'REPLAY_REJECTED',
        reason: 'TRANSITION_CONTINUITY_BROKEN',
        state_validation_result: 'PASS',
        canonical_event_ids: canonicalOrder,
        failure_transition: {
          from_event_id: previousId,
          to_event_id: eventId,
          required_parent_id: null,
          actual_parent_id: null
        },
        trace,
        trace_emitted: true,
        accepted_step_count: trace.filter(step => step.status === 'ACCEPTED').length,
        replay_executed: true,
        payload_bytes_read: false,
        payload_recomputation_executed: false,
        authority: false
      };
    }

    const step = {
      step: index + 1,
      event_id: eventId,
      type: event.type,
      sequence: event.sequence,
      parent_id: event.parent_id || null,
      transition: previousId ? `${previousId}→${eventId}` : 'START',
      status: 'ACCEPTED'
    };

    if (index > 0 && event.parent_id !== previousId) {
      step.status = 'REJECTED';
      trace.push(step);
      return {
        verdict: 'REPLAY_REJECTED',
        reason: 'TRANSITION_CONTINUITY_BROKEN',
        state_validation_result: 'PASS',
        canonical_event_ids: canonicalOrder,
        failure_transition: {
          from_event_id: previousId,
          to_event_id: eventId,
          required_parent_id: event.parent_id || null,
          actual_parent_id: event.parent_id || null
        },
        trace,
        trace_emitted: true,
        accepted_step_count: trace.filter(item => item.status === 'ACCEPTED').length,
        replay_executed: true,
        payload_bytes_read: false,
        payload_recomputation_executed: false,
        authority: false
      };
    }

    trace.push(step);
  }

  return {
    verdict: 'REPLAY_VALID',
    reason: null,
    state_validation_result: 'PASS',
    canonical_event_ids: canonicalOrder,
    ordered_event_ids: canonicalOrder,
    ordered_types: stateResult.ordered.map(event => event.type),
    transition_count: Math.max(0, traversal.length - 1),
    start_event_id: traversal[0] || null,
    end_event_id: traversal[traversal.length - 1] || null,
    trace,
    trace_emitted: true,
    replay_executed: true,
    payload_bytes_read: false,
    payload_recomputation_executed: false,
    authority: false
  };
}

function compareFixture(fixture, actual) {
  const expected = fixture.expected;
  const checks = {
    state_validation_result: actual.state_validation_result === (expected.state_validation_result || expected.state_prerequisite),
    verdict: actual.verdict === expected.verdict,
    reason: expected.reason === undefined || actual.reason === expected.reason,
    state_error: expected.state_error === undefined || actual.state_error === expected.state_error,
    replay_executed: expected.replay_executed === undefined || actual.replay_executed === expected.replay_executed,
    trace_emitted: expected.trace_emitted === undefined || actual.trace_emitted === expected.trace_emitted,
    payload_bytes_read: actual.payload_bytes_read === expected.payload_bytes_read,
    payload_recomputation_executed: actual.payload_recomputation_executed === expected.payload_recomputation_executed,
    authority: actual.authority === expected.authority
  };

  if (expected.ordered_event_ids) {
    checks.ordered_event_ids = JSON.stringify(actual.ordered_event_ids) === JSON.stringify(expected.ordered_event_ids);
  }
  if (expected.ordered_types) {
    checks.ordered_types = JSON.stringify(actual.ordered_types) === JSON.stringify(expected.ordered_types);
  }
  if (expected.canonical_event_ids) {
    checks.canonical_event_ids = JSON.stringify(actual.canonical_event_ids) === JSON.stringify(expected.canonical_event_ids);
  }
  if (expected.supplied_event_ids) {
    checks.supplied_event_ids = JSON.stringify(actual.supplied_event_ids) === JSON.stringify(expected.supplied_event_ids);
  }
  if (expected.transition_count !== undefined) {
    checks.transition_count = actual.transition_count === expected.transition_count;
  }
  if (expected.start_event_id !== undefined) {
    checks.start_event_id = actual.start_event_id === expected.start_event_id;
  }
  if (expected.end_event_id !== undefined) {
    checks.end_event_id = actual.end_event_id === expected.end_event_id;
  }
  if (expected.accepted_step_count !== undefined) {
    checks.accepted_step_count = actual.accepted_step_count === expected.accepted_step_count;
  }
  if (expected.failure_transition) {
    checks.failure_transition = JSON.stringify(actual.failure_transition) === JSON.stringify(expected.failure_transition);
  }

  return {
    passed: Object.values(checks).every(Boolean),
    checks
  };
}

function runVerifier() {
  const positive = loadFixtures('fixtures/itp/trajectory-replay/replay-positive-fixtures-v0.1.json');
  const negative = loadFixtures('fixtures/itp/trajectory-replay/replay-negative-fixtures-v0.1.json');
  const fixtures = [...positive, ...negative];

  const results = fixtures.map(fixture => {
    const actual = replayTrajectory(fixture.trajectory, fixture.requested_trace || null);
    const comparison = compareFixture(fixture, actual);
    return {
      name: fixture.name,
      passed: comparison.passed,
      checks: comparison.checks,
      actual
    };
  });

  const passedCount = results.filter(result => result.passed).length;
  const report = {
    verifier: 'ITP_TRAJECTORY_REPLAY_VERIFIER_V0_1',
    scope: 'SINGLE_TRAJECTORY_REPLAY_ONLY',
    state_validation_required: true,
    fixture_count: fixtures.length,
    passed_count: passedCount,
    failed_count: fixtures.length - passedCount,
    replay_executed: true,
    payload_bytes_read: false,
    payload_recomputation_executed: false,
    authority: false,
    results
  };

  fs.mkdirSync('receipts/itp/trajectory-replay', { recursive: true });
  fs.writeFileSync(
    'receipts/itp/trajectory-replay/replay-report-v0.1.json',
    `${JSON.stringify(report, null, 2)}\n`
  );
  console.log(JSON.stringify(report, null, 2));
  process.exitCode = report.failed_count === 0 ? 0 : 1;
}

runVerifier();
