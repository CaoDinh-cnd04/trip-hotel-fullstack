import React, { useState } from 'react'
import { motion } from 'framer-motion'
import { HelpCircle, MessageSquare, ChevronDown, ChevronUp, Send } from 'lucide-react'
import toast from 'react-hot-toast'

const HelpCenterPage = () => {
  const [activeTab, setActiveTab] = useState(0) // 0: FAQ, 1: Feedback
  const [expandedFAQ, setExpandedFAQ] = useState(null)
  const [feedbackData, setFeedbackData] = useState({
    category: 'general',
    title: '',
    content: ''
  })

  const faqItems = [
    {
      question: 'Làm thế nào để đặt phòng?',
      answer: 'Bạn có thể đặt phòng bằng cách tìm kiếm khách sạn trên trang chủ, chọn ngày check-in và check-out, số lượng khách, sau đó nhấn "Tìm kiếm". Chọn khách sạn phù hợp và làm theo hướng dẫn để hoàn tất đặt phòng.'
    },
    {
      question: 'Tôi có thể hủy đặt phòng không?',
      answer: 'Có, bạn có thể hủy đặt phòng trong phần "Lịch sử đặt phòng" của tài khoản. Tuy nhiên, chính sách hủy phòng phụ thuộc vào từng khách sạn và có thể có phí hủy phòng.'
    },
    {
      question: 'Những phương thức thanh toán nào được chấp nhận?',
      answer: 'Chúng tôi chấp nhận nhiều phương thức thanh toán bao gồm: Thẻ tín dụng/ghi nợ, Chuyển khoản ngân hàng, Ví điện tử (MoMo, ZaloPay), và thanh toán khi nhận phòng.'
    },
    {
      question: 'Làm thế nào để thay đổi thông tin đặt phòng?',
      answer: 'Bạn có thể thay đổi thông tin đặt phòng trong phần "Lịch sử đặt phòng". Tuy nhiên, một số thay đổi như ngày check-in/check-out có thể phụ thuộc vào chính sách của khách sạn.'
    },
    {
      question: 'Chính sách hoàn tiền như thế nào?',
      answer: 'Chính sách hoàn tiền phụ thuộc vào từng khách sạn và loại phòng. Thông thường, nếu hủy trước thời hạn quy định, bạn sẽ được hoàn tiền đầy đủ hoặc một phần tùy theo chính sách.'
    }
  ]

  const feedbackCategories = [
    { value: 'general', label: 'Chung' },
    { value: 'booking', label: 'Đặt phòng' },
    { value: 'payment', label: 'Thanh toán' },
    { value: 'technical', label: 'Kỹ thuật' },
    { value: 'other', label: 'Khác' }
  ]

  const handleSubmitFeedback = () => {
    if (!feedbackData.title || !feedbackData.content) {
      toast.error('Vui lòng điền đầy đủ thông tin')
      return
    }
    // TODO: Submit feedback to API
    toast.success('Cảm ơn bạn đã gửi phản hồi! Chúng tôi sẽ xem xét và phản hồi sớm nhất có thể.')
    setFeedbackData({ category: 'general', title: '', content: '' })
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-br from-blue-600 via-blue-500 to-blue-700 text-white">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 pt-20 pb-8">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 bg-white/20 rounded-lg flex items-center justify-center">
              <HelpCircle size={24} />
            </div>
            <div>
              <h1 className="text-3xl font-bold mb-2">Trung tâm trợ giúp</h1>
              <p className="text-blue-100">Tìm câu trả lời hoặc liên hệ với chúng tôi</p>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 -mt-8 pb-8">
        {/* Tabs */}
        <div className="bg-white rounded-xl shadow-sm mb-6 overflow-hidden">
          <div className="flex border-b border-gray-200">
            <button
              onClick={() => setActiveTab(0)}
              className={`flex-1 flex items-center justify-center gap-2 py-4 px-6 font-medium transition-colors ${
                activeTab === 0
                  ? 'text-blue-600 border-b-2 border-blue-600 bg-blue-50'
                  : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
              }`}
            >
              <HelpCircle size={18} />
              <span>Câu hỏi thường gặp</span>
            </button>
            <button
              onClick={() => setActiveTab(1)}
              className={`flex-1 flex items-center justify-center gap-2 py-4 px-6 font-medium transition-colors ${
                activeTab === 1
                  ? 'text-blue-600 border-b-2 border-blue-600 bg-blue-50'
                  : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
              }`}
            >
              <MessageSquare size={18} />
              <span>Gửi phản hồi</span>
            </button>
          </div>
        </div>

        {/* FAQ Tab */}
        {activeTab === 0 && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="space-y-4"
          >
            {faqItems.map((faq, index) => (
              <div
                key={index}
                className="bg-white rounded-xl shadow-sm overflow-hidden"
              >
                <button
                  onClick={() => setExpandedFAQ(expandedFAQ === index ? null : index)}
                  className="w-full flex items-center justify-between p-6 text-left hover:bg-gray-50 transition-colors"
                >
                  <span className="font-semibold text-gray-900 pr-4">{faq.question}</span>
                  {expandedFAQ === index ? (
                    <ChevronUp size={20} className="text-gray-400 flex-shrink-0" />
                  ) : (
                    <ChevronDown size={20} className="text-gray-400 flex-shrink-0" />
                  )}
                </button>
                {expandedFAQ === index && (
                  <div className="px-6 pb-6 text-gray-700 leading-relaxed">
                    {faq.answer}
                  </div>
                )}
              </div>
            ))}
          </motion.div>
        )}

        {/* Feedback Tab */}
        {activeTab === 1 && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-white rounded-xl shadow-sm p-6"
          >
            <h2 className="text-xl font-semibold text-gray-900 mb-6">Gửi phản hồi</h2>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Danh mục
                </label>
                <select
                  value={feedbackData.category}
                  onChange={(e) => setFeedbackData({...feedbackData, category: e.target.value})}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
                >
                  {feedbackCategories.map((cat) => (
                    <option key={cat.value} value={cat.value}>
                      {cat.label}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Tiêu đề
                </label>
                <input
                  type="text"
                  value={feedbackData.title}
                  onChange={(e) => setFeedbackData({...feedbackData, title: e.target.value})}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
                  placeholder="Nhập tiêu đề phản hồi"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Nội dung
                </label>
                <textarea
                  value={feedbackData.content}
                  onChange={(e) => setFeedbackData({...feedbackData, content: e.target.value})}
                  rows={6}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none resize-none"
                  placeholder="Mô tả chi tiết vấn đề hoặc đề xuất của bạn..."
                />
              </div>

              <button
                onClick={handleSubmitFeedback}
                className="w-full bg-blue-600 text-white py-3 px-4 rounded-lg font-semibold hover:bg-blue-700 transition-colors flex items-center justify-center gap-2"
              >
                <Send size={20} />
                Gửi phản hồi
              </button>
            </div>
          </motion.div>
        )}
      </div>
    </div>
  )
}

export default HelpCenterPage

