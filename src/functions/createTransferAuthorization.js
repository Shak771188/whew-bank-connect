const { jsonResponse } = require('../lib/response');
const crypto = require('crypto');

// Mirrors Plaid's real two-step Transfer flow: an authorization/risk-check
// decision has to happen before a transfer can be created. Live Plaid Transfer
// access requires a verified business entity (KYB) that this project doesn't
// have yet, so this endpoint simulates Plaid's authorization response shape
// instead of calling the real API — everything downstream (the two-step
// pattern, the response fields, the decision logic) matches how the real
// integration would work once that's in place.
exports.handler = async (event) => {
  try {
    const body = JSON.parse(event.body || '{}');
    const { amount, goalId } = body;

    if (!amount || amount <= 0) {
      return jsonResponse(400, { error: 'A positive transfer amount is required.' });
    }
    if (!goalId) {
      return jsonResponse(400, { error: 'A goal to contribute toward is required.' });
    }

    // Plaid's authorization can return "approved", "declined", or "user_action_required".
    // A simple, honest stand-in: decline unusually large one-time transfers, approve the rest.
    const decision = amount > 5000 ? 'declined' : 'approved';

    return jsonResponse(200, {
      authorization_id: `authsim-${crypto.randomUUID()}`,
      decision,
      simulated: true,
    });
  } catch (err) {
    console.error('createTransferAuthorization failed:', err.message);
    return jsonResponse(500, { error: 'Could not authorize this transfer.' });
  }
};
