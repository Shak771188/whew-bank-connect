const crypto = require('crypto');
const { jsonResponse } = require('../lib/response');
const { saveTransfer, findByClientTransferId } = require('../lib/dynamoTransfers');

// Creates the transfer record once authorization has approved it. Simulated
// for the same reason createTransferAuthorization.js is — real Plaid Transfer
// needs a verified business entity this project doesn't have yet — but the
// record shape and the pending -> posted -> settled lifecycle match how a
// real transfer moves through Plaid's system.
exports.handler = async (event) => {
  try {
    const body = JSON.parse(event.body || '{}');
    const { authorization_id: authorizationId, amount, goalId, goalName, clientTransferId } = body;

    if (!authorizationId) {
      return jsonResponse(400, { error: 'A transfer must be authorized before it can be created.' });
    }
    if (!clientTransferId) {
      return jsonResponse(400, { error: 'A clientTransferId is required so retries cannot double-submit.' });
    }

    // Idempotency check: if this exact request already created a transfer
    // (e.g. a retried click or network retry), return the existing one
    // instead of creating a second, duplicate transfer.
    const existing = await findByClientTransferId(clientTransferId);
    if (existing) {
      return jsonResponse(200, existing);
    }

    const transfer = {
      transferId: `trsim-${crypto.randomUUID()}`,
      authorizationId,
      clientTransferId,
      goalId,
      goalName,
      amount,
      status: 'pending',
      simulated: true,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    await saveTransfer(transfer);
    return jsonResponse(201, transfer);
  } catch (err) {
    console.error('createTransfer failed:', err.message);
    return jsonResponse(500, { error: 'Could not create this transfer.' });
  }
};
