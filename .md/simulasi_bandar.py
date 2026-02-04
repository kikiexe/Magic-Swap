import random

# ==========================================
# KONFIGURASI FINAL (MODEL 50:50 THANOS)
# ==========================================
TREASURY_USD = 10000.0   # Modal Awal Bandar
TOTAL_BETS   = 10000     # Jumlah user main

# --- SAFETY VALVE (FITUR ANTI-PAUS) ---
# Payout maksimal per kemenangan tidak boleh melebihi X% dari total treasury.
# Ini mencegah 1 orang menguras habis uang bandar.
MAX_PAYOUT_CAP_RATIO = 0.10  # 10% (Sangat Aman)

# --- SETTING REFUND (LOSS) ---
REFUND_RATE = 0.60      # Balik 60% (Bandar ambil 40%)

# --- SETTING HADIAH (MULTIPLIER) ---
MULT_SMALL   = 1.05     # Profit 5%
MULT_MEDIUM  = 1.50     # Profit 50%
MULT_BIG     = 8.0      # Profit 700%
MULT_MIRACLE = 50.0     # Profit 4900%

# --- DISTRIBUSI PELUANG (TOTAL 1.0) ---
PROB_LOSS    = 0.50     # 50%
PROB_SMALL   = 0.40     # 40%
PROB_MEDIUM  = 0.09     # 9%
PROB_BIG     = 0.009    # 0.9%
PROB_MIRACLE = 0.001    # 0.1%

# ==========================================
# 1. ANALISIS MATEMATIKA (RTP)
# ==========================================
def check_viability():
    print(f"--- PRE-FLIGHT CHECK ---")
    
    # Hitung Return to Player (RTP) Tanpa Cap
    ev_loss    = PROB_LOSS * REFUND_RATE
    ev_small   = PROB_SMALL * MULT_SMALL
    ev_medium  = PROB_MEDIUM * MULT_MEDIUM
    ev_big     = PROB_BIG * MULT_BIG
    ev_miracle = PROB_MIRACLE * MULT_MIRACLE
    
    total_rtp = ev_loss + ev_small + ev_medium + ev_big + ev_miracle
    
    print(f"Theoretical RTP: {total_rtp*100:.2f}%")
    print(f"Expected House Edge: {(1.0 - total_rtp)*100:.2f}%")
    
    if total_rtp > 1.0:
        print("⚠️  PERINGATAN: RTP > 100%. Bergantung pada Safety Cap untuk profit.")
    else:
        print(f"✅ AMAN: Secara matematis bandar untung.")
    print("-" * 40)

# ==========================================
# 2. ENGINE SIMULASI
# ==========================================
def run_simulation():
    treasury = TREASURY_USD
    stats = {
        "Loss": 0, "Small": 0, "Medium": 0, 
        "Big": 0, "Miracle": 0
    }
    safety_triggers = 0 # Menghitung berapa kali sistem menyelamatkan bandar
    
    print(f"STARTING SIMULATION with ${treasury:,.2f} Treasury...")
    print(f"Safety Cap Active: Max Payout {MAX_PAYOUT_CAP_RATIO*100}% of Vault\n")
    
    for i in range(1, TOTAL_BETS + 1):
        # --- A. USER DATANG ---
        # Simulasi User: 95% Ritel ($10-$50), 5% Paus ($100-$1000)
        rng_user = random.random()
        if rng_user < 0.95:
            bet_usd = random.randint(10, 50)
        else:
            bet_usd = random.randint(100, 1000) # Paus Berbahaya
            
        # Duit masuk dulu ke treasury
        treasury += bet_usd
        
        # --- B. PUTAR RNG ---
        rng = random.random()
        multiplier = 0
        outcome = ""
        
        if rng < PROB_LOSS: 
            multiplier = REFUND_RATE
            outcome = "Loss"
            stats["Loss"] += 1
        elif rng < (PROB_LOSS + PROB_SMALL):
            multiplier = MULT_SMALL
            outcome = "Small"
            stats["Small"] += 1
        elif rng < (PROB_LOSS + PROB_SMALL + PROB_MEDIUM):
            multiplier = MULT_MEDIUM
            outcome = "Medium"
            stats["Medium"] += 1
        elif rng < (PROB_LOSS + PROB_SMALL + PROB_MEDIUM + PROB_BIG):
            multiplier = MULT_BIG
            outcome = "Big"
            stats["Big"] += 1
        else:
            multiplier = MULT_MIRACLE
            outcome = "Miracle"
            stats["Miracle"] += 1
            
        # --- C. HITUNG PAYOUT & SAFETY VALVE ---
        ideal_payout = bet_usd * multiplier
        
        # Hitung Batas Aman (10% dari Treasury saat ini)
        max_allowed = treasury * MAX_PAYOUT_CAP_RATIO
        
        actual_payout = ideal_payout
        
        # Jika payout ideal melebihi batas aman, potong!
        if ideal_payout > max_allowed:
            actual_payout = max_allowed
            safety_triggers += 1
            # Uncomment baris bawah kalau mau lihat log setiap kali Safety Cap aktif
            # print(f"[SAFETY] User menang ${ideal_payout:,.0f} tapi dicap jadi ${actual_payout:,.0f}")
            
        # Bayar User
        treasury -= actual_payout
        
        # Cek Bangkrut (Harusnya mustahil dengan Safety Valve)
        if treasury < 0:
            print(f"\n❌ FATAL ERROR: BANKRUPT di user ke-{i}!")
            return 
            
    # --- D. REPORT AKHIR ---
    print("\n=== HASIL AKHIR ===")
    print(f"Saldo Awal : ${TREASURY_USD:,.2f}")
    print(f"Saldo Akhir: ${treasury:,.2f}")
    profit = treasury - TREASURY_USD
    
    roi_percent = (profit / TREASURY_USD) * 100
    print(f"Profit     : ${profit:,.2f} ({roi_percent:.2f}%)")
    
    print("\nStatistik & Keamanan:")
    print(f"📉 Loss (Refund)    : {stats['Loss']}")
    print(f"💵 Small Win        : {stats['Small']}")
    print(f"💰 Medium Win       : {stats['Medium']}")
    print(f"💎 Jackpot (8x)     : {stats['Big']}")
    print(f"🚀 Miracle (50x)    : {stats['Miracle']}")
    print(f"🛡️ Safety Triggered : {safety_triggers} kali (Penyelamatan Bandar)")

if __name__ == "__main__":
    check_viability()
    run_simulation()