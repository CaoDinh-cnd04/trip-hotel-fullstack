import React, { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { ChevronDown, Globe } from 'lucide-react'
import { useLanguageStore } from '../../stores/languageStore'

const LanguageSelector = () => {
  const [isOpen, setIsOpen] = useState(false)
  const { currentLanguage, setLanguage, getFlagEmoji } = useLanguageStore()

  const languages = [
    {
      code: 'vi',
      name: 'Tiếng Việt',
      flag: '🇻🇳'
    },
    {
      code: 'en', 
      name: 'English',
      flag: '🇺🇸'
    }
  ]

  const currentLang = languages.find(lang => lang.code === currentLanguage)

  const handleLanguageChange = (langCode) => {
    setLanguage(langCode)
    setIsOpen(false)
  }

  return (
    <div className="relative">
      {/* Language Button */}
      <motion.button
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95 }}
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center space-x-1 px-2 py-2 text-gray-600 hover:text-purple-600 transition-colors duration-200 rounded-lg hover:bg-gray-100"
        title={currentLang?.name}
      >
        <span className="text-xl">{currentLang?.flag}</span>
        <ChevronDown className={`w-3 h-3 transition-transform duration-200 ${isOpen ? 'rotate-180' : ''}`} />
      </motion.button>

      {/* Language Dropdown */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, y: -10, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -10, scale: 0.95 }}
            className="absolute right-0 mt-2 w-48 bg-white rounded-xl shadow-2xl ring-1 ring-black ring-opacity-5 z-50 overflow-hidden"
          >
            <div className="py-2">
              {languages.map((language) => (
                <motion.button
                  key={language.code}
                  whileHover={{ backgroundColor: '#f8fafc' }}
                  onClick={() => handleLanguageChange(language.code)}
                  className={`w-full text-left px-4 py-3 flex items-center space-x-3 transition-colors duration-150 ${
                    currentLanguage === language.code 
                      ? 'bg-purple-50 text-purple-700 border-r-4 border-purple-500' 
                      : 'text-gray-700 hover:bg-gray-50'
                  }`}
                >
                  <span className="text-lg">{language.flag}</span>
                  <span className="font-medium">{language.name}</span>
                  {currentLanguage === language.code && (
                    <motion.div
                      initial={{ scale: 0 }}
                      animate={{ scale: 1 }}
                      className="ml-auto w-2 h-2 bg-purple-500 rounded-full"
                    />
                  )}
                </motion.button>
              ))}
            </div>
            
            {/* Footer */}
            <div className="px-4 py-2 border-t border-gray-100 bg-gray-50">
              <div className="flex items-center space-x-2 text-xs text-gray-500">
                <Globe className="w-3 h-3" />
                <span>Language / Ngôn ngữ</span>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Backdrop */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black bg-opacity-20 z-40"
            onClick={() => setIsOpen(false)}
          />
        )}
      </AnimatePresence>
    </div>
  )
}

export default LanguageSelector