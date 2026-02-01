import { useCurrentAccount, useCurrentWallet, useConnectWallet, useDisconnectWallet } from '@mysten/dapp-kit';
import { useSuiClientQuery } from '@mysten/dapp-kit';

export function useWallet() {
    const currentAccount = useCurrentAccount();
    const { currentWallet, connectionStatus } = useCurrentWallet();
    const { mutate: connect } = useConnectWallet();
    const { mutate: disconnect } = useDisconnectWallet();

    // Get wallet balance
    const { data: balance } = useSuiClientQuery(
        'getBalance',
        {
            owner: currentAccount?.address || '',
            coinType: '0x2::sui::SUI',
        },
        {
            enabled: !!currentAccount,
        }
    );

    const balanceInSui = balance ? Number(balance.totalBalance) / 1_000_000_000 : 0;

    return {
        address: currentAccount?.address,
        isConnected: connectionStatus === 'connected',
        wallet: currentWallet,
        balance: balanceInSui,
        connect,
        disconnect,
    };
}
