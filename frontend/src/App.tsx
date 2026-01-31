import { ConnectButton } from '@mysten/dapp-kit';

function App() {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gray-900 text-white">
      <header className="flex flex-col items-center gap-4">
        <h1 className="text-4xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-purple-400 to-pink-600">
          Magic Swap
        </h1>
        <p className="text-gray-400">Risk-Bounded GameFi Trading via Sui</p>

        <div className="mt-6">
          <ConnectButton />
        </div>
      </header>
    </div>
  )
}

export default App
