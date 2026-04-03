# AgentFix — Self-Healing Middleware for Agentic Commerce

AgentFix is an n8n-orchestrated middleware that sits between AI shopping/finance agents and broken merchant infrastructure. When an agentic transaction fails, AgentFix detects what broke, fixes it autonomously, settles via USDC on Crossmint, and logs a full audit trail.

## Quick Start

### 1. Prerequisites

- [n8n](https://n8n.io/) self-hosted instance (Docker or npm)
- [Node.js](https://nodejs.org/) 18+
- [Crossmint Console](https://staging.crossmint.com/console) staging account (use promo code **HAC15**)
- Anthropic API key

### 2. Setup

```bash
# Clone and enter
cd agentfix

# Copy env and fill in your keys
cp .env.example .env

# Generate Solana keypairs for agent wallets
bash scripts/generate-keys.sh

# Create wallets on Crossmint
bash scripts/setup-wallets.sh

# Fund wallets with test USDC
bash scripts/fund-wallets.sh
```

### 3. Install n8n Crossmint Community Node

```bash
git clone https://github.com/Crossmint/n8n-nodes-crossmint.git
cd n8n-nodes-crossmint
npm install && npm run build
# Link to your n8n instance per https://docs.n8n.io/integrations/creating-nodes/build/
```

### 4. Import n8n Workflows

Import these JSON files into your n8n instance:

1. `n8n-workflows/agentfix-main-pipeline.json` — Main purchase pipeline
2. `n8n-workflows/agentfix-data-fixer.json` — Product data extraction sub-workflow
3. `n8n-workflows/agentfix-balance-monitor.json` — Cron wallet balance monitor

### 5. Dashboard

Open `dashboard/index.html` in a browser. Configure the webhook URL at the top to point to your n8n instance.

### 6. Test

```bash
bash scripts/test-integration.sh
```

## Architecture

```
User/AI Agent → n8n Webhook → Failure Classifier (AI) → Fix Router
                                                           ├─ Data Fix (scrape + extract)
                                                           ├─ Checkout Fix (Crossmint World Store)
                                                           ├─ Payment Fix (USDC settlement)
                                                           └─ Human escalation (Slack)
                                                        → Crossmint (wallets, checkout, settlement)
                                                        → Audit Trail (Google Sheets)
```

## Wallets

| Wallet | Purpose |
|---|---|
| treasury | Master fund pool |
| fixer-agent | Pays for purchases on behalf of users |
| escrow | Holds funds during order fulfillment |
| fee-collector | Collects 2% AgentFix service fee |

## Tech Stack

- **Orchestration:** n8n (self-hosted)
- **Payments:** Crossmint Wallets API + World Store Checkout
- **AI:** Anthropic Claude Sonnet 4.6 via n8n AI Agent nodes
- **Settlement:** USDC on Solana (devnet)
- **Dashboard:** Single-file React + Tailwind + Recharts

## License

MIT
