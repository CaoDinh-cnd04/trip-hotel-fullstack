import React from 'react'
import { clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

const cn = (...inputs) => {
  return twMerge(clsx(inputs))
}

const Button = React.forwardRef(({ className, variant = "default", size = "default", asChild = false, ...props }, ref) => {
  const Comp = asChild ? "span" : "button"
  
  const variants = {
    default: "bg-gradient-to-r from-purple-600 to-blue-600 text-white hover:from-purple-700 hover:to-blue-700 focus:ring-purple-500 shadow-lg hover:shadow-xl transform hover:scale-105",
    destructive: "bg-gradient-to-r from-red-500 to-red-600 text-white hover:from-red-600 hover:to-red-700 focus:ring-red-500 shadow-lg hover:shadow-xl",
    outline: "border-2 border-purple-200 bg-transparent text-purple-700 hover:bg-purple-50 hover:border-purple-300 focus:ring-purple-500 transition-all duration-200",
    secondary: "bg-gradient-to-r from-gray-100 to-gray-200 text-gray-900 hover:from-gray-200 hover:to-gray-300 focus:ring-gray-500 shadow-md",
    ghost: "text-gray-700 hover:bg-gray-100 hover:text-gray-900 focus:ring-gray-500 transition-all duration-200",
    link: "text-purple-600 underline-offset-4 hover:underline focus:ring-purple-500 hover:text-purple-700"
  }
  
  const sizes = {
    default: "h-12 px-6 py-3",
    sm: "h-10 px-4 text-sm",
    lg: "h-14 px-8 text-lg",
    icon: "h-12 w-12"
  }

  return (
    <Comp
      className={cn(
        "inline-flex items-center justify-center rounded-xl font-semibold ring-offset-white transition-all duration-300 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 active:scale-95",
        variants[variant],
        sizes[size],
        className
      )}
      ref={ref}
      {...props}
    />
  )
})
Button.displayName = "Button"

export default Button