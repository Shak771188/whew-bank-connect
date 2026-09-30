const { jsonResponse } = require('../lib/response');
const { listTransfers } = require('../lib/dynamoTransfers');

// Lets the frontend check current transfer statuses (source of truth lives
// in DynamoDB, updated by transferWebhook.js) so a goal's contributed amount
// only updates once a transfer has actually settled.
exports.handler = async () => {
  try {
    const transfers = await listTransfers();
    return jsonResponse(200, { transfers });
  } catch (err) {
    console.error('getTransfers failed:', err.message);
    return jsonResponse(500, { error: 'Could not fetch transfers.' });
  }
};
