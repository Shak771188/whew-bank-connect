const plaidClient = require('../lib/plaidClient');
const { getPlaidItem } = require('../lib/dynamo');
const { jsonResponse } = require('../lib/response');

// Called by the frontend (in place of a CSV upload) to pull real transactions
// for whichever bank account was linked. Returns them in the same shape the
// CSV importer produces, so the rest of the app (categorize.js, Dashboard's
// category totals) doesn't need to know the difference.
exports.handler = async () => {
  try {
    const item = await getPlaidItem();
    if (!item) {
      return jsonResponse(404, { error: 'No bank account linked yet.' });
    }

    const today = new Date();
    const startDate = new Date(today);
    startDate.setDate(startDate.getDate() - 30);
    const toIso = (d) => d.toISOString().slice(0, 10);

    const response = await plaidClient.transactionsGet({
      access_token: item.accessToken,
      start_date: toIso(startDate),
      end_date: toIso(today),
    });

    const transactions = response.data.transactions.map((t) => ({
      id: t.transaction_id,
      date: t.date,
      // Plaid's own category comes through here; the frontend's
      // categorize.js re-sorts it into WHEW's category list for consistency
      // with manually-entered and CSV-imported transactions.
      description: t.name,
      amount: Math.abs(t.amount),
      type: t.amount < 0 ? 'income' : 'expense',
      imported: true,
    }));

    return jsonResponse(200, { transactions });
  } catch (err) {
    console.error('getTransactions failed:', err.response?.data || err.message);
    return jsonResponse(500, { error: 'Could not fetch transactions.' });
  }
};
