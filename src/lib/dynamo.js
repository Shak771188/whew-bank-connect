const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, GetCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION || 'us-east-1' });
const docClient = DynamoDBDocumentClient.from(client);
const TABLE = process.env.DYNAMODB_TABLE || 'whew-plaid-items';

// There's no user login system yet, so every item is stored under one fixed
// user id for now. Swap this out for a real user id once auth exists.
const DEMO_USER_ID = 'demo-user';

async function savePlaidItem({ accessToken, itemId }) {
  await docClient.send(
    new PutCommand({
      TableName: TABLE,
      Item: { userId: DEMO_USER_ID, accessToken, itemId, linkedAt: new Date().toISOString() },
    })
  );
}

async function getPlaidItem() {
  const result = await docClient.send(
    new GetCommand({ TableName: TABLE, Key: { userId: DEMO_USER_ID } })
  );
  return result.Item || null;
}

module.exports = { savePlaidItem, getPlaidItem };
