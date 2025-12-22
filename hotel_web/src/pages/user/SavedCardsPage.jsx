import React, { useState } from 'react'
import { motion } from 'framer-motion'
import { CreditCard, Plus, Trash2, CheckCircle } from 'lucide-react'
import toast from 'react-hot-toast'

const SavedCardsPage = () => {
  const [savedCards, setSavedCards] = useState([])

  const handleAddCard = () => {
    toast.info('Tính năng thêm thẻ đang phát triển')
  }

  const handleDeleteCard = (cardId) => {
    if (window.confirm('Bạn có chắc chắn muốn xóa thẻ này?')) {
      setSavedCards(savedCards.filter(card => card.id !== cardId))
      toast.success('Đã xóa thẻ thành công')
    }
  }

  const maskCardNumber = (number) => {
    if (!number) return '**** **** **** ****'
    const cleaned = number.replace(/\s/g, '')
    return '**** **** **** ' + cleaned.slice(-4)
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-br from-blue-600 via-blue-500 to-blue-700 text-white">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 pt-20 pb-8">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 bg-white/20 rounded-lg flex items-center justify-center">
                <CreditCard size={24} />
              </div>
              <div>
                <h1 className="text-3xl font-bold mb-2">Thẻ đã lưu</h1>
                <p className="text-blue-100">Quản lý thẻ thanh toán của bạn</p>
              </div>
            </div>
            <button
              onClick={handleAddCard}
              className="bg-white/20 hover:bg-white/30 rounded-lg px-4 py-2 flex items-center gap-2 transition-colors"
            >
              <Plus size={20} />
              <span>Thêm thẻ</span>
            </button>
          </div>
        </div>
      </div>

      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 -mt-8 pb-8">
        {savedCards.length === 0 ? (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-white rounded-xl shadow-sm p-12 text-center"
          >
            <CreditCard size={80} className="mx-auto text-gray-300 mb-6" />
            <h3 className="text-xl font-semibold text-gray-900 mb-2">
              Chưa có thẻ nào được lưu
            </h3>
            <p className="text-gray-500 mb-8 max-w-md mx-auto">
              Thêm thẻ thanh toán để đặt phòng nhanh hơn trong lần sau. 
              Thông tin thẻ của bạn được mã hóa và bảo mật an toàn.
            </p>
            <button
              onClick={handleAddCard}
              className="bg-blue-600 text-white px-8 py-3 rounded-lg font-semibold hover:bg-blue-700 transition-colors flex items-center gap-2 mx-auto"
            >
              <Plus size={20} />
              Thêm thẻ mới
            </button>
          </motion.div>
        ) : (
          <div className="space-y-4">
            {savedCards.map((card) => (
              <motion.div
                key={card.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="bg-white rounded-xl shadow-sm p-6 hover:shadow-md transition-shadow"
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-4">
                    <div className="w-16 h-16 bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg flex items-center justify-center">
                      <CreditCard size={32} className="text-white" />
                    </div>
                    <div>
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-semibold text-gray-900">
                          {maskCardNumber(card.number)}
                        </h3>
                        {card.isDefault && (
                          <span className="px-2 py-0.5 bg-blue-100 text-blue-700 rounded text-xs font-medium">
                            Mặc định
                          </span>
                        )}
                      </div>
                      <p className="text-sm text-gray-500">{card.name}</p>
                      <p className="text-xs text-gray-400">
                        Hết hạn: {card.expiryMonth}/{card.expiryYear}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    {card.isDefault && (
                      <span className="px-3 py-1 bg-green-100 text-green-700 rounded-full text-xs font-medium flex items-center gap-1">
                        <CheckCircle size={14} />
                        Mặc định
                      </span>
                    )}
                    <button
                      onClick={() => handleDeleteCard(card.id)}
                      className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                    >
                      <Trash2 size={20} />
                    </button>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        )}

        {/* Security Notice */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.2 }}
          className="bg-blue-50 rounded-xl p-6 mt-6"
        >
          <h3 className="font-semibold text-blue-900 mb-2">Bảo mật thông tin</h3>
          <ul className="space-y-1 text-sm text-blue-800">
            <li className="flex items-start gap-2">
              <span className="text-blue-600 mt-1">•</span>
              <span>Thông tin thẻ của bạn được mã hóa và lưu trữ an toàn</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-blue-600 mt-1">•</span>
              <span>Chúng tôi không lưu trữ mã CVV của thẻ</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-blue-600 mt-1">•</span>
              <span>Bạn có thể xóa thẻ bất cứ lúc nào</span>
            </li>
          </ul>
        </motion.div>
      </div>
    </div>
  )
}

export default SavedCardsPage

