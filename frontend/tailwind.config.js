/** @type {import('tailwindcss').Config} */
export default {
    content: [
        "./src/**/*.{js,ts,jsx,tsx}",
    ],
    theme: {
        extend: {
            colors: {
                'retro-yellow': '#FFC107',
                'retro-pink': '#FFC0CB',
                'retro-blue': '#87CEEB',
                'retro-mint': '#98FF98',
                'saweria-blue': '#A8DADC',
                'saweria-orange': '#F4A261',
            },
            fontFamily: {
                'heading': ['Quicksand', 'sans-serif'],
                'mono': ['Space Mono', 'Courier Prime', 'monospace'],
            },
            boxShadow: {
                'brutal': '6px 6px 0px 0px rgba(0,0,0,1)',
                'brutal-lg': '8px 8px 0px 0px rgba(0,0,0,1)',
                'brutal-xl': '10px 10px 0px 0px rgba(0,0,0,1)',
                'brutal-sm': '4px 4px 0px 0px rgba(0,0,0,1)',
            },
        },
    },
    plugins: [],
}
