const { jsonResponse } = require('../lib/response');
const { updateTransferStatus, getTransfer } = require('../lib/dynamoTransfers');

// This is the real shape of what Plaid would call in production: an
// unauthenticated endpoint Plaid's servers POST to as a transfer's status
// changes, separate from anything the frontend calls directly. Since live
// Transfer access needs business verification this project doesn't have
// yet, the frontend calls this endpoint itself on a short delay to stand in
// for Plaid — but the handler code here is exactly what would run if Plaid
// were calling it for real.
exports.handler = async (event) => {
  try {
    const body = JSON.parse(event.body || '{}');
    const { transfer_id: transferId, status } = body;

    if (!transferId || !status) {
      return jsonResponse(400, { error: 'transfer_id and status are required.' });
    }

    const transfer = await getTransfer(transferId);
    if (!transfer) {
      return jsonResponse(404, { error: 'Unknown transfer_id.' });
    }

    await updateTransferStatus(transferId, status);
    return jsonResponse(200, { transferId, status });
  } catch (err) {
    console.error('transferWebhook failed:', err.message);
    return jsonResponse(500, { error: 'Could not process transfer status update.' });
  }
};
