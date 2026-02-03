# Protocol Mechanics: "Soft-Loss" Betting System
**Project Codename:** [Insert Name Here]
**Concept:** High-Retention Lottery with Loss Rebate
**Date:** 2026-02-02

---

## 1. The Core Concept
Mekanisme ini dirancang untuk memaksimalkan **User Retention** dengan meminimalkan rasa sakit akibat kekalahan ("Loss Aversion"). User tidak merasa kehilangan uang sepenuhnya, melainkan hanya membayar "biaya partisipasi" untuk peluang mendapatkan reward besar (Jackpot/Token Reward).

### Flow Logika
1.  **Entry (Bet):** User deposit **1 SUI** (Asumsi Market Price: ~$2.00).
2.  **Conversion:** Sistem mengonversi/menilai aset terhadap USDC/Stablecoin.
3.  **Outcome Generation:** RNG (Random Number Generator) menentukan hasil.
    * **Scenario A (Loss - 80-90% Probability):** User kalah taruhan.
    * **Scenario B (Win Tier 2 - 10-15% Probability):** User menang token proyek (WALRUS).
    * **Scenario C (Win Tier 1 - 0.00000001% Probability):** User menang Jackpot (BTC).

---

## 2. The Economics (Unit Analysis)
Analisis ini menggunakan asumsi harga tetap untuk simulasi. Dalam produksi, semua nilai harus *dynamic* (diambil dari Oracle).

**Market Variables:**
* Price SUI: **$2.00**
* Price WALRUS: **$0.10**
* Price USDC: **$1.00**

### A. Skenario Kekalahan (The Loss Rebate)
Ini adalah sumber pendapatan utama protokol (House Edge).
* **User Input:** 1 SUI ($2.00)
* **User Receive:** 1.6 USDC (Refund 80%)
* **House Revenue (Gross):** $0.40 (20% Cut)
* *Catatan:* $0.40 ini adalah dana abadi untuk membayar pemenang dan treasury dev.

### B. Skenario Kemenangan (The Payout)
Ini adalah beban biaya protokol.
* **User Input:** 1 SUI ($2.00)
* **Prize:** 30 WALRUS ($0.10 x 30 = $3.00)
* **User Net Profit:** +$1.00 (ROI 50%)
* **House P&L:** **-$1.00** (Defisit)

> **CRITICAL REALITY:** Fee transaksi blockchain ($0.01 - $0.05) **TIDAK RELEVAN** untuk menutupi defisit $1.00 ini. Satu-satunya penutup defisit adalah akumulasi dari user yang kalah.

---

## 3. Mathematical Viability (Break-Even Point)
Agar bandar tidak bangkrut, jumlah user yang kalah (Loss) harus cukup untuk mensubsidi user yang menang (Win).

### Rumus Break-Even
$$(Prob_{loss} \times Margin_{loss}) = (Prob_{win} \times Cost_{win})$$

**Dimana:**
* $Margin_{loss}$ = $0.40 (Pendapatan saat user kalah)
* $Cost_{win}$ = $1.00 (Kerugian bandar saat user menang: Hadiah $3 - Modal $2)

**Perhitungan:**
$$0.40 \times Y = 1.00 \times 1$$
$$Y = 2.5$$

### The Golden Ratio: 1 : 2.5
Untuk setiap **1 Pemenang** (dapat 30 WALRUS), sistem MEMBUTUHKAN minimal **2.5 Pecundang** (kena potong $0.40).

### Batas Aman Win Rate (Probabilitas Menang)
Jika `x` adalah persentase kemenangan (Win Rate):
$$0.40(1-x) = 1.00(x)$$
$$0.40 - 0.40x = x$$
$$1.4x = 0.40$$
$$x \approx 28.5\%$$

**Kesimpulan Statistik:**
* Jika Win Rate settingan kamu **> 28.5%** = **BANDAR PASTI RUGI**.
* **Rekomendasi Win Rate:** **10% - 15%** (Untuk memastikan profit margin sehat bagi treasury).

---

## 4. Risk Factors & Mitigation

### Risk A: Token Dump (Sell Pressure)
Jika 1000 user menang, 30.000 WALRUS masuk sirkulasi. User rasional akan segera menjual (dump) WALRUS ke USDC untuk mengamankan profit $1 mereka.
* **Dampak:** Harga WALRUS turun -> Nilai hadiah turun -> User tidak tertarik main lagi.
* **Solusi:** Implementasi **Vesting**.
    * Menang 30 WALRUS: 5 cair instan, 25 terkunci (claimable per hari selama 5 hari). Ini memaksa user kembali ke platform (retention) dan menahan laju dump.

### Risk B: SUI Price Volatility (Impermanent Loss)
User deposit 1 SUI saat harga $2.00. Tiba-tiba saat proses, SUI turun ke $1.80.
* Sistem refund 1.6 USDC.
* Sistem jual SUI di $1.80.
* Sisa margin protokol cuma $0.20 (bukan $0.40).
* **Solusi:** Oracle harus update harga *real-time* atau sistem refund berbasis persentase dinamis, bukan fix 1.6 USDC.

---

## 5. Strategic Recommendation
Jangan hanya mengandalkan "Fee Transaksi". Ubah mindset pendapatan menjadi **"Loss Arbitrage"**.

**Pengaturan Algoritma yang Disarankan:**
1.  **Dynamic Odds:** Jika Treasury < $1000, turunkan Win Rate ke 5%. Jika Treasury > $10,000, naikkan Win Rate ke 15%.
2.  **Safety Cap:** Maksimal payout per hari dibatasi untuk mencegah "Bank Run" jika terjadi exploit.
3.  **Vesting Reward:** Wajib diterapkan untuk token WALRUS agar harga token tidak hancur.