import { create } from 'zustand'
import { persist } from 'zustand/middleware'

const useLanguageStore = create(
  persist(
    (set, get) => ({
      currentLanguage: 'vi', // 'vi' hoặc 'en'
      
      // Actions
      setLanguage: (language) => {
        set({ currentLanguage: language })
      },
      
      toggleLanguage: () => {
        const currentLang = get().currentLanguage
        const newLang = currentLang === 'vi' ? 'en' : 'vi'
        set({ currentLanguage: newLang })
      },
      
      // Helper functions
      isVietnamese: () => get().currentLanguage === 'vi',
      isEnglish: () => get().currentLanguage === 'en',
      
      // Get flag emoji
      getFlagEmoji: () => {
        return get().currentLanguage === 'vi' ? '🇻🇳' : '🇺🇸'
      },
      
      // Get language name
      getLanguageName: () => {
        return get().currentLanguage === 'vi' ? 'Tiếng Việt' : 'English'
      }
    }),
    {
      name: 'language-storage'
    }
  )
)

export { useLanguageStore }