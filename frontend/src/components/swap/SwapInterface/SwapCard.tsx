import React, { useState } from 'react';
import { ChevronDown, Loader2 } from 'lucide-react';
import ActionButton from './ActionButton';
import { useSwapTransaction } from '../hooks/useSwapTransaction';
import { useWallet } from '../hooks/useWallet';

const COINS = [
    { id: 'SUI', name: 'SUI', icon: '🌊' },
];

export default function SwapCard({ onSwapExecute }) {
    const [amount, setAmount] = useState('');
    const [selectedCoin, setSelectedCoin] = useState(COINS[0]);
    const { executeSwap, isLoading } = useSwapTransaction();
    const { isConnected, balance } = useWallet();

    // Contract probabilities (from smart contract)
    // 50% loss (return 80%), 40% small win (1.1x), 10% big win (2x)
    const riskPercentage = 50;

    const handleExecute = async () => {
        if (!isConnected) {
            alert('Please connect your wallet first!');
            return;
        }

        if (!amount || parseFloat(amount) <= 0) {
            alert('Please enter a valid amount!');
            return;
        }

        const amountSui = parseFloat(amount);

        // Check balance
        if (amountSui > balance) {
            alert(`Insufficient balance! You only have ${balance.toFixed(4)} SUI`);
            return;
        }

        try {
            // Convert SUI to MIST (1 SUI = 1_000_000_000 MIST)
            const amountMist = Math.floor(amountSui * 1_000_000_000);

            const result = await executeSwap(amountMist);
            onSwapExecute(result);

            // Clear input after successful swap
            setAmount('');
        } catch (error) {
            console.error('Swap failed:', error);
            alert(error.message || 'Swap transaction failed. Please try again.');
        }
    };

    return (
        <div className="bg-white border-[3px] border-black shadow-brutal-lg rounded-2xl p-6 max-w-2xl w-full">
            {/* Info Section */}
            <div className="bg-white border-[3px] border-black rounded-xl p-5 mb-5">
                <div className="flex items-start gap-4">
                    <div className="flex-1">
                        <p className="font-mono text-sm leading-relaxed mb-3">
                            Magic Swap: High risk, high reward SUI gambling game!
                        </p>
                        <div className="grid grid-cols-2 gap-3">
                            <div>
                                <p className="text-xs font-mono mb-1">🎮 Probabilities</p>
                                <ul className="space-y-0.5">
                                    <li className="font-mono text-xs">• Loss (50%): Keep 80%</li>
                                    <li className="font-mono text-xs">• Small Win (40%): 1.1x</li>
                                    <li className="font-mono text-xs">• Big Win (10%): 2.0x</li>
                                </ul>
                            </div>
                            <div className="flex items-center justify-center">
                                <div className="text-6xl">⚡</div>
                            </div>
                        </div>
                        <p className="font-mono text-xs mt-3 text-gray-600">
                            Enter amount in SUI to play:
                        </p>
                    </div>
                </div>
            </div>

            {/* Input and Action in a card */}
            <div className="bg-white border-[3px] border-black rounded-xl p-5 mb-5">
                <label className="font-heading font-semibold text-sm mb-2 block">
                    Token Amount (SUI)
                </label>
                <input
                    type="number"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    placeholder="Enter amount..."
                    disabled={isLoading}
                    className="input-brutal w-full px-4 py-3 border-[3px] border-black rounded-lg text-lg font-mono font-bold shadow-brutal focus:outline-none transition-all mb-4 disabled:opacity-50"
                />

                {/* Win/Loss Probability Bar */}
                <div className="mb-4">
                    <div className="flex justify-between font-mono text-xs mb-2 text-gray-600">
                        <span>Probabilities</span>
                    </div>
                    <div className="h-6 bg-gray-200 border-[3px] border-black rounded-lg overflow-hidden flex text-[10px]">
                        <div
                            className="bg-retro-pink border-r-[2px] border-black flex items-center justify-center font-mono font-bold"
                            style={{ width: '50%' }}
                        >
                            LOSS 50%
                        </div>
                        <div
                            className="bg-retro-mint border-r-[2px] border-black flex items-center justify-center font-mono font-bold"
                            style={{ width: '40%' }}
                        >
                            WIN 40%
                        </div>
                        <div
                            className="bg-yellow-300 flex items-center justify-center font-mono font-bold"
                            style={{ width: '10%' }}
                        >
                            x2
                        </div>
                    </div>
                </div>

                {/* Action Button */}
                <ActionButton onClick={handleExecute} variant="primary" disabled={isLoading}>
                    {isLoading ? (
                        <span className="flex items-center justify-center gap-2">
                            <Loader2 className="w-5 h-5 animate-spin" />
                            Processing...
                        </span>
                    ) : (
                        'EXECUTE SWAP'
                    )}
                </ActionButton>

                {!isConnected && (
                    <p className="text-xs font-mono text-center mt-3 text-gray-600">
                        ⚠️ Connect your wallet first to play
                    </p>
                )}
            </div>

            {/* Bottom CTA */}
            <button className="btn-brutal w-full bg-pink-200 border-[3px] border-black shadow-brutal-sm rounded-lg py-2 font-mono text-sm font-semibold hover:bg-pink-300 transition-all">
                How to start
            </button>
        </div>
    );
}
