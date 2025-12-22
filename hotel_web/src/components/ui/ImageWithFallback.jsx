import React, { useState, useEffect } from 'react'

const ImageWithFallback = ({ 
  src, 
  alt, 
  className = '',
  fallbackSrc = null,
  ...props 
}) => {
  // Default fallback to backend images/default.jpg
  const defaultFallback = fallbackSrc || `${import.meta.env.VITE_API_ROOT_URL || 'http://localhost:5000'}/images/Defaut.jpg`
  // Ensure we always have a valid src
  const initialSrc = src || fallbackSrc || defaultFallback
  const [imgSrc, setImgSrc] = useState(initialSrc)
  const [isLoading, setIsLoading] = useState(true)
  const [hasError, setHasError] = useState(false)

  // Update image source when src prop changes
  useEffect(() => {
    if (src) {
      setImgSrc(src)
      setIsLoading(true)
      setHasError(false)
    } else {
      setImgSrc(fallbackSrc || defaultFallback)
    }
  }, [src, fallbackSrc])

  const handleError = () => {
    console.warn(`Image failed to load: ${imgSrc}`)
    const finalFallback = fallbackSrc || defaultFallback
    if (imgSrc !== finalFallback && imgSrc !== defaultFallback) {
      // Try fallback first
      setImgSrc(finalFallback)
      setHasError(false)
      setIsLoading(true)
    } else if (imgSrc !== defaultFallback) {
      // Try default fallback
      setImgSrc(defaultFallback)
      setHasError(false)
      setIsLoading(true)
    } else {
      // All fallbacks failed, but don't show error badge - just show placeholder
      setHasError(false)
      setIsLoading(false)
    }
  }

  const handleLoad = () => {
    setIsLoading(false)
  }

  return (
    <div className={`relative overflow-hidden ${className}`}>
      {isLoading && (
        <div className="absolute inset-0 bg-gray-200 animate-pulse flex items-center justify-center">
          <div className="text-gray-400 text-sm">Đang tải...</div>
        </div>
      )}
      
      <img
        src={imgSrc}
        alt={alt}
        className={`w-full h-full object-cover transition-opacity duration-300 ${
          isLoading ? 'opacity-0' : 'opacity-100'
        }`}
        onLoad={handleLoad}
        onError={handleError}
        {...props}
      />
      
      {hasError && imgSrc && !imgSrc.includes('Defaut.jpg') && (
        <div className="absolute top-2 right-2 bg-red-500 text-white text-xs px-2 py-1 rounded">
          Ảnh lỗi
        </div>
      )}
    </div>
  )
}

export default ImageWithFallback