import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import toast from 'react-hot-toast'

const useFavoritesStore = create(
  persist(
    (set, get) => ({
      favorites: [], // Array of hotel IDs

      // Actions
      addToFavorites: (hotel) => {
        const state = get()
        const isAlreadyFavorite = state.favorites.find(fav => fav.id === hotel.id)
        
        if (isAlreadyFavorite) {
          toast.error('Khách sạn đã có trong danh sách yêu thích')
          return false
        }

        set(state => ({
          favorites: [...state.favorites, {
            id: hotel.id,
            ten: hotel.ten,
            dia_chi: hotel.dia_chi,
            hinh_anh: hotel.hinh_anh,
            so_sao: hotel.so_sao,
            gia_thap_nhat: hotel.gia_thap_nhat,
            rating: hotel.rating,
            reviews_count: hotel.reviews_count,
            addedAt: new Date().toISOString()
          }]
        }))
        
        toast.success('Đã thêm vào danh sách yêu thích')
        return true
      },

      removeFromFavorites: (hotelId) => {
        set(state => ({
          favorites: state.favorites.filter(fav => fav.id !== hotelId)
        }))
        toast.success('Đã xóa khỏi danh sách yêu thích')
      },

      isFavorite: (hotelId) => {
        const state = get()
        return state.favorites.some(fav => fav.id === hotelId)
      },

      toggleFavorite: (hotel) => {
        const state = get()
        const isFav = state.isFavorite(hotel.id)
        
        if (isFav) {
          state.removeFromFavorites(hotel.id)
          return false
        } else {
          return state.addToFavorites(hotel)
        }
      },

      clearFavorites: () => {
        set({ favorites: [] })
        toast.success('Đã xóa tất cả yêu thích')
      },

      getFavoritesCount: () => {
        const state = get()
        return state.favorites.length
      }
    }),
    {
      name: 'favorites-storage',
      partialize: (state) => ({ favorites: state.favorites }),
    }
  )
)

export { useFavoritesStore }