# FinFix — Self-Healing Middleware for Agentic Commerce

When AI agents try to shop online, **68% of transactions fail** — broken product pages, anti-bot checkouts, rejected payments. FinFix is the middleware that catches those failures, fixes them autonomously, and settles via USDC stablecoins. No human in the loop.

## What It Does

FinFix sits between AI shopping agents and broken merchant infrastructure. When a transaction fails, it:

1. **Detects** the failure at the merchant endpoint
2. **Classifies** the failure type using MiniMax + Claude AI in real-time
3. **Fixes** it autonomously (scrape data, bypass checkout, reroute payment)
4. **Settles** via USDC on Solana through Crossmint wallets — instant, borderless
5. **Logs** a full audit trail with on-chain transaction hashes

All of this happens in under 3 seconds, orchestrated by n8n workflows.

## The Problem

AI agents are getting good at browsing and shopping, but merchant infrastructure wasn't built for them:

- **Broken product data** — unstructured pages with no API, missing prices, no schema markup
- **Blocked checkouts** — anti-bot walls, CAPTCHAs, and rate limits kill agent-driven purchases
- **Payment rejection** — traditional card processors don't handle programmatic, high-frequency agent purchases

There's no middleware layer between AI agents and merchants. FinFix fills that gap.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              FinFix Pipeline                                        │
│                                                                                     │
│  ┌──────────┐    ┌──────────┐    ┌──────────────┐    ┌─────────────┐               │
│  │ AI Agent │───▶│ n8n      │───▶│ MiniMax +    │───▶│ Fix Router  │               │
│  │          │    │ Webhook  │    │ Claude AI    │    │             │               │
│  │ purchase │    │ POST     │    │ Classifier   │    │ classify &  │               │
│  │ request  │    │ /finfix  │    │              │    │ route       │               │
│  └──────────┘    └──────────┘    └──────────────┘    └──────┬──────┘               │
│                                                             │                       │
│                        ┌────────────────┬──────────────┬────┴────────┐              │
│                        ▼                ▼              ▼             ▼              │
│                  ┌───────────┐   ┌────────────┐ ┌──────────┐  ┌──────────┐         │
│                  │ DATA FIX  │   │ CHECKOUT   │ │ PAYMENT  │  │ ESCALATE │         │
│                  │           │   │ FIX        │ │ FIX      │  │          │         │
│                  │ scrape &  │   │ Crossmint  │ │ USDC     │  │ human    │         │
│                  │ extract   │   │ World Store│ │ rails    │  │ review   │         │
│                  └─────┬─────┘   └─────┬──────┘ └────┬─────┘  └──────────┘         │
│                        │               │             │                              │
│                        └───────────────┴──────┬──────┘                              │
│                                               ▼                                     │
│                                  ┌─────────────────────┐                            │
│                                  │   Crossmint          │                            │
│                                  │   Wallets API        │                            │
│                                  │                      │                            │
│                                  │  Treasury → Fixer    │                            │
│                                  │  Fixer → Escrow      │                            │
│                                  │  Escrow → Fee Pool   │                            │
│                                  │                      │                            │
│                                  │  USDC on Solana      │                            │
│                                  └──────────┬───────────┘                            │
│                                             ▼                                       │
│                                  ┌─────────────────────┐                            │
│                                  │   Settlement         │                            │
│                                  │   + Audit Trail      │                            │
│                                  └─────────────────────┘                            │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Pipeline Flow

1. **AI Agent** sends a purchase request to the n8n webhook
2. **n8n** orchestrates the entire pipeline as a workflow
3. **MiniMax + Claude AI** classify the failure type in real-time
4. **Fix Router** dispatches to the correct autonomous fix
5. **Crossmint** handles wallet operations, checkout, and USDC settlement on Solana
6. **Audit trail** logs every transaction with on-chain hashes

### Three Failure Types, Three Autonomous Fixes

| Failure | What Happens | How FinFix Fixes It |
|---|---|---|
| **Broken Product Data** | Merchant page has no structured data | Scrapes HTML, MiniMax + Claude extract product info, finds Amazon equivalent |
| **Blocked Checkout** | Anti-bot walls block the agent | Reroutes through Crossmint World Store API |
| **Payment Rejected** | Card processor rejects programmatic payment | Settles via USDC on Solana — no chargebacks, instant finality |

## Wallet Architecture

FinFix uses 4 Crossmint smart wallets on Solana for the payment flow:

| Wallet | Role |
|---|---|
| **Treasury** | Master fund pool — auto-tops up fixer when low |
| **Fixer Agent** | Executes purchases on behalf of users |
| **Escrow** | Holds funds during order fulfillment |
| **Fee Collector** | Collects 2% FinFix service fee per transaction |

## Tech Stack

| Layer | Technology |
|---|---|
| **Orchestration** | [n8n](https://n8n.io/) — self-hosted workflow automation, connects every piece |
| **AI Classification** | [MiniMax](https://www.minimax.io/) + Anthropic Claude Sonnet 4.6 — failure detection and intelligent routing |
| **Payments & Wallets** | [Crossmint](https://crossmint.com/) — Wallets API, World Store Checkout, USDC settlement |
| **Blockchain** | Solana (devnet) — USDC stablecoin transfers with on-chain finality |
| **Frontend** | React + Three.js + Tailwind + Cyberpunk HUD Command Center |
| **Dashboard** | Real-time pipeline visualization with transaction monitoring |

## Quick Start

### Prerequisites

- [n8n](https://n8n.io/) self-hosted instance (Docker or npm)
- [Node.js](https://nodejs.org/) 18+
- [Crossmint Console](https://staging.crossmint.com/console) staging account (use promo code **HAC15**)
- Anthropic API key

### Setup

```bash
# Clone and enter
git clone https://github.com/Kush614/agentfix.git
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

### Import n8n Workflows

Import these JSON files into your n8n instance:

1. `n8n-workflows/finfix-main-pipeline.json` — Main purchase pipeline
2. `n8n-workflows/finfix-data-fixer.json` — Product data extraction sub-workflow
3. `n8n-workflows/finfix-balance-monitor.json` — Cron wallet balance monitor
4. `n8n-workflows/finfix-dashboard-data.json` — Dashboard stats API

### Dashboard

Open `dashboard/index.html` in a browser to access the Command Center. It connects to your n8n instance at `http://localhost:5678` by default.

### Test

```bash
bash scripts/test-integration.sh
```

## API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/webhook/finfix/purchase` | Submit a purchase request through the pipeline |
| `GET` | `/webhook/finfix/stats` | Get wallet balances and transaction history |

### Submit a Purchase

```bash
curl -X POST http://localhost:5678/webhook/finfix/purchase \
  -H "Content-Type: application/json" \
  -d '{
    "product_url": "https://www.amazon.com/dp/B09V3KXJPB",
    "quantity": 1,
    "max_price": 30,
    "user_email": "buyer@example.com",
    "agent_id": "agent-001"
  }'
```

## Project Structure

```
.
├── dashboard/              # Cyberpunk HUD Command Center (single-file React)
├── n8n-workflows/          # n8n workflow JSON files
│   ├── finfix-main-pipeline.json
│   ├── finfix-data-fixer.json
│   ├── finfix-balance-monitor.json
│   └── finfix-dashboard-data.json
├── scripts/                # Setup and test scripts
│   ├── generate-keys.sh
│   ├── setup-wallets.sh
│   ├── fund-wallets.sh
│   └── test-integration.sh
└── .env.example            # Environment template
```

## Built For

HAC Vibe Coding Hackathon 2026 — Powered by [Crossmint](https://crossmint.com/), [n8n](https://n8n.io/) & [MiniMax](https://www.minimax.io/)

## License

MIT
