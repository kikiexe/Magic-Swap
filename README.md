# Magic Swap 🎲

> A provably fair, blockchain-based gaming protocol built on Sui Network

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Sui Network](https://img.shields.io/badge/Sui-Network-blue)](https://sui.io)
[![Tests](https://img.shields.io/badge/tests-60%2F60%20passing-brightgreen)](./TEST_RESULTS.md)
[![Security](https://img.shields.io/badge/security-8.5%2F10-green)](./SECURITY_ANALYSIS.md)

Magic Swap is a next-generation gaming protocol that combines transparent probability mechanics with blockchain security. Players can participate in a provably fair game where outcomes are determined by on-chain randomness, with built-in protections for both players and the house.

---

## 🌟 Features

### **For Players**

- 🎯 **Provably Fair** - All outcomes verifiable on-chain
- 💰 **60% Loss Refund** - Get 60% back even when you lose
- 🎁 **Multiple Win Tiers** - From small wins (1.05x) to miracles (9x)
- 🔒 **Safety Guaranteed** - Smart contract enforces all rules
- ⚡ **Instant Payouts** - No waiting, no manual processing

### **For the House**

- 📊 **Sustainable Economics** - ~4.75% house edge + 1% operational fee
- 🛡️ **Treasury Protection** - 10% safety cap prevents bankruptcy
- 🚨 **Emergency Controls** - Auto-pause when treasury critically low
- 📈 **Dynamic Odds** - Adjusts based on treasury health
- 🔐 **Anti-Spam Protection** - 2-epoch cooldown prevents RNG manipulation

---

## 🎲 How It Works

### **Probability Distribution**

| Outcome       | Probability | Multiplier | Example (100 SUI bet) |
| ------------- | ----------- | ---------- | --------------------- |
| 🔴 Loss       | 55.0%       | 0.60x      | Get 59.4 SUI back     |
| 🟢 Small Win  | 35.0%       | 1.05x      | Win 103.95 SUI        |
| 🟡 Medium Win | 8.0%        | 1.50x      | Win 148.5 SUI         |
| 🟠 Jackpot    | 1.5%        | 6.00x      | Win 594 SUI           |
| 🔵 Miracle    | 0.5%        | 9.00x      | Win 891 SUI           |

_All payouts subject to 1% operational fee and 10% treasury safety cap_

### **Game Flow**

```
1. Player submits bet (1-1000 SUI)
   ↓
2. 1% fee deducted for operations
   ↓
3. Safety check: Can treasury cover max possible win?
   ↓
4. On-chain random number generated (0-999)
   ↓
5. Outcome calculated based on probability distribution
   ↓
6. Safety cap applied (max profit = 10% of treasury)
   ↓
7. Payout transferred to player
   ↓
8. Stats updated, cooldown enforced
```

---

## 🏗️ Architecture

### **Smart Contract Modules**

```
smart-contracts/
├── sources/
│   ├── core/
│   │   ├── magic_swap.move          # Main game logic
│   │   ├── probability_engine.move  # Outcome calculation
│   │   ├── reward_pool.move         # Reward management
│   │   └── dynamic_odds.move        # Treasury-based odds
│   │
│   ├── modules/
│   │   ├── admin.move               # Admin capabilities
│   │   ├── treasury.move            # Safety cap enforcement
│   │   ├── fee_manager.move         # Fee collection
│   │   ├── emergency.move           # Pause controls
│   │   └── user_stats.move          # Player statistics
│   │
│   └── utils/
│       ├── math.move                # Math operations
│       ├── randomness.move          # RNG helpers
│       └── events.move              # Event emissions
│
└── tests/                           # 60 comprehensive tests
```

### **Frontend Stack**

```
frontend/
├── src/
│   ├── components/
│   │   ├── swap/                    # Game interface
│   │   ├── wallet/                  # Wallet integration
│   │   └── common/                  # Reusable components
│   │
│   ├── hooks/                       # React hooks
│   ├── services/                    # API & blockchain
│   └── store/                       # State management
│
└── public/                          # Static assets
```

---

## 🚀 Quick Start

### **Prerequisites**

- [Sui CLI](https://docs.sui.io/build/install) (v1.0.0+)
- [Node.js](https://nodejs.org/) (v18+)
- [pnpm](https://pnpm.io/) or npm

### **Installation**

```bash
# Clone repository
git clone https://github.com/yourusername/magic-swap.git
cd magic-swap

# Install smart contract dependencies
cd smart-contracts
sui move build

# Install frontend dependencies
cd ../frontend
pnpm install
```

### **Testing**

```bash
# Run smart contract tests
cd smart-contracts
sui move test

# Expected output:
# Test result: OK. Total tests: 60; passed: 60; failed: 0

# Run frontend tests
cd ../frontend
pnpm test
```

### **Local Development**

```bash
# Start local Sui network
sui start

# Deploy contracts to local network
cd smart-contracts
sui client publish --gas-budget 100000000

# Start frontend dev server
cd ../frontend
pnpm dev
```

---

## 📊 Validation & Testing

### **Test Coverage: 100%**

```
✅ 60/60 tests passing
✅ 10,000 games stress tested
✅ Security analysis complete
✅ Zero reentrancy vulnerabilities
```

### **Stress Test Results**

```
Games Simulated:     10,000
Initial Treasury:    10,000 SUI
Final Treasury:      17,202 SUI
House Profit:        +72.03%
House Edge:          8.02% (includes 1% fee)
Outcome Accuracy:    All within 3% of expected
```

See [TEST_RESULTS.md](./TEST_RESULTS.md) for detailed validation report.

---

## 🔒 Security

### **Security** 

**Recent Security Audit (2026-02-05):**

- ✅ **"Miracle Drain" Vulnerability Fixed** - Pre-flight house balance validation
- ✅ **Error Code Standardization** - Descriptive error constants
- ✅ **RewardPool Secured** - Withdraw functions implemented
- ✅ **All 60/60 Tests Passing** - 100% test coverage maintained

**Protections:**

- ✅ **Reentrancy Safe** - Move's built-in protection
- ✅ **Cooldown Mechanism** - Prevents RNG spam (2 epochs)
- ✅ **Safety Cap** - Limits max payout to 10% of treasury
- ✅ **Pre-flight Checks** - Validates house can cover worst-case payout BEFORE processing
- ✅ **Emergency Pause** - Auto-pause when treasury < 10 SUI
- ✅ **Conservative Validation** - Checks against gross wager (before fee deduction)

**Audits:**

- ✅ **Senior Sui Developer Audit** - Completed 2026-02-05, all critical fixes implemented
- ⏳ External audit pending (scheduled before mainnet)

**Security Documentation:**

- [Security Audit Report](./.md/SECURITY_AUDIT.md) - Complete audit findings
- [Security Fixes Log](./.md/SECURITY_FIXES.md) - Implementation details
- [Before/After Comparison](./.md/BEFORE_AFTER_COMPARISON.md) - Code improvements

---

## 📈 Economics

### **House Edge Breakdown**

```
Probability Edge:  4.75% (from game mechanics)
Operational Fee:   1.00% (deducted from wagers)
Total Edge:        ~5.75-8.00% (varies by bet size)
```

### **Revenue Distribution**

```
Player Losses (40% of 55%):  22.00%
Player Wins (small):         -1.75%
Player Wins (medium):        -4.00%
Player Wins (jackpot):       -7.50%
Player Wins (miracle):       -4.00%
Operational Fee:             +1.00%
─────────────────────────────────
Net House Edge:              ~5.75%
```

### **Treasury Management**

- **Initial Funding:** Recommended 10,000+ SUI
- **Safety Cap:** Max 10% payout per game
- **Auto-Pause:** Triggers at < 10 SUI
- **Dynamic Odds:** Adjusts when treasury low

---

## 🛠️ Configuration

### **Game Parameters**

```move
// In magic_swap.move
MIN_WAGER: 1 SUI (1_000_000_000 MIST)
MAX_WAGER: 1000 SUI (1_000_000_000_000 MIST)
FEE_RATE: 1% (100 basis points)
SAFETY_CAP: 10% of treasury
COOLDOWN: 2 epochs (~4 seconds)
```

### **Probability Thresholds**

```move
// In probability_engine.move
LOSS_RANGE:       0-549   (55.0%)
SMALL_WIN_RANGE:  550-899 (35.0%)
MEDIUM_WIN_RANGE: 900-979 (8.0%)
JACKPOT_RANGE:    980-994 (1.5%)
MIRACLE_RANGE:    995-999 (0.5%)
```

### **Emergency Thresholds**

```move
// In emergency.move & dynamic_odds.move
EMERGENCY_PAUSE:  10 SUI
LOW_TREASURY:     1 SUI (conservative mode)
MEDIUM_TREASURY:  10 SUI (normal mode)
HIGH_TREASURY:    100 SUI (generous mode)
```

---

## 📚 Documentation

### **Security & Audit**

- [Security Audit Report](./.md/SECURITY_AUDIT.md) - Complete security audit findings
- [Security Fixes Log](./.md/SECURITY_FIXES.md) - Implementation details and testing
- [Before/After Comparison](./.md/BEFORE_AFTER_COMPARISON.md) - Code improvements
- [Implementation Summary](./.md/IMPLEMENTATION_SUMMARY.md) - Overview of all changes

### **Economics & Analysis**

- [Loss Tier Economics](./.md/LOSS_TIER_ECONOMICS.md) - Mathematical analysis and recommendations

### **Deployment**

- [Deployment Guide](./.md/DEPLOYMENT_GUIDE.md) - Step-by-step deployment instructions

### **Legacy Documentation**

- [Critical Fixes Applied](./.md/CRITICAL_FIXES_APPLIED.md) - Previous improvements
- [Changes Reference](./.md/CHANGES_REFERENCE.md) - Quick reference guide
- [Mission Accomplished](./.md/MISSION_ACCOMPLISHED.md) - Development summary

---

## 🗺️ Roadmap

### **Phase 1: Foundation** ✅

- [x] Core smart contracts
- [x] Probability engine
- [x] Safety mechanisms
- [x] Comprehensive testing (60/60 tests)
- [x] Security analysis

### **Phase 2: Testnet** 🚧

- [ ] Multi-sig implementation
- [ ] Testnet deployment
- [ ] 1 week monitoring
- [ ] Bug fixes & optimizations

### **Phase 3: Audit** ⏳

- [ ] External security audit
- [ ] Address audit findings
- [ ] Bug bounty program
- [ ] Insurance fund setup

### **Phase 4: Mainnet** 🎯

- [ ] Mainnet deployment
- [ ] Frontend launch
- [ ] Marketing campaign
- [ ] Community building

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](./CONTRIBUTING.md) for details.

### **Development Workflow**

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests (`sui move test`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### **Code Standards**

- Follow [Move Style Guide](https://move-language.github.io/move/coding-conventions.html)
- Write comprehensive tests for new features
- Update documentation for API changes
- Ensure all tests pass before submitting PR

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

---

## ⚠️ Disclaimer

**This is experimental software. Use at your own risk.**

- Smart contracts are audited but not guaranteed bug-free
- Cryptocurrency gaming involves financial risk
- Only bet what you can afford to lose
- Check local regulations before participating
- Past performance does not guarantee future results

---

<div align="center">

**Built with ❤️ on Sui Network**

[Documentation](./docs) • [Security](./SECURITY_ANALYSIS.md) • [Tests](./TEST_RESULTS.md) • [Roadmap](#-roadmap)

</div>
