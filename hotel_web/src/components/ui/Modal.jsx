import React from 'react'
import { clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

const cn = (...inputs) => {
  return twMerge(clsx(inputs))
}

const Modal = ({ isOpen, onClose, children, className }) => {
  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <div 
        className="fixed inset-0 bg-black bg-opacity-50 transition-opacity"
        onClick={onClose}
      />
      
      {/* Modal */}
      <div className={cn(
        "relative bg-white rounded-lg shadow-lg max-w-lg w-full mx-4 max-h-[90vh] overflow-auto",
        className
      )}>
        {children}
      </div>
    </div>
  )
}

const ModalHeader = ({ children, className }) => (
  <div className={cn("px-6 py-4 border-b border-gray-200", className)}>
    {children}
  </div>
)

const ModalContent = ({ children, className }) => (
  <div className={cn("px-6 py-4", className)}>
    {children}
  </div>
)

const ModalFooter = ({ children, className }) => (
  <div className={cn("px-6 py-4 border-t border-gray-200 flex justify-end space-x-2", className)}>
    {children}
  </div>
)

export { Modal, ModalHeader, ModalContent, ModalFooter }
export default Modal