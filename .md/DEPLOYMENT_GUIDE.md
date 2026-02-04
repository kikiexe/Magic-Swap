# 🚀 Magic Swap Deployment Guide

**Quick Reference for Testnet & Mainnet Deployment**

---

## 📋 Pre-Deployment Checklist

### Code Quality

- [x] All security fixes implemented
- [x] Error codes standardized
- [x] Constants defined
- [x] RewardPool secured
- [x] 60/60 tests passing

### Documentation

- [x] Security audit report
- [x] Implementation summary
- [x] Economic analysis
- [x] Before/after comparison

### Pending Decisions

- [ ] Loss tier percentage (60% vs 50%)
- [ ] Initial house balance
- [ ] Max wager limits
- [ ] Monitoring setup

---

## 🧪 Testnet Deployment

### Step 1: Build & Test

```bash
cd smart-contracts

# Run full test suite
sui move test

# Expected output: Test result: OK. Total tests: 60; passed: 60; failed: 0

# Build the package
sui move build
```

### Step 2: Deploy to Testnet

```bash
# Set network to testnet
sui client switch --env testnet

# Check active address
sui client active-address

# Fund your address from faucet
# Visit: https://faucet.testnet.sui.io/

# Publish the package
sui client publish --gas-budget 100000000
```

**Expected Output:**

```
Transaction Digest: <digest>
Published Objects:
- PackageID: 0x...
- AdminCap: 0x...
- EmergencyStatus: 0x...
- UserStatsRegistry: 0x...
```

**⚠️ IMPORTANT:** Save these object IDs!

### Step 3: Initialize Game

```bash
# Create GameHouse for SUI token
sui client call \
  --package <PACKAGE_ID> \
  --module game \
  --function create_game \
  --type-args 0x2::sui::SUI \
  --args <ADMIN_CAP_ID> \
  --gas-budget 10000000
```

**Expected Output:**

```
Created Objects:
- GameHouse<SUI>: 0x...
- FeeVault<SUI>: 0x...
```

### Step 4: Fund the House

```bash
# Deposit initial liquidity (e.g., 100 SUI for testing)
sui client call \
  --package <PACKAGE_ID> \
  --module game \
  --function deposit \
  --type-args 0x2::sui::SUI \
  --args <GAME_HOUSE_ID> <COIN_OBJECT_ID> \
  --gas-budget 10000000
```

### Step 5: Configure Limits

```bash
# Update min/max wager (optional)
# Min: 0.1 SUI (100000000 MIST)
# Max: 10 SUI (10000000000 MIST)
sui client call \
  --package <PACKAGE_ID> \
  --module game \
  --function update_config \
  --type-args 0x2::sui::SUI \
  --args <ADMIN_CAP_ID> <GAME_HOUSE_ID> 100000000 10000000000 \
  --gas-budget 10000000
```

### Step 6: Test Play

```bash
# Make a test bet (1 SUI)
sui client call \
  --package <PACKAGE_ID> \
  --module game \
  --function play \
  --type-args 0x2::sui::SUI \
  --args <GAME_HOUSE_ID> <FEE_VAULT_ID> <USER_STATS_REGISTRY_ID> <EMERGENCY_STATUS_ID> 0x8 <COIN_OBJECT_ID> \
  --gas-budget 10000000
```

**Note:** `0x8` is the Random object on Sui

---

## 🌐 Mainnet Deployment

### Pre-Mainnet Checklist

- [ ] Testnet tested for 2-4 weeks
- [ ] Volume data collected
- [ ] Economic model validated
- [ ] Monitoring infrastructure ready
- [ ] Multi-sig wallet configured
- [ ] Emergency procedures documented
- [ ] Final security review completed

### Recommended Initial Configuration

```
Network: Mainnet
Initial House Balance: 500-1000 SUI
Min Wager: 1 SUI (1000000000 MIST)
Max Wager: 50 SUI (50000000000 MIST)
Loss Refund: 50% (recommended)
Emergency Threshold: 10 SUI (10000000000 MIST)
```

### Step 1: Switch to Mainnet

```bash
# Switch network
sui client switch --env mainnet

# Verify active address
sui client active-address

# Check balance (ensure you have enough SUI for gas + house funding)
sui client gas
```

### Step 2: Deploy Package

```bash
cd smart-contracts

# Final build
sui move build

# Publish to mainnet
sui client publish --gas-budget 100000000
```

### Step 3: Multi-Sig Setup (Recommended)

```bash
# Create multi-sig address (2-of-3 recommended)
sui keytool multi-sig-address \
  --pks <PUBLIC_KEY_1> <PUBLIC_KEY_2> <PUBLIC_KEY_3> \
  --weights 1 1 1 \
  --threshold 2

# Transfer AdminCap to multi-sig address
sui client transfer \
  --object-id <ADMIN_CAP_ID> \
  --to <MULTI_SIG_ADDRESS> \
  --gas-budget 10000000
```

### Step 4: Initialize & Fund

```bash
# Create GameHouse
sui client call \
  --package <PACKAGE_ID> \
  --module game \
  --function create_game \
  --type-args 0x2::sui::SUI \
  --args <ADMIN_CAP_ID> \
  --gas-budget 10000000

# Deposit initial house balance (500-1000 SUI)
sui client call \
  --package <PACKAGE_ID> \
  --module game \
  --function deposit \
  --type-args 0x2::sui::SUI \
  --args <GAME_HOUSE_ID> <COIN_OBJECT_ID> \
  --gas-budget 10000000
```

### Step 5: Configure Production Limits

```bash
# Set production limits
# Min: 1 SUI, Max: 50 SUI
sui client call \
  --package <PACKAGE_ID> \
  --module game \
  --function update_config \
  --type-args 0x2::sui::SUI \
  --args <ADMIN_CAP_ID> <GAME_HOUSE_ID> 1000000000 50000000000 \
  --gas-budget 10000000
```

---

## 📊 Monitoring Setup

### Key Metrics to Track

1. **House Balance**

   ```bash
   # Check house balance
   sui client call \
     --package <PACKAGE_ID> \
     --module game \
     --function get_house_balance \
     --type-args 0x2::sui::SUI \
     --args <GAME_HOUSE_ID>
   ```

2. **User Statistics**
   - Total players
   - Total games
   - Volume
   - Win/Loss distribution

3. **Events**
   - Monitor `OutcomeEvent` for each play
   - Track outcome distribution
   - Calculate realized house edge

### Automated Monitoring Script

```javascript
// Example monitoring script (Node.js)
const { SuiClient } = require("@mysten/sui.js/client");

const client = new SuiClient({ url: "https://fullnode.mainnet.sui.io" });

async function monitorHouseBalance(gameHouseId) {
  const interval = 60000; // Check every minute

  setInterval(async () => {
    const object = await client.getObject({
      id: gameHouseId,
      options: { showContent: true },
    });

    const balance = object.data.content.fields.house;
    const balanceSUI = balance / 1_000_000_000;

    console.log(`House Balance: ${balanceSUI} SUI`);

    // Alert if below threshold
    if (balanceSUI < 100) {
      console.error("⚠️ ALERT: House balance critically low!");
      // Send notification (email, Telegram, etc.)
    }
  }, interval);
}

monitorHouseBalance("<GAME_HOUSE_ID>");
```

---

## 🚨 Emergency Procedures

### Emergency Pause

```bash
# Pause the game (requires AdminCap)
sui client call \
  --package <PACKAGE_ID> \
  --module emergency \
  --function pause \
  --args <ADMIN_CAP_ID> <EMERGENCY_STATUS_ID> \
  --gas-budget 10000000
```

### Emergency Withdrawal

```bash
# Withdraw funds from house (requires AdminCap)
sui client call \
  --package <PACKAGE_ID> \
  --module game \
  --function withdraw \
  --type-args 0x2::sui::SUI \
  --args <ADMIN_CAP_ID> <GAME_HOUSE_ID> <AMOUNT_IN_MIST> \
  --gas-budget 10000000
```

### Resume Operations

```bash
# Resume the game after emergency
sui client call \
  --package <PACKAGE_ID> \
  --module emergency \
  --function resume \
  --args <ADMIN_CAP_ID> <EMERGENCY_STATUS_ID> \
  --gas-budget 10000000
```

---

## 🔧 Configuration Reference

### Error Codes

| Code | Constant                    | Meaning                   |
| ---- | --------------------------- | ------------------------- |
| 101  | EWagerTooSmall              | Wager below minimum       |
| 102  | EWagerTooLarge              | Wager above maximum       |
| 103  | EBetTooHighForTreasury      | House can't cover payout  |
| 104  | ETreasuryTooLow             | Emergency pause triggered |
| 105  | EInsufficientWithdrawAmount | Withdraw exceeds balance  |
| 201  | EInsufficientPoolBalance    | RewardPool insufficient   |

### Constants

| Constant              | Value  | Description              |
| --------------------- | ------ | ------------------------ |
| MAX_PAYOUT_MULTIPLIER | 9      | Maximum payout (MIRACLE) |
| EMERGENCY_THRESHOLD   | 10 SUI | Auto-pause threshold     |
| Fee Rate              | 1%     | Operational fee          |

### Outcome Tiers

| Tier       | Roll Range | Probability | Multiplier (Current) |
| ---------- | ---------- | ----------- | -------------------- |
| LOSS       | 0-549      | 55.0%       | 0.60x (60% refund)   |
| SMALL_WIN  | 550-899    | 35.0%       | 1.05x                |
| MEDIUM_WIN | 900-979    | 8.0%        | 1.50x                |
| JACKPOT    | 980-994    | 1.5%        | 6.00x                |
| MIRACLE    | 995-999    | 0.5%        | 9.00x                |

---

## 📝 Post-Deployment Tasks

### Day 1

- [ ] Verify all contracts deployed correctly
- [ ] Test play function with small amounts
- [ ] Monitor first 10-20 transactions
- [ ] Check event emissions
- [ ] Verify house balance updates

### Week 1

- [ ] Monitor daily volume
- [ ] Track outcome distribution
- [ ] Calculate realized house edge
- [ ] Check for any anomalies
- [ ] Gather user feedback

### Month 1

- [ ] Analyze economic model performance
- [ ] Compare theoretical vs actual house edge
- [ ] Evaluate loss tier percentage
- [ ] Consider parameter adjustments
- [ ] Plan feature updates

---

## 🎯 Success Metrics

### Technical Health

- ✅ No failed transactions (except user errors)
- ✅ House balance stable or growing
- ✅ No emergency pauses triggered
- ✅ All events emitting correctly

### Economic Health

- ✅ Realized house edge close to theoretical
- ✅ Outcome distribution matches probabilities
- ✅ Sufficient volume for sustainability
- ✅ House balance above minimum threshold

### User Engagement

- ✅ Growing number of unique players
- ✅ Repeat player rate > 30%
- ✅ Average wager size increasing
- ✅ Positive user feedback

---

## 📞 Support & Resources

### Documentation

- Security Audit: `.md/SECURITY_AUDIT.md`
- Implementation Summary: `.md/IMPLEMENTATION_SUMMARY.md`
- Economic Analysis: `.md/LOSS_TIER_ECONOMICS.md`
- Before/After: `.md/BEFORE_AFTER_COMPARISON.md`

### Sui Resources

- Sui Docs: https://docs.sui.io
- Sui Explorer: https://suiscan.xyz
- Sui Discord: https://discord.gg/sui

### Emergency Contacts

- Multi-sig signers
- Development team
- Security auditor

---

## ✅ Final Checklist

### Before Going Live

- [ ] All tests passing (60/60)
- [ ] Security fixes verified
- [ ] Documentation complete
- [ ] Monitoring setup
- [ ] Emergency procedures tested
- [ ] Multi-sig configured
- [ ] Initial liquidity ready
- [ ] Team briefed

### After Going Live

- [ ] Monitor first 24 hours closely
- [ ] Track all metrics
- [ ] Be ready for emergency pause
- [ ] Communicate with users
- [ ] Gather feedback
- [ ] Plan iterations

---

**Status:** 🟢 Ready for Deployment

**Recommended Path:** Testnet (2-4 weeks) → Mainnet

**Good luck! 🚀**
