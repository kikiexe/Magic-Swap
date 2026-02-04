# Smart Contract Changes - Quick Reference

## 📋 FILES MODIFIED

### **Core Logic:**

1. `sources/core/probability_engine.move`
   - Changed loss threshold: 500 → 550 (55% loss rate)
   - Changed medium win threshold: 990 → 980 (8% medium win)
   - Changed jackpot threshold: 999 → 995 (1.5% jackpot)
   - Reduced jackpot multiplier: 800 → 600 (8x → 6x)
   - Reduced miracle multiplier: 5000 → 900 (50x → 9x)

2. `sources/core/magic_swap.move`
   - Added emergency treasury check (< 10 SUI auto-pause)
   - Added pre-flight safety check (max bet validation)
   - Changed `status` parameter to `&mut EmergencyStatus`
   - Pass current epoch to `update_stats()`

### **Modules:**

3. `sources/modules/user_stats.move`
   - Added `last_play_timestamp: u64` field to `UserStats`
   - Added cooldown check (2 epochs minimum)
   - Updated `update_stats()` signature (added `current_epoch` parameter)
   - Initialize `last_play_timestamp` to 0 for new users

4. `sources/modules/emergency.move`
   - Added `auto_pause()` function (package-level access)

### **Tests (Need Updates):**

5. `tests/user_stats_tests.move`
   - All `update_stats_for_testing()` calls need epoch parameter (0)
6. `tests/emergency_tests.move`
   - All `status` variables need `mut` declaration
   - All `game::play()` calls need `&mut status`

7. `tests/integration_tests.move`
   - `status` variable needs `mut` declaration
   - `game::play()` call needs `&mut status`

8. `tests/tier_outcome_tests.move`
   - Update expected multipliers: 800 → 600, 5000 → 900

---

## 🔢 NEW PROBABILITY DISTRIBUTION

| Outcome    | Roll Range | Probability | Multiplier  | Old Multiplier    |
| ---------- | ---------- | ----------- | ----------- | ----------------- |
| Loss       | 0-549      | 55.0%       | 0.60x (60)  | Same              |
| Small Win  | 550-899    | 35.0%       | 1.05x (105) | Same              |
| Medium Win | 900-979    | 8.0%        | 1.50x (150) | Same              |
| Jackpot    | 980-994    | 1.5%        | 6.00x (600) | **8.00x (800)**   |
| Miracle    | 995-999    | 0.5%        | 9.00x (900) | **50.00x (5000)** |

**Key Changes:**

- Loss rate: 50% → 55% (more sustainable)
- Small win rate: 40% → 35% (balanced)
- Jackpot: 0.9% → 1.5% (more frequent but smaller)
- Miracle: 0.1% → 0.5% (more frequent but smaller)

---

## 🛡️ NEW SECURITY CHECKS

### **1. Cooldown Enforcement (user_stats.move:72)**

```move
assert!(current_epoch >= stats.last_play_timestamp + 2, 999);
```

- Prevents spam attacks
- Minimum 2 epochs between plays (~4 seconds)

### **2. Emergency Auto-Pause (magic_swap.move:128-131)**

```move
if (balance::value(&game.house) < 10_000_000_000) {
    emergency::auto_pause(status);
    abort 104
}
```

- Auto-pauses when treasury < 10 SUI
- Prevents operating with insufficient funds

### **3. Pre-Flight Safety Check (magic_swap.move:152-155)**

```move
let max_possible_payout = net_wager * 9;
assert!(max_possible_payout <= house_balance_val, 103);
```

- Validates bet before execution
- Prevents bets that could exceed treasury

---

## 🔧 BREAKING CHANGES

### **Function Signatures:**

**user_stats::update_stats()** - Added parameter:

```move
// OLD:
public(package) fun update_stats(
    registry: &mut UserStatsRegistry,
    player: address,
    wager: u64,
    payout: u64,
    outcome_tier: u8,
)

// NEW:
public(package) fun update_stats(
    registry: &mut UserStatsRegistry,
    player: address,
    wager: u64,
    payout: u64,
    outcome_tier: u8,
    current_epoch: u64,  // ← NEW
)
```

**game::play()** - Changed parameter:

```move
// OLD:
public entry fun play<T>(
    ...
    status: &EmergencyStatus,
    ...
)

// NEW:
public entry fun play<T>(
    ...
    status: &mut EmergencyStatus,  // ← CHANGED
    ...
)
```

### **Struct Changes:**

**UserStats** - Added field:

```move
public struct UserStats has store, copy, drop {
    total_wagered: u64,
    total_payout: u64,
    games_played: u64,
    tier_counts: vector<u64>,
    net_profit: u64,
    is_profit: bool,
    last_play_timestamp: u64,  // ← NEW
}
```

---

## 🧪 TEST UPDATES NEEDED

### **Pattern 1: update_stats_for_testing calls**

```move
// OLD:
user_stats::update_stats_for_testing(&mut registry, USER_A, 1000, 600, 0);

// NEW:
user_stats::update_stats_for_testing(&mut registry, USER_A, 1000, 600, 0, 0);
//                                                                          ↑ epoch
```

### **Pattern 2: EmergencyStatus declarations**

```move
// OLD:
let status = test_scenario::take_shared<EmergencyStatus>(&scenario);

// NEW:
let mut status = test_scenario::take_shared<EmergencyStatus>(&scenario);
//  ↑ add mut
```

### **Pattern 3: game::play calls**

```move
// OLD:
game::play(&mut game_obj, &mut fee_vault, &mut stats_registry, &status, ...);

// NEW:
game::play(&mut game_obj, &mut fee_vault, &mut stats_registry, &mut status, ...);
//                                                               ↑ add mut
```

### **Pattern 4: Expected multipliers**

```move
// OLD:
assert!(multiplier == 800, ...);  // Jackpot
assert!(multiplier == 5000, ...); // Miracle

// NEW:
assert!(multiplier == 600, ...);  // Jackpot
assert!(multiplier == 900, ...);  // Miracle
```

---

## 📊 HOUSE EDGE CALCULATION

```
Expected Value = Σ(Probability × Net Profit)

= (0.55 × -0.40)     // Loss: house gains 40%
+ (0.35 × 0.05)      // Small win: house loses 5%
+ (0.08 × 0.50)      // Medium win: house loses 50%
+ (0.015 × 5.00)     // Jackpot: house loses 500%
+ (0.005 × 8.00)     // Miracle: house loses 800%

= -0.22 + 0.0175 + 0.04 + 0.075 + 0.04
= -0.0475
= -4.75% (house edge)
```

**Interpretation:** House expects to profit 4.75% of total wagers over time.

---

## 🚀 DEPLOYMENT CHECKLIST

Before deploying to testnet/mainnet:

- [ ] Update all test files with new signatures
- [ ] Run `sui move test` (target: 59/59 passing)
- [ ] Update documentation (PROJECT_BLUEPRINT.md, core-idea.md)
- [ ] Increase emergency threshold to 50 SUI for mainnet
- [ ] Run stress test (10,000 games simulation)
- [ ] Security audit for reentrancy vulnerabilities
- [ ] Frontend integration testing
- [ ] Multi-sig setup for AdminCap

---

**Last Updated:** 2026-02-04 22:40 WIB  
**Contract Version:** v1.0.0-fixed
