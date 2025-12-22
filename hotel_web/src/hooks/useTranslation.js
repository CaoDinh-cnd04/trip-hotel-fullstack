import { useLanguageStore } from '../stores/languageStore'
import { translations } from '../utils/translations'

export const useTranslation = () => {
  const { currentLanguage } = useLanguageStore()
  
  const t = (key) => {
    const keys = key.split('.')
    let value = translations[currentLanguage]
    
    for (const k of keys) {
      value = value?.[k]
    }
    
    return value || key
  }
  
  return { t, currentLanguage }
}