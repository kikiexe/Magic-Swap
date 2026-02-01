import { createNetworkConfig, SuiClientProvider, WalletProvider } from '@mysten/dapp-kit';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { getFullnodeUrl } from '@mysten/sui.js/client';
import '@mysten/dapp-kit/dist/index.css';

// Configure Sui network
const { networkConfig } = createNetworkConfig({
    testnet: { url: getFullnodeUrl('testnet') },
    devnet: { url: getFullnodeUrl('devnet') },
    mainnet: { url: getFullnodeUrl('mainnet') },
});

// Create React Query client
const queryClient = new QueryClient();

export default function SuiProvider({ children }) {
    return (
        <QueryClientProvider client={queryClient}>
            <SuiClientProvider networks={networkConfig} defaultNetwork="testnet">
                <WalletProvider autoConnect>
                    {children}
                </WalletProvider>
            </SuiClientProvider>
        </QueryClientProvider>
    );
}
