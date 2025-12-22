import React, { useState } from 'react'
import { MessageCircle, X, Send, User } from 'lucide-react'
import { motion, AnimatePresence } from 'framer-motion'
import { Badge } from 'react-bootstrap'

const ChatWidget = ({ hotelName = 'Khách sạn' }) => {
  const [isOpen, setIsOpen] = useState(false)
  const [messages, setMessages] = useState([
    {
      id: 1,
      text: `Xin chào! Tôi là trợ lý ảo của ${hotelName}. Tôi có thể giúp gì cho bạn?`,
      sender: 'bot',
      timestamp: new Date().toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })
    }
  ])
  const [inputMessage, setInputMessage] = useState('')

  // Các câu hỏi gợi ý
  const quickQuestions = [
    '📅 Chính sách hủy phòng như thế nào?',
    '🕐 Giờ nhận/trả phòng là mấy giờ?',
    '🚗 Có chỗ đậu xe không?',
    '🍳 Bao gồm bữa sáng không?',
    '🏊 Có hồ bơi và gym không?',
    '💳 Các hình thức thanh toán được chấp nhận?',
  ]

  // Câu trả lời tự động
  const getAutoResponse = (question) => {
    const responses = {
      'hủy phòng': 'Chính sách hủy phòng:\n- Hủy trước 7 ngày: Hoàn 100%\n- Hủy trước 3 ngày: Hoàn 50%\n- Hủy trong vòng 3 ngày: Không hoàn tiền\n\nBạn có thể liên hệ trực tiếp để được hỗ trợ thêm.',
      'nhận phòng': 'Thời gian nhận/trả phòng:\n- Nhận phòng: Từ 14:00\n- Trả phòng: Trước 12:00\n\nBạn có thể yêu cầu check-in sớm hoặc check-out muộn tùy tình trạng phòng.',
      'trả phòng': 'Thời gian nhận/trả phòng:\n- Nhận phòng: Từ 14:00\n- Trả phòng: Trước 12:00\n\nBạn có thể yêu cầu check-in sớm hoặc check-out muộn tùy tình trạng phòng.',
      'đậu xe': 'Chúng tôi có bãi đậu xe miễn phí cho khách lưu trú. Bãi xe được bảo vệ 24/7 và có camera an ninh. Vui lòng thông báo biển số xe khi check-in.',
      'bữa sáng': 'Bữa sáng buffet được phục vụ từ 6:30 - 10:00 tại nhà hàng tầng 1. Thực đơn đa dạng với món Á - Âu. Giá: 150.000đ/người (hoặc miễn phí tùy gói đặt phòng).',
      'hồ bơi': 'Tiện nghi khách sạn:\n- Hồ bơi ngoài trời: Mở cửa 6:00 - 22:00\n- Phòng gym: Mở cửa 24/7\n- Spa & Massage: 9:00 - 21:00\n\nTất cả miễn phí cho khách lưu trú.',
      'gym': 'Tiện nghi khách sạn:\n- Hồ bơi ngoài trời: Mở cửa 6:00 - 22:00\n- Phòng gym: Mở cửa 24/7\n- Spa & Massage: 9:00 - 21:00\n\nTất cả miễn phí cho khách lưu trú.',
      'thanh toán': 'Chúng tôi chấp nhận các hình thức thanh toán:\n- Tiền mặt (VNĐ)\n- Thẻ tín dụng/ghi nợ (Visa, Mastercard, JCB)\n- Chuyển khoản ngân hàng\n- Ví điện tử (MoMo, ZaloPay, VNPay)',
      'default': 'Cảm ơn câu hỏi của bạn! Để được hỗ trợ chi tiết hơn, vui lòng:\n📞 Gọi hotline: 1900 xxxx\n📧 Email: support@hotel.com\n💬 Hoặc để lại số điện thoại, nhân viên sẽ liên hệ lại trong 5 phút.'
    }

    const lowerQuestion = question.toLowerCase()
    for (const [key, response] of Object.entries(responses)) {
      if (key !== 'default' && lowerQuestion.includes(key)) {
        return response
      }
    }
    return responses.default
  }

  const handleQuickQuestion = (question) => {
    // Thêm tin nhắn của người dùng
    const userMessage = {
      id: messages.length + 1,
      text: question,
      sender: 'user',
      timestamp: new Date().toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })
    }

    setMessages(prev => [...prev, userMessage])

    // Sau 1 giây, bot trả lời
    setTimeout(() => {
      const botResponse = {
        id: messages.length + 2,
        text: getAutoResponse(question),
        sender: 'bot',
        timestamp: new Date().toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })
      }
      setMessages(prev => [...prev, botResponse])
    }, 1000)
  }

  const handleSendMessage = (e) => {
    e.preventDefault()
    if (!inputMessage.trim()) return

    const userMessage = {
      id: messages.length + 1,
      text: inputMessage,
      sender: 'user',
      timestamp: new Date().toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })
    }

    setMessages(prev => [...prev, userMessage])
    setInputMessage('')

    // Bot trả lời sau 1 giây
    setTimeout(() => {
      const botResponse = {
        id: messages.length + 2,
        text: getAutoResponse(inputMessage),
        sender: 'bot',
        timestamp: new Date().toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })
      }
      setMessages(prev => [...prev, botResponse])
    }, 1000)
  }

  return (
    <>
      {/* Chat Button */}
      <AnimatePresence>
        {!isOpen && (
          <motion.button
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            exit={{ scale: 0 }}
            whileHover={{ scale: 1.1 }}
            whileTap={{ scale: 0.9 }}
            onClick={() => setIsOpen(true)}
            style={{
              position: 'fixed',
              bottom: '24px',
              right: '24px',
              width: '64px',
              height: '64px',
              borderRadius: '50%',
              backgroundColor: '#0d6efd',
              border: 'none',
              boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
              cursor: 'pointer',
              zIndex: 1000,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'white'
            }}
          >
            <MessageCircle size={32} />
            <Badge
              bg="danger"
              pill
              style={{
                position: 'absolute',
                top: '8px',
                right: '8px',
                fontSize: '10px'
              }}
            >
              1
            </Badge>
          </motion.button>
        )}
      </AnimatePresence>

      {/* Chat Window */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, y: 100, scale: 0.8 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 100, scale: 0.8 }}
            transition={{ type: 'spring', damping: 25, stiffness: 300 }}
            style={{
              position: 'fixed',
              bottom: '24px',
              right: '24px',
              width: '380px',
              height: '600px',
              backgroundColor: 'white',
              borderRadius: '16px',
              boxShadow: '0 8px 32px rgba(0,0,0,0.12)',
              zIndex: 1000,
              display: 'flex',
              flexDirection: 'column',
              overflow: 'hidden'
            }}
          >
            {/* Header */}
            <div
              style={{
                background: 'linear-gradient(135deg, #0d6efd 0%, #0a58ca 100%)',
                color: 'white',
                padding: '20px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between'
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                <div
                  style={{
                    width: '48px',
                    height: '48px',
                    borderRadius: '50%',
                    backgroundColor: 'white',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: '#0d6efd'
                  }}
                >
                  <User size={24} />
                </div>
                <div>
                  <h6 style={{ margin: 0, fontWeight: 'bold' }}>Trợ lý ảo</h6>
                  <small style={{ opacity: 0.9 }}>
                    <span style={{ display: 'inline-block', width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#00ff00', marginRight: '6px' }}></span>
                    Đang hoạt động
                  </small>
                </div>
              </div>
              <button
                onClick={() => setIsOpen(false)}
                style={{
                  background: 'none',
                  border: 'none',
                  color: 'white',
                  cursor: 'pointer',
                  padding: '8px'
                }}
              >
                <X size={24} />
              </button>
            </div>

            {/* Messages */}
            <div
              style={{
                flex: 1,
                overflowY: 'auto',
                padding: '20px',
                backgroundColor: '#f8f9fa'
              }}
            >
              {messages.map((message, index) => (
                <motion.div
                  key={message.id}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: index * 0.1 }}
                  style={{
                    display: 'flex',
                    justifyContent: message.sender === 'user' ? 'flex-end' : 'flex-start',
                    marginBottom: '16px'
                  }}
                >
                  <div
                    style={{
                      maxWidth: '75%',
                      padding: '12px 16px',
                      borderRadius: message.sender === 'user' ? '16px 16px 4px 16px' : '16px 16px 16px 4px',
                      backgroundColor: message.sender === 'user' ? '#0d6efd' : 'white',
                      color: message.sender === 'user' ? 'white' : '#212529',
                      boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
                      whiteSpace: 'pre-line'
                    }}
                  >
                    <div style={{ fontSize: '14px' }}>{message.text}</div>
                    <div
                      style={{
                        fontSize: '11px',
                        marginTop: '4px',
                        opacity: 0.7,
                        textAlign: 'right'
                      }}
                    >
                      {message.timestamp}
                    </div>
                  </div>
                </motion.div>
              ))}

              {/* Quick Questions */}
              {messages.length <= 2 && (
                <div style={{ marginTop: '20px' }}>
                  <p style={{ fontSize: '12px', color: '#6c757d', marginBottom: '12px' }}>
                    Câu hỏi thường gặp:
                  </p>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                    {quickQuestions.map((question, idx) => (
                      <motion.button
                        key={idx}
                        whileHover={{ scale: 1.02 }}
                        whileTap={{ scale: 0.98 }}
                        onClick={() => handleQuickQuestion(question)}
                        style={{
                          padding: '10px 14px',
                          backgroundColor: 'white',
                          border: '1px solid #dee2e6',
                          borderRadius: '8px',
                          cursor: 'pointer',
                          fontSize: '13px',
                          textAlign: 'left',
                          color: '#495057',
                          transition: 'all 0.2s'
                        }}
                      >
                        {question}
                      </motion.button>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* Input */}
            <form
              onSubmit={handleSendMessage}
              style={{
                padding: '16px',
                backgroundColor: 'white',
                borderTop: '1px solid #dee2e6',
                display: 'flex',
                gap: '8px'
              }}
            >
              <input
                type="text"
                value={inputMessage}
                onChange={(e) => setInputMessage(e.target.value)}
                placeholder="Nhập tin nhắn..."
                style={{
                  flex: 1,
                  padding: '12px 16px',
                  border: '1px solid #dee2e6',
                  borderRadius: '24px',
                  fontSize: '14px',
                  outline: 'none'
                }}
              />
              <button
                type="submit"
                disabled={!inputMessage.trim()}
                style={{
                  width: '48px',
                  height: '48px',
                  borderRadius: '50%',
                  backgroundColor: inputMessage.trim() ? '#0d6efd' : '#dee2e6',
                  border: 'none',
                  color: 'white',
                  cursor: inputMessage.trim() ? 'pointer' : 'not-allowed',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  transition: 'all 0.2s'
                }}
              >
                <Send size={20} />
              </button>
            </form>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  )
}

export default ChatWidget
