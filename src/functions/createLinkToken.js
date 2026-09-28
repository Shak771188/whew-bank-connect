const { Products, CountryCode } = require('plaid');
const plaidClient = require('../lib/plaidClient');
const { jsonResponse } = require('../lib/response');

// Called when the user clicks "Connect Bank Account" in WHEW. Returns a
// short-lived link_token that the frontend hands to Plaid Link to open the
// bank-login widget.
exports.handler = async () => {
  try {
    const response = await plaidClient.linkTokenCreate({
      user: { client_user_id: 'demo-user' },
      client_name: 'WHEW Budget',
      products: [Products.Transactions],
      country_codes: [CountryCode.Us],
      language: 'en',
    });

    return jsonResponse(200, { link_token: response.data.link_token });
  } catch (err) {
    console.error('createLinkToken failed:', err.response?.data || err.message);
    return jsonResponse(500, { error: 'Could not create a Plaid link token.' });
  }
};
