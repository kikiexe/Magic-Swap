import React from 'react';
import { X } from 'lucide-react';

export default function OutcomePopup({ isOpen, onClose, result }) {
    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            {/* Dark backdrop */}
            <div
                className="absolute inset-0 bg-black/80"
                onClick={onClose}
            />

            {/* Confetti for victory */}
            {result?.success && (
                <div className="absolute inset-0 pointer-events-none overflow-hidden">
                    {[...Array(50)].map((_, i) => (
                        <div
                            key={i}
                            className="absolute w-3 h-3 animate-confetti"
                            style={{
                                left: `${Math.random() * 100}%`,
                                top: `-${Math.random() * 20}%`,
                                backgroundColor: ['#FFD700', '#FF6B6B', '#4ECDC4', '#45B7D1', '#FFA07A'][Math.floor(Math.random() * 5)],
                                animationDelay: `${Math.random() * 3}s`,
                                animationDuration: `${2 + Math.random() * 2}s`,
                                transform: `rotate(${Math.random() * 360}deg)`
                            }}
                        />
                    ))}
                </div>
            )}

            {/* BOMBASTIC Modal - Compact */}
            <div className="relative bg-gradient-to-b from-gray-900 via-blue-950 to-gray-900 border-[6px] border-yellow-400 rounded-2xl p-6 max-w-2xl w-full mx-4 animate-scaleIn"
                style={{
                    boxShadow: '0 0 60px rgba(251, 191, 36, 0.6), inset 0 0 40px rgba(0,0,0,0.5)'
                }}
            >
                {/* Close Button */}
                <button
                    onClick={onClose}
                    className="absolute top-4 right-4 p-3 bg-red-600 hover:bg-red-500 rounded-lg border-[3px] border-black z-10 transition-all"
                >
                    <X className="w-6 h-6 text-white" />
                </button>

                {/* BOMBASTIC Content */}
                <div className="text-center space-y-8">
                    {/* Decorative frame corners */}
                    <div className="absolute top-0 left-0 w-20 h-20 border-t-[5px] border-l-[5px] border-yellow-400"></div>
                    <div className="absolute top-0 right-0 w-20 h-20 border-t-[5px] border-r-[5px] border-yellow-400"></div>
                    <div className="absolute bottom-0 left-0 w-20 h-20 border-b-[5px] border-l-[5px] border-yellow-400"></div>
                    <div className="absolute bottom-0 right-0 w-20 h-20 border-b-[5px] border-r-[5px] border-yellow-400"></div>

                    {/* Health bars style decoration */}
                    <div className="flex justify-between px-6 mb-6">
                        <div className="w-40 h-4 bg-gray-700 border-[3px] border-yellow-400">
                            <div className="h-full bg-gradient-to-r from-pink-500 to-purple-500 w-3/4"></div>
                        </div>
                        <div className="w-40 h-4 bg-gray-700 border-[3px] border-yellow-400">
                            <div className="h-full bg-gradient-to-r from-blue-500 to-cyan-500 w-3/4"></div>
                        </div>
                    </div>

                    {/* Zeus Character - Properly sized */}
                    <div className="relative">
                        <div className="w-full max-w-lg h-52 mx-auto bg-gradient-to-br from-blue-900 via-purple-900 to-blue-900 border-[5px] border-yellow-400 rounded-2xl shadow-[0_0_50px_rgba(251,191,36,0.7)] flex items-center justify-center overflow-hidden">
                            {/* Zeus Pixel Art - FULL BODY VERSION */}
                            <img
                                src="/zeus-large.png"
                                alt="Zeus"
                                className="w-full h-full object-cover animate-pulse"
                                style={{
                                    filter: 'drop-shadow(0 0 20px rgba(251, 191, 36, 0.8))'
                                }}
                            />
                        </div>
                        {/* Glowing effect particles - MORE */}
                        <div className="absolute -top-6 -right-6 text-5xl animate-bounce">⚡</div>
                        <div className="absolute -bottom-6 -left-6 text-5xl animate-bounce" style={{ animationDelay: '0.2s' }}>✨</div>
                        <div className="absolute -top-6 -left-6 text-5xl animate-bounce" style={{ animationDelay: '0.4s' }}>💫</div>
                        <div className="absolute -bottom-6 -right-6 text-5xl animate-bounce" style={{ animationDelay: '0.6s' }}>🌟</div>
                    </div>

                    {/* Result Box - BIGGER */}
                    <div className="relative">
                        <div className={`border-[4px] ${result?.success ? 'border-green-400 bg-gradient-to-r from-green-900 to-emerald-900' : 'border-red-400 bg-gradient-to-r from-red-900 to-rose-900'} p-5 rounded-xl`}>
                            <p className="font-heading text-3xl font-bold text-white mb-3 uppercase" style={{
                                textShadow: '3px 3px 0px rgba(0,0,0,1)'
                            }}>
                                {result?.success ? '🎉 VICTORY!' : '💀 DEFEAT!'}
                            </p>
                            <div className="bg-black/50 border-[3px] border-yellow-400 p-4 rounded-lg">
                                <p className="font-mono text-xl font-bold text-yellow-400">
                                    {result?.message || 'Swap completed!'}
                                </p>
                            </div>
                        </div>
                        {/* Pixel corners */}
                        <div className="absolute -top-3 -left-3 w-6 h-6 bg-yellow-400 border-[2px] border-black"></div>
                        <div className="absolute -top-3 -right-3 w-6 h-6 bg-yellow-400 border-[2px] border-black"></div>
                        <div className="absolute -bottom-3 -left-3 w-6 h-6 bg-yellow-400 border-[2px] border-black"></div>
                        <div className="absolute -bottom-3 -right-3 w-6 h-6 bg-yellow-400 border-[2px] border-black"></div>
                    </div>

                    {/* Swap Details */}
                    {result?.details && (
                        <div className="bg-gray-900 border-[4px] border-cyan-400 p-6 rounded-xl">
                            <p className="font-mono text-xl text-cyan-400 mb-3 font-bold">
                                {result.fromAmount} {result.fromCoin} ➜ 1 BTC ₿
                            </p>
                            <p className="font-mono text-base text-gray-300">
                                {result.details}
                            </p>
                        </div>
                    )}

                    {/* Continue Button */}
                    <button
                        onClick={onClose}
                        className="w-full bg-gradient-to-r from-yellow-400 to-orange-500 border-[4px] border-black font-heading font-bold text-2xl py-4 rounded-xl hover:scale-105 transition-transform uppercase"
                        style={{
                            boxShadow: '6px 6px 0px rgba(0,0,0,1)',
                            textShadow: '2px 2px 0px rgba(0,0,0,0.5)'
                        }}
                    >
                        CONTINUE
                    </button>
                </div>
            </div>
        </div>
    );
}
