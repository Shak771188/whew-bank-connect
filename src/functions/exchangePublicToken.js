const plaidClient = require('../lib/plaidClient');
const { savePlaidItem } = require('../lib/dynamo');
const { jsonResponse } = require('../lib/response');

// Called right after the user finishes logging into their bank inside Plaid
// Link. Trades the short-lived public_token for a durable access_token and
// stores it so future transaction pulls don't need the user to log in again.
exports.handler = async (event) => {
  try {
    const body = JSON.parse(event.body || '{}');
    if (!body.public_token) {
      return jsonResponse(400, { error: 'Missing public_token in request body.' });
    }

    const response = await plaidClient.itemPublicTokenExchange({
      public_token: body.public_token,
    });

    await savePlaidItem({
      accessToken: response.data.access_token,
      itemId: response.data.item_id,
    });

    return jsonResponse(200, { success: true });
  } catch (err) {
    console.error('exchangePublicToken failed:', err.response?.data || err.message);
    return jsonResponse(500, { error: 'Could not link that bank account.' });
  }
};
