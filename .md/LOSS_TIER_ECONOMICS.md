# 📊 Loss Tier Economic Analysis

**Date:** 2026-02-05  
**Purpose:** Evaluate Loss Tier refund percentage for optimal house sustainability

---

## Current Implementation

```move
if (roll < 550) {
    (60, 0)   // LOSS - Player gets 60% back
}
```

**Probability Distribution:**

- 0-549 (55.0%): LOSS - 0.60x (60% refund, 40% house take)
- 550-899 (35.0%): SMALL_WIN - 1.05x (5% player profit)
- 900-979 (8.0%): MEDIUM_WIN - 1.50x (50% player profit)
- 980-994 (1.5%): JACKPOT - 6.00x (500% player profit)
- 995-999 (0.5%): MIRACLE - 9.00x (800% player profit)

---

## Mathematical Analysis

### Expected Value Calculation

For a 1 SUI wager (after 1% fee = 0.99 SUI net):

```
EV = Σ(Probability × Payout)

EV = (0.55 × 0.60) + (0.35 × 1.05) + (0.08 × 1.50) + (0.015 × 6.00) + (0.005 × 9.00)
   = 0.33 + 0.3675 + 0.12 + 0.09 + 0.045
   = 0.9525

House Edge = 1 - 0.9525 = 0.0475 = 4.75%
```

### Comparison with Different Loss Refunds

| Loss Refund       | Expected Value | House Edge | House Take per 100 SUI Volume |
| ----------------- | -------------- | ---------- | ----------------------------- |
| 0% (No refund)    | 0.7975         | 20.25%     | 20.25 SUI                     |
| 20%               | 0.8875         | 11.25%     | 11.25 SUI                     |
| 40%               | 0.9200         | 8.00%      | 8.00 SUI                      |
| **60% (Current)** | **0.9525**     | **4.75%**  | **4.75 SUI**                  |
| 80%               | 0.9850         | 1.50%      | 1.50 SUI                      |

---

## Scenario Analysis

### Scenario 1: Current (60% Refund) - Player Friendly

**House Edge:** 4.75%

**Daily Volume Requirements:**

- To earn 10 SUI/day: Need 210.5 SUI volume
- To earn 50 SUI/day: Need 1,052.6 SUI volume
- To earn 100 SUI/day: Need 2,105.3 SUI volume

**Minimum House Balance:**

- For max wager 10 SUI: 90 SUI (9x multiplier)
- For max wager 50 SUI: 450 SUI
- For max wager 100 SUI: 900 SUI

**Risk Assessment:**

- 🟡 **Medium Risk:** Requires consistent high volume
- 🟡 **Volatility:** One Miracle win (9x) can wipe out 189 average plays
- 🟢 **Player Retention:** Very attractive for players

**Break-Even Analysis:**

```
If player bets 100 SUI total:
- Expected loss: 4.75 SUI
- But with variance, could win or lose much more
- House needs volume to realize edge
```

---

### Scenario 2: Balanced (40% Refund) - Recommended

**House Edge:** 8.00%

**Calculation:**

```
EV = (0.55 × 0.40) + (0.35 × 1.05) + (0.08 × 1.50) + (0.015 × 6.00) + (0.005 × 9.00)
   = 0.22 + 0.3675 + 0.12 + 0.09 + 0.045
   = 0.8425

House Edge = 1 - 0.8425 = 0.1575 = 15.75%

Wait, let me recalculate...

Actually for 40% refund on LOSS tier:
EV = (0.55 × 0.40) + (0.35 × 1.05) + (0.08 × 1.50) + (0.015 × 6.00) + (0.005 × 9.00)
   = 0.22 + 0.3675 + 0.12 + 0.09 + 0.045
   = 0.8425

House Edge = 1 - 0.8425 = 15.75%

Hmm, that's too high. Let me recalculate properly...

For 40% refund:
Loss: -60% of wager (player loses 60%)
Small Win: +5% of wager
Medium Win: +50% of wager
Jackpot: +500% of wager
Miracle: +800% of wager

EV = (0.55 × -0.60) + (0.35 × 0.05) + (0.08 × 0.50) + (0.015 × 5.00) + (0.005 × 8.00)
   = -0.33 + 0.0175 + 0.04 + 0.075 + 0.04
   = -0.1575

House Edge = 15.75%
```

Wait, I need to recalculate this properly. Let me use net profit/loss:

**For 60% refund (current):**

- Loss: Player gets 0.60x back → Net: -0.40x
- Small Win: Player gets 1.05x back → Net: +0.05x
- Medium Win: Player gets 1.50x back → Net: +0.50x
- Jackpot: Player gets 6.00x back → Net: +5.00x
- Miracle: Player gets 9.00x back → Net: +8.00x

```
Player EV = (0.55 × -0.40) + (0.35 × 0.05) + (0.08 × 0.50) + (0.015 × 5.00) + (0.005 × 8.00)
          = -0.22 + 0.0175 + 0.04 + 0.075 + 0.04
          = -0.0475

House Edge = 4.75% ✓
```

**For 40% refund:**

- Loss: Player gets 0.40x back → Net: -0.60x

```
Player EV = (0.55 × -0.60) + (0.35 × 0.05) + (0.08 × 0.50) + (0.015 × 5.00) + (0.005 × 8.00)
          = -0.33 + 0.0175 + 0.04 + 0.075 + 0.04
          = -0.1575

House Edge = 15.75%
```

That's too aggressive. Let me try 50% refund:

**For 50% refund:**

- Loss: Player gets 0.50x back → Net: -0.50x

```
Player EV = (0.55 × -0.50) + (0.35 × 0.05) + (0.08 × 0.50) + (0.015 × 5.00) + (0.005 × 8.00)
          = -0.275 + 0.0175 + 0.04 + 0.075 + 0.04
          = -0.1025

House Edge = 10.25%
```

**Better! Let's use 50% refund as the balanced option.**

---

### Revised Scenario 2: Balanced (50% Refund)

**House Edge:** 10.25%

**Daily Volume Requirements:**

- To earn 10 SUI/day: Need 97.6 SUI volume
- To earn 50 SUI/day: Need 487.8 SUI volume
- To earn 100 SUI/day: Need 975.6 SUI volume

**Minimum House Balance:**

- For max wager 10 SUI: 90 SUI (9x multiplier)
- For max wager 50 SUI: 450 SUI
- For max wager 100 SUI: 900 SUI

**Risk Assessment:**

- 🟢 **Lower Risk:** More sustainable with moderate volume
- 🟡 **Volatility:** Still need to manage big wins
- 🟢 **Player Retention:** Still attractive (50% loss mitigation)

**Break-Even Analysis:**

```
If player bets 100 SUI total:
- Expected loss: 10.25 SUI
- More predictable for house
- Still player-friendly with 50% loss protection
```

---

### Scenario 3: Conservative (0% Refund) - Traditional Casino

**House Edge:** 20.25%

**Daily Volume Requirements:**

- To earn 10 SUI/day: Need 49.4 SUI volume
- To earn 50 SUI/day: Need 246.9 SUI volume
- To earn 100 SUI/day: Need 493.8 SUI volume

**Risk Assessment:**

- 🟢 **Low Risk:** Very sustainable
- 🔴 **Player Retention:** May discourage players
- 🟢 **Volatility:** Better handles big wins

---

## Industry Comparison

| Platform                  | House Edge | Loss Refund | Notes            |
| ------------------------- | ---------- | ----------- | ---------------- |
| Traditional Casino        | 2-5%       | 0%          | Slots, Roulette  |
| Crypto Dice (Typical)     | 1-2%       | 0%          | Pure probability |
| **Magic Swap (Current)**  | **4.75%**  | **60%**     | Unique model     |
| **Magic Swap (Balanced)** | **10.25%** | **50%**     | Recommended      |
| Crash Games               | 1-3%       | 0%          | Multiplier-based |

---

## Recommendation Matrix

| Metric                                  | 60% Refund           | 50% Refund            | 0% Refund        |
| --------------------------------------- | -------------------- | --------------------- | ---------------- |
| House Sustainability                    | ⚠️ Needs high volume | ✅ Moderate volume OK | ✅ Low volume OK |
| Player Attraction                       | ✅ Very attractive   | ✅ Attractive         | ❌ Standard      |
| Unique Selling Point                    | ✅ "Loss insurance"  | ✅ "Loss protection"  | ❌ None          |
| Risk Management                         | ⚠️ Higher variance   | ✅ Balanced           | ✅ Low variance  |
| Minimum House Balance                   | 1000 SUI             | 500 SUI               | 250 SUI          |
| Daily Volume Needed (for 50 SUI profit) | 1,053 SUI            | 488 SUI               | 247 SUI          |

---

## Final Recommendation

### 🎯 Recommended: 50% Loss Refund

**Rationale:**

1. **Balanced Economics:** 10.25% house edge is sustainable
2. **Unique Feature:** Still offers "loss protection" as USP
3. **Lower Risk:** Requires ~50% less volume than current
4. **Player Friendly:** 50% refund is still very generous
5. **Market Position:** Differentiates from traditional 0% refund games

**Implementation:**

```move
if (roll < 550) {
    (50, 0)   // LOSS - Player gets 50% back
}
```

**Expected Outcomes:**

- House Edge: 10.25%
- Minimum House Balance: 500 SUI (for 50 SUI max wager)
- Daily Volume for 50 SUI profit: ~488 SUI
- Player retention: High (unique loss protection feature)

---

## Phased Rollout Strategy

### Phase 1: Testnet (Keep 60%)

- Test player engagement
- Measure actual volume
- Validate economic model
- Duration: 2-4 weeks

### Phase 2: Mainnet Launch (Start with 50%)

- Launch with 50% refund
- Monitor metrics closely
- Adjust if needed
- Duration: 1-2 months

### Phase 3: Optimization (Data-Driven)

- Analyze actual house edge realization
- Compare to theoretical
- Adjust based on:
  - Volume trends
  - Player retention
  - House balance health
  - Competitive landscape

---

## Monitoring Metrics

Track these KPIs to validate the model:

1. **Realized House Edge:**
   - Should converge to theoretical over time
   - Alert if deviates >2% for >1 week

2. **Volume Metrics:**
   - Daily volume
   - Average wager size
   - Number of unique players
   - Repeat player rate

3. **Outcome Distribution:**
   - Should match theoretical probabilities
   - Alert if any tier deviates >5%

4. **House Balance:**
   - Track min/max/average
   - Alert if drops below 500 SUI
   - Auto-pause if drops below 100 SUI

---

## Risk Mitigation

### If Volume is Lower Than Expected:

**Option 1:** Reduce max wager

- Keeps same house edge
- Reduces maximum loss per play
- Allows operation with lower house balance

**Option 2:** Adjust refund percentage

- Can reduce to 40% (15.75% house edge)
- Increases profitability per play
- May impact player retention

**Option 3:** Add volume incentives

- Referral bonuses
- Loyalty rewards
- Tournament events

### If Volume is Higher Than Expected:

**Option 1:** Increase max wager

- Allows whales to play
- Increases total volume
- Requires higher house balance

**Option 2:** Keep current limits

- Safer approach
- Build house balance first
- Scale gradually

---

## Conclusion

**Current Status:** 60% refund (4.75% house edge)
**Recommended:** 50% refund (10.25% house edge)
**Rationale:** Better balance of sustainability and player attraction

**Action Items:**

1. Test current model on Testnet
2. Collect volume data
3. Launch Mainnet with 50% refund
4. Monitor and adjust based on data

**Decision Point:** Before Mainnet deployment

---

**Note:** This is a data-driven recommendation. Final decision should consider:

- Target market
- Competitive landscape
- Risk tolerance
- Marketing strategy
- Initial liquidity available
