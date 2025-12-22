import React from 'react'

/**
 * Select Component
 * A styled select dropdown component
 */
const Select = React.forwardRef(({ 
  children, 
  className = '', 
  error,
  label,
  helperText,
  ...props 
}, ref) => {
  const baseClasses = `
    w-full px-3 py-2 
    border rounded-lg 
    bg-white dark:bg-gray-800
    text-gray-900 dark:text-gray-100
    focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent
    transition-colors duration-200
    disabled:bg-gray-100 disabled:cursor-not-allowed disabled:opacity-50
    ${error ? 'border-red-500 focus:ring-red-500' : 'border-gray-300 dark:border-gray-600'}
    ${className}
  `.trim().replace(/\s+/g, ' ')

  return (
    <div className="w-full">
      {label && (
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
          {label}
          {props.required && <span className="text-red-500 ml-1">*</span>}
        </label>
      )}
      <select
        ref={ref}
        className={baseClasses}
        {...props}
      >
        {children}
      </select>
      {error && (
        <p className="mt-1 text-sm text-red-600 dark:text-red-400">{error}</p>
      )}
      {helperText && !error && (
        <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">{helperText}</p>
      )}
    </div>
  )
})

Select.displayName = 'Select'

export default Select

