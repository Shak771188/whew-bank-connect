const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, GetCommand, UpdateCommand, ScanCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: process.env.AWS_REGION || 'us-east-1' });
const docClient = DynamoDBDocumentClient.from(client);
const TABLE = process.env.TRANSFERS_TABLE || 'whew-transfers';

// Same single-user placeholder as dynamo.js — swap for a real user id once auth exists.
const DEMO_USER_ID = 'demo-user';

async function saveTransfer(transfer) {
  await docClient.send(
    new PutCommand({
      TableName: TABLE,
      Item: { userId: DEMO_USER_ID, ...transfer },
    })
  );
}

async function getTransfer(transferId) {
  const result = await docClient.send(
    new GetCommand({ TableName: TABLE, Key: { userId: DEMO_USER_ID, transferId } })
  );
  return result.Item || null;
}

async function updateTransferStatus(transferId, status) {
  await docClient.send(
    new UpdateCommand({
      TableName: TABLE,
      Key: { userId: DEMO_USER_ID, transferId },
      UpdateExpression: 'SET #s = :status, updatedAt = :updatedAt',
      ExpressionAttributeNames: { '#s': 'status' },
      ExpressionAttributeValues: { ':status': status, ':updatedAt': new Date().toISOString() },
    })
  );
}

async function listTransfers() {
  const result = await docClient.send(
    new ScanCommand({
      TableName: TABLE,
      FilterExpression: 'userId = :uid',
      ExpressionAttributeValues: { ':uid': DEMO_USER_ID },
    })
  );
  return result.Items || [];
}

async function findByClientTransferId(clientTransferId) {
  const all = await listTransfers();
  return all.find((t) => t.clientTransferId === clientTransferId) || null;
}

module.exports = { saveTransfer, getTransfer, updateTransferStatus, listTransfers, findByClientTransferId };
