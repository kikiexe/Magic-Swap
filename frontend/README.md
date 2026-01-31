# Magic Swap - Sui Blockchain Integration

## 🎮 About
Magic Swap is a high-risk, high-reward gambling dApp built on Sui blockchain. Players can swap SUI tokens with the following probabilities:
- **50% - Loss**: Keep 80% of your tokens
- **40% - Small Win**: Get 1.1x (110%) of your tokens
- **10% - Big Win**: Get 2x (200%) of your tokens!

## 📁 Project Structure
```
gamefi-rev/
├── move/                   # Sui Move smart contract
│   ├── sources/
│   │   └── magic_swap.move
│   └── Move.toml
├── src/
│   ├── components/         # React components
│   │   ├── SwapCard.jsx   # Main swap interface
│   │   ├── OutcomePopup.jsx # Bombastic modal
│   │   └── ActionButton.jsx
│   ├── hooks/              # Custom hooks
│   │   ├── useWallet.js   # Wallet connection
│   │   └── useSwapTransaction.js # Transaction logic
│   ├── providers/
│   │   └── SuiProvider.jsx # Sui SDK provider
│   ├── config/
│   │   └── sui.js         # Contract config
│   └── App.jsx
└── public/
    └── zeus-large.png     # Zeus pixel art
```

## 🚀 Setup Instructions

### 1. Deploy Smart Contract

```bash
cd move
sui client publish --gas-budget 100000000
```

**Save these values from deployment:**
- Package ID
- Game Object ID

### 2. Update Configuration

Edit `src/config/sui.js`:
```javascript
export const PACKAGE_ID = 'YOUR_PACKAGE_ID_FROM_DEPLOYMENT';
export const GAME_OBJECT_ID = 'YOUR_GAME_OBJECT_ID_FROM_DEPLOYMENT';
```

### 3. Fund the House

The house needs SUI to pay out wins:

```bash
sui client call \
  --package YOUR_PACKAGE_ID \
  --module game \
  --function deposit \
  --args YOUR_GAME_OBJECT_ID 1000000000000 \
  --gas-budget 10000000
```

### 4. Run Frontend

```bash
npm install
npm run dev
```

## 🎯 How to Play

1. **Connect Wallet**: Click "Connect Wallet"
2. **Enter Amount**: Type SUI amount to wager
3. **Execute Swap**: Click button and sign transaction
4. **See Results**: Epic modal shows if you won!

## 🛠️ Tech Stack

- Frontend: React + Vite + Tailwind
- Blockchain: Sui Network (Move)
- Wallet: @mysten/dapp-kit
- Design: Neubrutalism + Saweria style

## ⚠️ Next Steps

- [ ] Deploy contract to testnet
- [ ] Update config with Package ID
- [ ] Fund house with SUI
- [ ] Test transactions

---

Built with ⚡ on Sui
