# Magic Swap - Project Structure

## Root Directory Structure

```
magic-swap/
├── smart-contracts/          # Sui Move contracts
├── frontend/                 # Web interface
├── docs/                     # Documentation
├── scripts/                  # Deployment & utility scripts
└── README.md
```

---

## 1. Smart Contracts Structure (`smart-contracts/`)

```
smart-contracts/
├── sources/
│   ├── core/
│   │   ├── magic_swap.move           # Main swap logic
│   │   ├── probability_engine.move   # Probability calculation & RNG
│   │   ├── reward_pool.move          # Reward pool management
│   │   └── loss_cap.move             # 20% loss enforcement
│   │
│   ├── modules/
│   │   ├── admin.move                # Admin capabilities
│   │   ├── treasury.move             # Treasury management
│   │   ├── fee_manager.move          # Fee collection & distribution
│   │   └── emergency.move            # Pause/emergency controls
│   │
│   ├── utils/
│   │   ├── math.move                 # Mathematical operations
│   │   ├── randomness.move           # VRF/randomness helpers
│   │   └── events.move               # Event emissions
│   │
│   └── types/
│       ├── swap_types.move           # Swap-related types
│       ├── reward_types.move         # Reward tier types
│       └── user_types.move           # User state types
│
├── tests/
│   ├── core_tests.move               # Core logic tests
│   ├── probability_tests.move        # Probability engine tests
│   ├── edge_case_tests.move          # Edge cases & exploit tests
│   └── integration_tests.move        # Integration tests
│
├── scripts/
│   ├── deploy.sh                     # Deployment script
│   ├── upgrade.sh                    # Upgrade script
│   └── verify.sh                     # Contract verification
│
├── Move.toml                         # Move package config
└── README.md                         # SC documentation
```

---

## 2. Frontend Structure (`frontend/`)

```
frontend/
├── public/
│   ├── assets/
│   │   ├── images/
│   │   ├── icons/
│   │   └── animations/
│   ├── favicon.ico
│   └── manifest.json
│
├── src/
│   ├── components/
│   │   ├── common/
│   │   │   ├── Button/
│   │   │   ├── Modal/
│   │   │   ├── Spinner/
│   │   │   └── Toast/
│   │   │
│   │   ├── layout/
│   │   │   ├── Header/
│   │   │   ├── Footer/
│   │   │   └── Sidebar/
│   │   │
│   │   ├── wallet/
│   │   │   ├── WalletConnect/
│   │   │   ├── WalletInfo/
│   │   │   └── NetworkSwitcher/
│   │   │
│   │   └── swap/
│   │       ├── SwapInterface/        # Main swap UI
│   │       ├── AmountInput/          # Input component
│   │       ├── ProbabilityDisplay/   # Show win chances
│   │       ├── RewardTierCard/       # Reward tier display
│   │       ├── SwapHistory/          # User swap history
│   │       └── ResultModal/          # Swap result display
│   │
│   ├── pages/
│   │   ├── Home/                     # Landing page
│   │   ├── Swap/                     # Main swap page
│   │   ├── Dashboard/                # User dashboard
│   │   ├── Leaderboard/              # Top winners
│   │   ├── HowItWorks/               # Explanation page
│   │   └── Analytics/                # Stats & analytics
│   │
│   ├── hooks/
│   │   ├── useWallet.ts              # Wallet connection hook
│   │   ├── useSwap.ts                # Swap execution hook
│   │   ├── useProbability.ts         # Probability calculation
│   │   ├── useRewards.ts             # Reward fetching
│   │   └── useHistory.ts             # User history hook
│   │
│   ├── services/
│   │   ├── api/
│   │   │   ├── swap.service.ts       # Swap API calls
│   │   │   ├── user.service.ts       # User data API
│   │   │   └── analytics.service.ts  # Analytics API
│   │   │
│   │   └── blockchain/
│   │       ├── sui.client.ts         # Sui client setup
│   │       ├── contract.service.ts   # Contract interactions
│   │       └── transaction.service.ts # TX building & signing
│   │
│   ├── store/
│   │   ├── slices/
│   │   │   ├── walletSlice.ts        # Wallet state
│   │   │   ├── swapSlice.ts          # Swap state
│   │   │   └── userSlice.ts          # User state
│   │   └── store.ts                  # Redux/Zustand store
│   │
│   ├── utils/
│   │   ├── formatters.ts             # Number/date formatters
│   │   ├── validators.ts             # Input validation
│   │   ├── constants.ts              # App constants
│   │   └── helpers.ts                # Helper functions
│   │
│   ├── types/
│   │   ├── swap.types.ts             # Swap-related types
│   │   ├── user.types.ts             # User types
│   │   └── api.types.ts              # API response types
│   │
│   ├── styles/
│   │   ├── globals.css               # Global styles
│   │   ├── variables.css             # CSS variables
│   │   └── theme.ts                  # Theme config
│   │
│   ├── config/
│   │   ├── chains.ts                 # Chain configs
│   │   ├── contracts.ts              # Contract addresses
│   │   └── env.ts                    # Environment variables
│   │
│   ├── App.tsx                       # Root component
│   ├── main.tsx                      # Entry point
│   └── vite-env.d.ts                 # Vite type declarations
│
├── .env.example                      # Environment template
├── .env.development                  # Dev environment
├── .env.production                   # Prod environment
├── .gitignore
├── package.json
├── tsconfig.json
├── vite.config.ts                    # Vite configuration
├── tailwind.config.js                # Tailwind config
└── README.md
```

---

## 3. Documentation Structure (`docs/`)

```
docs/
├── architecture/
│   ├── system-design.md              # Overall architecture
│   ├── smart-contract-design.md      # SC architecture
│   └── frontend-design.md            # FE architecture
│
├── guides/
│   ├── user-guide.md                 # End user guide
│   ├── developer-guide.md            # Developer guide
│   └── deployment-guide.md           # Deployment steps
│
├── technical/
│   ├── probability-mechanics.md      # How probability works
│   ├── loss-cap-mechanism.md         # 20% cap enforcement
│   ├── reward-distribution.md        # Reward logic
│   └── security-considerations.md    # Security audit notes
│
└── api/
    ├── contract-api.md               # Smart contract API
    └── rest-api.md                   # REST API (if any)
```

---

## 4. Scripts Structure (`scripts/`)

```
scripts/
├── deploy/
│   ├── deploy-testnet.sh
│   ├── deploy-mainnet.sh
│   └── verify-deployment.sh
│
├── setup/
│   ├── init-pool.sh                  # Initialize reward pool
│   └── set-parameters.sh             # Set system parameters
│
└── utils/
    ├── check-balance.sh
    └── emergency-pause.sh
```

---

## Key Architecture Notes

### Smart Contract Layer
- **Modular design**: Each module has single responsibility
- **Security first**: Loss cap enforced at contract level
- **Upgradeable**: Admin controls for parameter tuning
- **Event-driven**: All state changes emit events

### Frontend Layer
- **Type-safe**: Full TypeScript
- **Component-based**: Reusable UI components
- **State management**: Centralized state (Redux/Zustand)
- **Wallet integration**: Sui Wallet adapter
- **Real-time updates**: WebSocket for live data

### Critical Files to Focus On

**Smart Contracts:**
1. `magic_swap.move` - Core swap logic
2. `probability_engine.move` - Probability calculation
3. `loss_cap.move` - 20% loss enforcement

**Frontend:**
1. `SwapInterface/` - Main user interaction
2. `useSwap.ts` - Swap execution logic
3. `contract.service.ts` - Blockchain interaction

---

## Development Workflow

1. **Local Development**
   ```
   cd smart-contracts && sui move build
   cd frontend && npm run dev
   ```

2. **Testing**
   ```
   sui move test
   npm run test
   ```

3. **Deployment**
   ```
   ./scripts/deploy/deploy-testnet.sh
   npm run build && npm run deploy
   ```

---

## Tech Stack Recommendations

### Smart Contracts
- Sui Move
- Sui Framework

### Frontend
- React + TypeScript
- Vite (build tool)
- TailwindCSS (styling)
- Zustand/Redux (state)
- @mysten/sui.js (Sui SDK)
- Sui Wallet Kit

### Testing
- Sui Move Test Framework
- Vitest (frontend tests)
- Playwright (E2E tests)

---

