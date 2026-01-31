import React from 'react';

export default function ActionButton({
    children,
    onClick,
    fullWidth = true,
    variant = 'primary'
}) {
    const baseClasses = "btn-brutal font-heading font-bold px-6 py-3 border-[3px] border-black rounded-lg transition-all duration-150 cursor-pointer";

    const variantClasses = {
        primary: "bg-saweria-orange shadow-brutal hover:bg-[#E8995A]",
        secondary: "bg-saweria-blue shadow-brutal hover:bg-[#96CED0]",
        pink: "bg-retro-pink shadow-brutal hover:bg-[#FFB3C0]"
    };

    const widthClass = fullWidth ? "w-full" : "";

    return (
        <button
            onClick={onClick}
            className={`${baseClasses} ${variantClasses[variant]} ${widthClass}`}
        >
            {children}
        </button>
    );
}
