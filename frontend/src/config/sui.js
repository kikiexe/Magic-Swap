// Sui Network Configuration
export const NETWORK = 'testnet'; // or 'devnet' or 'mainnet'

// Smart Contract Configuration
export const PACKAGE_ID = '0x64e29aefcfdb5da6240222d92c34538fa0c9dc793d87e3f6b29adde987386017';
export const GAME_OBJECT_ID = '0xf7575e1cc828f5d425c7e06c04f2b93de9448213dcdcf18133a3b71a5ab35bb0';

// Random Oracle Object ID (Sui's built-in random)
export const RANDOM_OBJECT_ID = '0x8';

export const CONTRACT_CONFIG = {
    packageId: PACKAGE_ID,
    module: 'game',
    functions: {
        swap: 'swap',
        deposit: 'deposit',
        withdraw: 'withdraw',
    },
};
