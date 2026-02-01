import React, { useState } from 'react';
import { Wallet, LogOut } from 'lucide-react';
import { ConnectButton } from '@mysten/dapp-kit';
import SwapCard from './components/SwapCard';
import OutcomePopup from './components/OutcomePopup';
import SuiProvider from './providers/SuiProvider';
import { useWallet } from './hooks/useWallet';
import './App.css';

function AppContent() {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [swapResult, setSwapResult] = useState(null);
  const { address, isConnected, balance, disconnect } = useWallet();

  const handleSwapExecute = (result) => {
    setSwapResult(result);
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setSwapResult(null);
  };

  return (
    <div className="min-h-screen bg-[#FAFAFA]">
      {/* Cute mascot area at top */}
      <div className="text-center pt-8 pb-4">
        <div className="text-7xl mb-3">
          🎮 ⚡ 🎲
        </div>
        <h1 className="font-heading text-3xl font-bold text-gray-800 mb-1">
          Magic Swap
        </h1>
        <p className="font-mono text-sm text-gray-600">
          Your bridge to digital fortune!
        </p>
      </div>

      {/* Connect Wallet Button */}
      <div className="flex justify-center mb-8 px-4">
        {!isConnected ? (
          <ConnectButton className="btn-brutal bg-saweria-orange border-[3px] border-black shadow-brutal px-8 py-3 rounded-lg font-heading font-bold flex items-center gap-2 hover:bg-[#E8995A] transition-all text-lg" />
        ) : (
          <div className="flex items-center gap-4">
            <div className="bg-white border-[3px] border-black shadow-brutal px-6 py-3 rounded-lg">
              <p className="font-mono text-xs text-gray-600 mb-1">Connected Wallet</p>
              <p className="font-mono font-bold text-sm">{address?.slice(0, 6)}...{address?.slice(-4)}</p>
              <p className="font-mono text-xs text-gray-600 mt-1">Balance: {balance.toFixed(4)} SUI</p>
            </div>
            <button
              onClick={disconnect}
              className="btn-brutal bg-red-200 border-[3px] border-black shadow-brutal p-3 rounded-lg hover:bg-red-300 transition-all"
            >
              <LogOut className="w-5 h-5" />
            </button>
          </div>
        )}
      </div>

      {/* Main Content */}
      <main className="flex flex-col items-center px-4 pb-12">
        <SwapCard onSwapExecute={handleSwapExecute} />
      </main>

      {/* Outcome Modal */}
      <OutcomePopup
        isOpen={isModalOpen}
        onClose={handleCloseModal}
        result={swapResult}
      />
    </div>
  );
}

function App() {
  return (
    <SuiProvider>
      <AppContent />
    </SuiProvider>
  );
}

export default App;
