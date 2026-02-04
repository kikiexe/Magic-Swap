#!/usr/bin/env python3
"""
Magic Swap - 10,000 Games Stress Test Simulation
Validates house edge, probability distribution, and edge cases.
"""

import random
from collections import Counter
from typing import Dict, List, Tuple

# ============ CONFIGURATION ============

# Probability Distribution (NEW)
LOSS_RANGE = (0, 549)          # 55.0%
SMALL_WIN_RANGE = (550, 899)   # 35.0%
MEDIUM_WIN_RANGE = (900, 979)  # 8.0%
JACKPOT_RANGE = (980, 994)     # 1.5%
MIRACLE_RANGE = (995, 999)     # 0.5%

# Multipliers (in basis points, divide by 100 for actual)
LOSS_MULT = 60      # 0.60x
SMALL_MULT = 105    # 1.05x
MEDIUM_MULT = 150   # 1.50x
JACKPOT_MULT = 600  # 6.00x
MIRACLE_MULT = 900  # 9.00x

# Game Parameters
NUM_GAMES = 10_000
INITIAL_TREASURY = 10_000  # SUI
FEE_RATE = 0.01  # 1%
SAFETY_CAP_PERCENT = 0.10  # 10% of treasury

# Bet Distribution (realistic player behavior)
BET_DISTRIBUTION = {
    1: 0.40,    # 40% bet 1 SUI
    5: 0.30,    # 30% bet 5 SUI
    10: 0.20,   # 20% bet 10 SUI
    50: 0.08,   # 8% bet 50 SUI
    100: 0.02,  # 2% bet 100 SUI
}

# ============ GAME LOGIC ============

def roll_dice() -> int:
    """Simulate random roll (0-999)"""
    return random.randint(0, 999)

def calculate_outcome(roll: int) -> Tuple[int, str]:
    """Calculate outcome based on roll"""
    if LOSS_RANGE[0] <= roll <= LOSS_RANGE[1]:
        return LOSS_MULT, "LOSS"
    elif SMALL_WIN_RANGE[0] <= roll <= SMALL_WIN_RANGE[1]:
        return SMALL_MULT, "SMALL_WIN"
    elif MEDIUM_WIN_RANGE[0] <= roll <= MEDIUM_WIN_RANGE[1]:
        return MEDIUM_MULT, "MEDIUM_WIN"
    elif JACKPOT_RANGE[0] <= roll <= JACKPOT_RANGE[1]:
        return JACKPOT_MULT, "JACKPOT"
    elif MIRACLE_RANGE[0] <= roll <= MIRACLE_RANGE[1]:
        return MIRACLE_MULT, "MIRACLE"
    else:
        raise ValueError(f"Invalid roll: {roll}")

def apply_safety_cap(payout: float, wager: float, treasury: float) -> float:
    """Apply 10% safety cap on winnings"""
    if payout <= wager:
        return payout  # Loss or break-even, no cap
    
    profit = payout - wager
    max_profit = treasury * SAFETY_CAP_PERCENT
    
    if profit > max_profit:
        return wager + max_profit
    return payout

def select_bet() -> float:
    """Select bet amount based on distribution"""
    rand = random.random()
    cumulative = 0.0
    for bet, prob in BET_DISTRIBUTION.items():
        cumulative += prob
        if rand <= cumulative:
            return float(bet)
    return 1.0  # Fallback

# ============ SIMULATION ============

def run_simulation(num_games: int = NUM_GAMES) -> Dict:
    """Run full simulation"""
    
    treasury = INITIAL_TREASURY
    total_wagered = 0.0
    total_payout = 0.0
    total_fees = 0.0
    outcome_counts = Counter()
    
    results = []
    treasury_history = [treasury]
    
    for game_num in range(1, num_games + 1):
        # Select bet
        wager = select_bet()
        
        # Pre-flight safety check
        max_possible_payout = wager * (MIRACLE_MULT / 100)
        if max_possible_payout > treasury:
            # Bet rejected (too high for treasury)
            continue
        
        # Deduct fee
        fee = wager * FEE_RATE
        net_wager = wager - fee
        
        # Roll dice
        roll = roll_dice()
        multiplier, outcome = calculate_outcome(roll)
        
        # Calculate ideal payout
        ideal_payout = net_wager * (multiplier / 100)
        
        # Apply safety cap
        final_payout = apply_safety_cap(ideal_payout, net_wager, treasury)
        
        # Update treasury
        if final_payout > net_wager:
            # Player won
            profit = final_payout - net_wager
            treasury -= profit
        else:
            # Player lost
            loss = net_wager - final_payout
            treasury += loss
        
        # Track stats
        total_wagered += wager
        total_payout += final_payout
        total_fees += fee
        outcome_counts[outcome] += 1
        
        results.append({
            'game': game_num,
            'wager': wager,
            'roll': roll,
            'outcome': outcome,
            'multiplier': multiplier,
            'payout': final_payout,
            'treasury': treasury,
        })
        
        treasury_history.append(treasury)
        
        # Check for bankruptcy
        if treasury < 10:
            print(f"⚠️ TREASURY DEPLETED at game {game_num}!")
            break
    
    return {
        'results': results,
        'treasury_history': treasury_history,
        'final_treasury': treasury,
        'total_wagered': total_wagered,
        'total_payout': total_payout,
        'total_fees': total_fees,
        'outcome_counts': outcome_counts,
    }

# ============ ANALYSIS ============

def analyze_results(data: Dict):
    """Analyze simulation results"""
    
    print("=" * 60)
    print("MAGIC SWAP - 10,000 GAMES STRESS TEST")
    print("=" * 60)
    print()
    
    # Treasury Analysis
    print("📊 TREASURY ANALYSIS:")
    print(f"  Initial Treasury: {INITIAL_TREASURY:,.2f} SUI")
    print(f"  Final Treasury:   {data['final_treasury']:,.2f} SUI")
    profit = data['final_treasury'] - INITIAL_TREASURY
    print(f"  House Profit:     {profit:,.2f} SUI ({profit/INITIAL_TREASURY*100:+.2f}%)")
    print()
    
    # Wagering Analysis
    print("💰 WAGERING ANALYSIS:")
    print(f"  Total Wagered:    {data['total_wagered']:,.2f} SUI")
    print(f"  Total Payout:     {data['total_payout']:,.2f} SUI")
    print(f"  Total Fees:       {data['total_fees']:,.2f} SUI")
    net_house_profit = data['total_wagered'] - data['total_payout']
    print(f"  Net House Profit: {net_house_profit:,.2f} SUI")
    house_edge = (net_house_profit / data['total_wagered']) * 100
    print(f"  House Edge:       {house_edge:.2f}%")
    print(f"  Expected Edge:    4.75%")
    print()
    
    # Outcome Distribution
    print("🎲 OUTCOME DISTRIBUTION:")
    total_games = sum(data['outcome_counts'].values())
    
    outcomes = [
        ("LOSS", 55.0),
        ("SMALL_WIN", 35.0),
        ("MEDIUM_WIN", 8.0),
        ("JACKPOT", 1.5),
        ("MIRACLE", 0.5),
    ]
    
    for outcome, expected_pct in outcomes:
        count = data['outcome_counts'][outcome]
        actual_pct = (count / total_games) * 100
        diff = actual_pct - expected_pct
        status = "✅" if abs(diff) < 2.0 else "⚠️"
        print(f"  {status} {outcome:12s}: {count:5d} ({actual_pct:5.2f}%) [Expected: {expected_pct:5.2f}%] (Δ {diff:+.2f}%)")
    print()
    
    # Edge Cases
    print("🔍 EDGE CASE ANALYSIS:")
    
    # Find largest win
    largest_win = max(data['results'], key=lambda x: x['payout'] - x['wager'])
    print(f"  Largest Win:")
    print(f"    Game #{largest_win['game']}: {largest_win['outcome']}")
    print(f"    Wager: {largest_win['wager']:.2f} SUI")
    print(f"    Payout: {largest_win['payout']:.2f} SUI")
    print(f"    Profit: {largest_win['payout'] - largest_win['wager']:.2f} SUI")
    print()
    
    # Find largest loss
    largest_loss = min(data['results'], key=lambda x: x['payout'] - x['wager'])
    print(f"  Largest Loss:")
    print(f"    Game #{largest_loss['game']}: {largest_loss['outcome']}")
    print(f"    Wager: {largest_loss['wager']:.2f} SUI")
    print(f"    Payout: {largest_loss['payout']:.2f} SUI")
    print(f"    Loss: {largest_loss['wager'] - largest_loss['payout']:.2f} SUI")
    print()
    
    # Treasury volatility
    treasury_min = min(data['treasury_history'])
    treasury_max = max(data['treasury_history'])
    print(f"  Treasury Volatility:")
    print(f"    Min: {treasury_min:,.2f} SUI")
    print(f"    Max: {treasury_max:,.2f} SUI")
    print(f"    Range: {treasury_max - treasury_min:,.2f} SUI")
    print()
    
    # Validation
    print("✅ VALIDATION:")
    
    checks = []
    
    # Check 1: House edge within 1% of expected
    edge_ok = abs(house_edge - 4.75) < 1.0
    checks.append(("House edge ~4.75%", edge_ok))
    
    # Check 2: Treasury never went negative
    treasury_ok = treasury_min > 0
    checks.append(("Treasury always positive", treasury_ok))
    
    # Check 3: Outcome distribution reasonable
    dist_ok = all(abs(data['outcome_counts'][o] / total_games * 100 - e) < 3.0 for o, e in outcomes)
    checks.append(("Outcome distribution valid", dist_ok))
    
    # Check 4: Final treasury profitable
    profit_ok = data['final_treasury'] > INITIAL_TREASURY
    checks.append(("House profitable", profit_ok))
    
    for check, passed in checks:
        status = "✅" if passed else "❌"
        print(f"  {status} {check}")
    
    print()
    print("=" * 60)
    
    all_passed = all(c[1] for c in checks)
    if all_passed:
        print("🎉 ALL VALIDATIONS PASSED - READY FOR DEPLOYMENT")
    else:
        print("⚠️ SOME VALIDATIONS FAILED - REVIEW REQUIRED")
    print("=" * 60)

# ============ MAIN ============

if __name__ == "__main__":
    print("Starting 10,000 games simulation...")
    print()
    
    # Run simulation
    data = run_simulation()
    
    # Analyze results
    analyze_results(data)
    
    # Optional: Save detailed results
    # import json
    # with open('stress_test_results.json', 'w') as f:
    #     json.dump(data, f, indent=2)
