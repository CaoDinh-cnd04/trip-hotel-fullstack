import React, { useState } from 'react'
import { Link } from 'react-router-dom'
import { Modal } from 'react-bootstrap'
import {
  MapPin,
  Phone,
  Mail,
  Facebook,
  Twitter,
  Instagram,
  Youtube,
  X
} from 'lucide-react'

const Footer = () => {
  const [showModal, setShowModal] = useState(false)
  const [modalContent, setModalContent] = useState({ title: '', content: null })

  const openModal = (title, content) => {
    setModalContent({ title, content })
    setShowModal(true)
  }

  const modalContents = {
    faq: (
      <div className="space-y-4">
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">1. Làm thế nào để đặt phòng?</h5>
          <p className="text-gray-700">Bạn có thể tìm kiếm khách sạn theo địa điểm, chọn phòng phù hợp, điền thông tin và thanh toán để hoàn tất đặt phòng.</p>
        </div>
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">2. Tôi có thể hủy đặt phòng không?</h5>
          <p className="text-gray-700">Chính sách hủy phòng tùy thuộc vào từng khách sạn. Vui lòng kiểm tra điều khoản hủy phòng khi đặt.</p>
        </div>
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">3. Các hình thức thanh toán được chấp nhận?</h5>
          <p className="text-gray-700">Chúng tôi chấp nhận thẻ tín dụng/ghi nợ, ví điện tử (MoMo, ZaloPay), và chuyển khoản ngân hàng.</p>
        </div>
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">4. Tôi có nhận được xác nhận đặt phòng không?</h5>
          <p className="text-gray-700">Sau khi đặt phòng thành công, bạn sẽ nhận email xác nhận với mã đặt phòng và thông tin chi tiết.</p>
        </div>
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">5. Làm sao để thay đổi thông tin đặt phòng?</h5>
          <p className="text-gray-700">Bạn có thể liên hệ với chúng tôi qua hotline hoặc email để được hỗ trợ thay đổi thông tin.</p>
        </div>
      </div>
    ),
    bookingGuide: (
      <div className="space-y-4">
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">Bước 1: Tìm kiếm khách sạn</h5>
          <p className="text-gray-700">Nhập địa điểm, ngày nhận phòng, trả phòng và số lượng khách vào thanh tìm kiếm.</p>
        </div>
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">Bước 2: Chọn khách sạn và phòng</h5>
          <p className="text-gray-700">Xem danh sách kết quả, so sánh giá và tiện nghi, sau đó chọn phòng phù hợp.</p>
        </div>
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">Bước 3: Điền thông tin</h5>
          <p className="text-gray-700">Nhập đầy đủ thông tin cá nhân: họ tên, email, số điện thoại và yêu cầu đặc biệt (nếu có).</p>
        </div>
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">Bước 4: Thanh toán</h5>
          <p className="text-gray-700">Chọn hình thức thanh toán và hoàn tất giao dịch. Bạn sẽ nhận được email xác nhận ngay lập tức.</p>
        </div>
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">Bước 5: Nhận xác nhận</h5>
          <p className="text-gray-700">Kiểm tra email để nhận mã đặt phòng và voucher. Mang theo khi check-in tại khách sạn.</p>
        </div>
      </div>
    ),
    paymentGuide: (
      <div className="space-y-4">
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">1. Thanh toán bằng thẻ tín dụng/ghi nợ</h5>
          <p className="text-gray-700">Chấp nhận Visa, MasterCard, JCB. Nhập thông tin thẻ và mã CVV để hoàn tất thanh toán.</p>
        </div>
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">2. Thanh toán qua ví điện tử</h5>
          <p className="text-gray-700">Hỗ trợ MoMo, ZaloPay, VNPay. Chọn ví điện tử và quét mã QR hoặc đăng nhập để thanh toán.</p>
        </div>
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">3. Chuyển khoản ngân hàng</h5>
          <p className="text-gray-700">Chuyển khoản theo thông tin được cung cấp. Ghi rõ mã đặt phòng trong nội dung chuyển khoản.</p>
        </div>
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">4. Bảo mật thanh toán</h5>
          <p className="text-gray-700">Mọi giao dịch đều được mã hóa SSL 256-bit. Thông tin thẻ không được lưu trữ trên hệ thống.</p>
        </div>
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">5. Hoàn tiền</h5>
          <p className="text-gray-700">Trường hợp hủy phòng được chấp nhận, hoàn tiền sẽ được xử lý trong 7-14 ngày làm việc.</p>
        </div>
      </div>
    ),
    terms: (
      <div className="space-y-4">
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">1. Chấp nhận điều khoản</h5>
          <p className="text-gray-700">Khi sử dụng dịch vụ TripHotel, bạn đồng ý tuân thủ các điều khoản và điều kiện này.</p>
        </div>
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">2. Tài khoản người dùng</h5>
          <p className="text-gray-700">Bạn có trách nhiệm bảo mật thông tin tài khoản và chịu trách nhiệm về mọi hoạt động dưới tài khoản của mình.</p>
        </div>
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">3. Đặt phòng và thanh toán</h5>
          <p className="text-gray-700">Giá phòng có thể thay đổi theo thời gian. Giá cuối cùng là giá hiển thị khi hoàn tất đặt phòng.</p>
        </div>
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">4. Hủy và hoàn tiền</h5>
          <p className="text-gray-700">Chính sách hủy phòng và hoàn tiền được quy định bởi từng khách sạn và loại phòng cụ thể.</p>
        </div>
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">5. Giới hạn trách nhiệm</h5>
          <p className="text-gray-700">TripHotel không chịu trách nhiệm về các vấn đề phát sinh tại khách sạn trong thời gian lưu trú.</p>
        </div>
      </div>
    ),
    privacy: (
      <div className="space-y-4">
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">1. Thu thập thông tin</h5>
          <p className="text-gray-700">Chúng tôi thu thập thông tin cá nhân cần thiết để xử lý đặt phòng: họ tên, email, số điện thoại.</p>
        </div>
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">2. Sử dụng thông tin</h5>
          <p className="text-gray-700">Thông tin được sử dụng để xác nhận đặt phòng, liên lạc và cải thiện dịch vụ.</p>
        </div>
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">3. Bảo mật thông tin</h5>
          <p className="text-gray-700">Chúng tôi áp dụng các biện pháp bảo mật cao cấp để bảo vệ thông tin cá nhân của bạn.</p>
        </div>
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">4. Chia sẻ thông tin</h5>
          <p className="text-gray-700">Thông tin chỉ được chia sẻ với khách sạn liên quan để xử lý đặt phòng, không bán cho bên thứ ba.</p>
        </div>
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">5. Quyền của bạn</h5>
          <p className="text-gray-700">Bạn có quyền truy cập, chỉnh sửa hoặc xóa thông tin cá nhân bất kỳ lúc nào.</p>
        </div>
      </div>
    ),
    cookies: (
      <div className="space-y-4">
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">1. Cookie là gì?</h5>
          <p className="text-gray-700">Cookie là tệp nhỏ được lưu trên trình duyệt để cải thiện trải nghiệm người dùng.</p>
        </div>
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">2. Chúng tôi sử dụng cookie như thế nào?</h5>
          <p className="text-gray-700">Cookie giúp ghi nhớ thông tin đăng nhập, ngôn ngữ, và tùy chọn tìm kiếm của bạn.</p>
        </div>
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">3. Loại cookie</h5>
          <p className="text-gray-700">Chúng tôi sử dụng cookie cần thiết, cookie phân tích và cookie marketing (với sự đồng ý).</p>
        </div>
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">4. Quản lý cookie</h5>
          <p className="text-gray-700">Bạn có thể tắt cookie trong cài đặt trình duyệt, nhưng một số tính năng có thể không hoạt động.</p>
        </div>
        <div>
          <h5 className="font-semibold text-purple-600 mb-2">5. Cookie của bên thứ ba</h5>
          <p className="text-gray-700">Chúng tôi sử dụng Google Analytics để phân tích lưu lượng truy cập website.</p>
        </div>
      </div>
    )
  }

  return (
    <>
    <footer className="bg-gradient-to-r from-gray-900 via-purple-900 to-gray-900 text-white relative overflow-hidden">
      {/* Background decoration */}
      <div className="absolute inset-0 opacity-10">
        <div className="absolute top-0 left-1/4 w-96 h-96 bg-purple-500 rounded-full blur-3xl"></div>
        <div className="absolute bottom-0 right-1/4 w-96 h-96 bg-blue-500 rounded-full blur-3xl"></div>
      </div>
      
      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
          {/* Company Info */}
          <div className="space-y-6">
            <div className="flex items-center">
              <div className="h-12 w-12 bg-gradient-to-br from-purple-500 to-blue-500 rounded-xl flex items-center justify-center shadow-lg">
                <span className="text-white font-bold text-xl">T</span>
              </div>
              <span className="ml-3 text-2xl font-bold bg-gradient-to-r from-white to-gray-200 bg-clip-text text-transparent">
                TripHotel
              </span>
            </div>
            <p className="text-gray-300 text-sm">
              Nền tảng đặt phòng khách sạn hàng đầu Việt Nam. Chúng tôi mang đến trải nghiệm 
              du lịch tuyệt vời với hàng ngàn khách sạn chất lượng cao.
            </p>
            <div className="flex space-x-3">
              <a href="#" className="w-10 h-10 bg-white/10 backdrop-blur-sm rounded-full flex items-center justify-center hover:bg-white/20 hover:scale-110 transition-all duration-300 group">
                <Facebook className="h-5 w-5 text-gray-300 group-hover:text-blue-400" />
              </a>
              <a href="#" className="w-10 h-10 bg-white/10 backdrop-blur-sm rounded-full flex items-center justify-center hover:bg-white/20 hover:scale-110 transition-all duration-300 group">
                <Twitter className="h-5 w-5 text-gray-300 group-hover:text-cyan-400" />
              </a>
              <a href="#" className="w-10 h-10 bg-white/10 backdrop-blur-sm rounded-full flex items-center justify-center hover:bg-white/20 hover:scale-110 transition-all duration-300 group">
                <Instagram className="h-5 w-5 text-gray-300 group-hover:text-pink-400" />
              </a>
              <a href="#" className="w-10 h-10 bg-white/10 backdrop-blur-sm rounded-full flex items-center justify-center hover:bg-white/20 hover:scale-110 transition-all duration-300 group">
                <Youtube className="h-5 w-5 text-gray-300 group-hover:text-red-400" />
              </a>
            </div>
          </div>

          {/* Quick Links */}
          <div>
            <h3 className="text-lg font-semibold mb-4">Liên kết nhanh</h3>
            <ul className="space-y-2">
              <li>
                <Link to="/hotels" className="text-gray-300 hover:text-white text-sm">
                  Khách sạn
                </Link>
              </li>
              <li>
                <Link to="/promotions" className="text-gray-300 hover:text-white text-sm">
                  Khuyến mãi
                </Link>
              </li>
              <li>
                <Link to="/about" className="text-gray-300 hover:text-white text-sm">
                  Về chúng tôi
                </Link>
              </li>
              <li>
                <Link to="/contact" className="text-gray-300 hover:text-white text-sm">
                  Liên hệ
                </Link>
              </li>
              <li>
                <Link to="/help" className="text-gray-300 hover:text-white text-sm">
                  Trợ giúp
                </Link>
              </li>
            </ul>
          </div>

          {/* Support */}
          <div>
            <h3 className="text-lg font-semibold mb-4">Hỗ trợ khách hàng</h3>
            <ul className="space-y-2">
              <li>
                <button 
                  onClick={() => openModal('Câu hỏi thường gặp', modalContents.faq)} 
                  className="text-gray-300 hover:text-white text-sm bg-transparent border-none p-0 cursor-pointer text-left w-full"
                >
                  Câu hỏi thường gặp
                </button>
              </li>
              <li>
                <button 
                  onClick={() => openModal('Hướng dẫn đặt phòng', modalContents.bookingGuide)} 
                  className="text-gray-300 hover:text-white text-sm bg-transparent border-none p-0 cursor-pointer text-left w-full"
                >
                  Hướng dẫn đặt phòng
                </button>
              </li>
              <li>
                <button 
                  onClick={() => openModal('Hướng dẫn thanh toán', modalContents.paymentGuide)} 
                  className="text-gray-300 hover:text-white text-sm bg-transparent border-none p-0 cursor-pointer text-left w-full"
                >
                  Hướng dẫn thanh toán
                </button>
              </li>
              <li>
                <button 
                  onClick={() => openModal('Điều khoản sử dụng', modalContents.terms)} 
                  className="text-gray-300 hover:text-white text-sm bg-transparent border-none p-0 cursor-pointer text-left w-full"
                >
                  Điều khoản sử dụng
                </button>
              </li>
              <li>
                <button 
                  onClick={() => openModal('Chính sách bảo mật', modalContents.privacy)} 
                  className="text-gray-300 hover:text-white text-sm bg-transparent border-none p-0 cursor-pointer text-left w-full"
                >
                  Chính sách bảo mật
                </button>
              </li>
            </ul>
          </div>

          {/* Contact Info */}
          <div>
            <h3 className="text-lg font-semibold mb-4">Thông tin liên hệ</h3>
            <div className="space-y-3">
              <div className="flex items-start space-x-3">
                <MapPin className="h-5 w-5 text-primary-500 mt-0.5 flex-shrink-0" />
                <div className="text-gray-300 text-sm">
                  <p>Tầng 12, Tòa nhà ABC</p>
                  <p>123 Đường XYZ, Quận 1</p>
                  <p>TP. Hồ Chí Minh, Việt Nam</p>
                </div>
              </div>
              
              <div className="flex items-center space-x-3">
                <Phone className="h-5 w-5 text-primary-500 flex-shrink-0" />
                <div className="text-gray-300 text-sm">
                  <p>Hotline: 1900 1234</p>
                  <p>Di động: 0901 234 567</p>
                </div>
              </div>
              
              <div className="flex items-center space-x-3">
                <Mail className="h-5 w-5 text-primary-500 flex-shrink-0" />
                <div className="text-gray-300 text-sm">
                  <p>support@triphotel.vn</p>
                  <p>info@triphotel.vn</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Bottom Section */}
        <div className="mt-12 pt-8 border-t border-gray-700">
          <div className="flex flex-col md:flex-row justify-between items-center">
            <div className="text-gray-400 text-sm">
              © 2024 TripHotel. Tất cả quyền được bảo lưu.
            </div>
            
            <div className="flex space-x-6 mt-4 md:mt-0">
              <button 
                onClick={() => openModal('Điều khoản', modalContents.terms)} 
                className="text-gray-400 hover:text-white text-sm bg-transparent border-none p-0 cursor-pointer"
              >
                Điều khoản
              </button>
              <button 
                onClick={() => openModal('Bảo mật', modalContents.privacy)} 
                className="text-gray-400 hover:text-white text-sm bg-transparent border-none p-0 cursor-pointer"
              >
                Bảo mật
              </button>
              <button 
                onClick={() => openModal('Cookies', modalContents.cookies)} 
                className="text-gray-400 hover:text-white text-sm bg-transparent border-none p-0 cursor-pointer"
              >
                Cookies
              </button>
            </div>
          </div>
        </div>
      </div>
    </footer>

    {/* Modal */}
    <Modal 
      show={showModal} 
      onHide={() => setShowModal(false)} 
      size="lg"
      centered
    >
      <Modal.Header className="border-0 pb-0">
        <Modal.Title className="text-2xl font-bold text-purple-600">
          {modalContent.title}
        </Modal.Title>
        <button 
          onClick={() => setShowModal(false)} 
          className="btn-close"
          aria-label="Close"
        ></button>
      </Modal.Header>
      <Modal.Body className="px-4 py-3">
        {modalContent.content}
      </Modal.Body>
      <Modal.Footer className="border-0 pt-0">
        <button 
          onClick={() => setShowModal(false)} 
          className="px-6 py-2 bg-gradient-to-r from-purple-600 to-blue-600 text-white rounded-lg hover:shadow-lg transition-all duration-300"
        >
          Đóng
        </button>
      </Modal.Footer>
    </Modal>
    </>
  )
}

export default Footer