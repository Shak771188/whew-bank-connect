# whew-bank-connect

Serverless AWS backend that connects the WHEW Budget App to real bank accounts
via [Plaid](https://plaid.com), instead of manually uploading CSV exports.

## Architecture

```
Frontend (whew-budget-app)
        │
        ▼
  API Gateway (HTTP API)
        │
   ┌────┼────────────────┐
   ▼    ▼                ▼
create- exchange-   get-
link-   public-      transactions
token   token
   │       │              │
   └───────┴──────┬───────┘
                   ▼
            DynamoDB (whew-plaid-items)
                   │
                   ▼
              Plaid API
```

Three Lambda functions, one DynamoDB table, one API Gateway HTTP API. No
server to keep running, no auth system yet (transactions are stored under a
single "demo-user" row until this app gets real user accounts).

## 1. Get Plaid sandbox credentials (free)

1. Sign up at https://dashboard.plaid.com/signup
2. Go to **Team Settings → Keys** and copy your `client_id` and `sandbox` secret.
   Sandbox gives you fake test banks with realistic transaction data — no
   real bank account needed to build and demo this.

## 2. Deploy the backend

```bash
cd whew-bank-connect/src
npm install          # pulls in the plaid + aws-sdk packages the Lambdas need

cd ../terraform
terraform init
terraform apply \
  -var="plaid_client_id=YOUR_CLIENT_ID" \
  -var="plaid_secret=YOUR_SANDBOX_SECRET"
```

Terraform will print `api_base_url` when it finishes — that's your backend's
URL. Requires AWS credentials configured locally (`aws configure`) with
permission to create Lambda, API Gateway, DynamoDB, and IAM resources.

Tip: instead of passing `-var` flags every time, copy `.env.example` values
into a `terraform/terraform.tfvars` file (already gitignored) as:

```hcl
plaid_client_id = "..."
plaid_secret    = "..."
```

## 3. What each endpoint does

- `POST /create-link-token` — call this when the user clicks "Connect Bank
  Account." Returns a `link_token` for Plaid Link (the bank-login widget) to
  use.
- `POST /exchange-public-token` — call this right after Plaid Link succeeds,
  passing `{ "public_token": "..." }`. Stores the account's access token in
  DynamoDB so future pulls don't need the user to log in again.
- `GET /transactions` — returns the last 30 days of transactions for the
  linked account, in the same shape the CSV importer produces
  (`{ id, date, description, amount, type, imported }`), so the frontend can
  run them through the same `categorize.js` used for CSV imports.

## 4. Frontend integration (in whew-budget-app, separate step)

This repo only covers the backend. Wiring it into the React app means:

1. `npm install react-plaid-link` in `whew-budget-app`.
2. Add a "Connect Bank Account" button that calls `POST /create-link-token`,
   then opens Plaid Link with the returned token.
3. On Plaid Link success, call `POST /exchange-public-token` with the
   `public_token` Plaid Link returns.
4. Call `GET /transactions`, run the results through `categorizeTransaction()`
   from `src/utils/categorize.js`, and merge into `transactions` state the
   same way CSV imports do today.

Ask for this as its own follow-up once the backend is deployed and you can
confirm `GET /transactions` returns Plaid's sandbox test data successfully.

## Notes / next steps

- Sandbox test bank login: username `user_good`, password `pass_good` in
  Plaid Link's search (search for "Platypus Bank" or similar sandbox
  institutions).
- Moving from `sandbox` to real bank data later just means changing
  `plaid_env` to `development` or `production` and using real Plaid keys —
  no code changes needed.
- The Plaid secret currently lives in a Lambda environment variable. AWS
  Secrets Manager is the more production-grade place for it; worth doing
  before this ever handles a real, non-sandbox bank account.
- `demo-user` as a fixed DynamoDB key works for a single-user portfolio demo
  but needs to become a real user id once the app has accounts/auth.
