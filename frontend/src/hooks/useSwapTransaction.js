import { useCurrentAccount, useSignAndExecuteTransaction } from '@mysten/dapp-kit';
import { Transaction } from '@mysten/sui/transactions';
import { useState } from 'react';
import { CONTRACT_CONFIG, GAME_OBJECT_ID, RANDOM_OBJECT_ID } from '../config/sui';

export function useSwapTransaction() {
    const [isLoading, setIsLoading] = useState(false);
    const { mutateAsync: signAndExecute } = useSignAndExecuteTransaction();
    const currentAccount = useCurrentAccount();

    const executeSwap = async (coinAmount) => {
        if (!currentAccount) {
            throw new Error('Please connect your wallet first!');
        }

        setIsLoading(true);

        try {
            const tx = new Transaction();

            // Split coin from gas
            const [coin] = tx.splitCoins(tx.gas, [coinAmount]);

            // Call swap function
            tx.moveCall({
                target: `${CONTRACT_CONFIG.packageId}::${CONTRACT_CONFIG.module}::${CONTRACT_CONFIG.functions.swap}`,
                arguments: [
                    tx.object(GAME_OBJECT_ID),
                    tx.object(RANDOM_OBJECT_ID),
                    coin,
                ],
            });

            const result = await signAndExecute({
                transaction: tx,
                options: {
                    showEffects: true,
                    showEvents: true,
                },
            });

            console.log('Transaction result:', result);

            // Parse the outcome from events
            const outcomeEvent = result.events?.find(
                (e) => e.type.includes('OutcomeEvent')
            );

            if (outcomeEvent) {
                const { wager, payout, outcome } = outcomeEvent.parsedJson;

                // outcome: 0 = Loss, 1 = Small Win, 2 = Big Win
                const success = outcome !== 0;

                return {
                    success,
                    fromCoin: 'SUI',
                    fromAmount: wager / 1_000_000_000, // Convert from MIST to SUI
                    payout: payout / 1_000_000_000,
                    outcome,
                    transactionDigest: result.digest,
                    message: getOutcomeMessage(outcome, wager, payout),
                    details: getOutcomeDetails(outcome, wager, payout),
                };
            }

            // Fallback: Transaction succeeded but couldn't parse events
            // This still means the swap executed successfully on-chain
            console.warn('Could not parse event, but transaction succeeded:', result.digest);
            return {
                success: true,
                fromCoin: 'SUI',
                fromAmount: coinAmount / 1_000_000_000,
                payout: 0,
                outcome: -1,
                transactionDigest: result.digest,
                message: 'Swap executed successfully! ✅',
                details: `Transaction completed on Sui blockchain. Check explorer for details: ${result.digest}`,
            };
        } catch (error) {
            console.error('Swap transaction error:', error);
            throw error;
        } finally {
            setIsLoading(false);
        }
    };

    return {
        executeSwap,
        isLoading,
    };
}

function getOutcomeMessage(outcome, wager, payout) {
    const wagerSui = wager / 1_000_000_000;
    const payoutSui = payout / 1_000_000_000;

    if (outcome === 0) {
        // Loss - returned 80%
        const lost = wagerSui - payoutSui;
        return `Lost ${lost.toFixed(4)} SUI 😢`;
    } else if (outcome === 1) {
        // Small win - 1.1x
        const profit = payoutSui - wagerSui;
        return `Won ${profit.toFixed(4)} SUI! 🎉`;
    } else {
        // Big win - 2x
        const profit = payoutSui - wagerSui;
        return `BIG WIN! Won ${profit.toFixed(4)} SUI! 🚀`;
    }
}

function getOutcomeDetails(outcome, wager, payout) {
    const wagerSui = wager / 1_000_000_000;
    const payoutSui = payout / 1_000_000_000;

    if (outcome === 0) {
        const kept = payoutSui;
        return `You lost 20% of your wager. You kept ${kept.toFixed(4)} SUI (80%).`;
    } else if (outcome === 1) {
        return `Small win! Your ${wagerSui.toFixed(4)} SUI turned into ${payoutSui.toFixed(4)} SUI (1.1x).`;
    } else {
        return `JACKPOT! Your ${wagerSui.toFixed(4)} SUI turned into ${payoutSui.toFixed(4)} SUI (2.0x)!`;
    }
}
