import React from 'react'
import { motion } from 'framer-motion'
import { Hotel, Mail, Phone, MapPin, Heart, Target, Eye } from 'lucide-react'

const AboutUsPage = () => {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-br from-blue-600 via-blue-500 to-blue-700 text-white">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 pt-20 pb-12">
          <div className="text-center">
            <div className="inline-flex items-center justify-center w-20 h-20 bg-white/20 backdrop-blur-sm rounded-2xl mb-6">
              <Hotel size={40} />
            </div>
            <h1 className="text-4xl font-bold mb-4">TripHotel</h1>
            <p className="text-blue-100 text-lg">
              Nền tảng đặt phòng khách sạn hàng đầu Việt Nam
            </p>
          </div>
        </div>
      </div>

      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 -mt-8 pb-8">
        {/* Mission Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white rounded-xl shadow-sm p-6 mb-6"
        >
          <div className="flex items-center gap-3 mb-4">
            <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
              <Target size={24} className="text-blue-600" />
            </div>
            <h2 className="text-2xl font-semibold text-gray-900">Sứ mệnh</h2>
          </div>
          <p className="text-gray-700 leading-relaxed">
            TripHotel cam kết mang đến trải nghiệm đặt phòng khách sạn tốt nhất cho khách hàng. 
            Chúng tôi kết nối hàng nghìn khách sạn trên toàn quốc với khách hàng, tạo nên một 
            nền tảng đặt phòng tiện lợi, nhanh chóng và đáng tin cậy.
          </p>
        </motion.div>

        {/* Vision Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="bg-white rounded-xl shadow-sm p-6 mb-6"
        >
          <div className="flex items-center gap-3 mb-4">
            <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
              <Eye size={24} className="text-blue-600" />
            </div>
            <h2 className="text-2xl font-semibold text-gray-900">Tầm nhìn</h2>
          </div>
          <p className="text-gray-700 leading-relaxed">
            Trở thành nền tảng đặt phòng khách sạn số 1 tại Việt Nam, được hàng triệu khách hàng 
            tin tưởng và lựa chọn. Chúng tôi hướng tới việc tạo ra một hệ sinh thái du lịch hoàn chỉnh, 
            nơi mọi người có thể dễ dàng tìm kiếm, đặt phòng và tận hưởng những kỳ nghỉ tuyệt vời.
          </p>
        </motion.div>

        {/* Values Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="bg-white rounded-xl shadow-sm p-6 mb-6"
        >
          <div className="flex items-center gap-3 mb-4">
            <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
              <Heart size={24} className="text-blue-600" />
            </div>
            <h2 className="text-2xl font-semibold text-gray-900">Giá trị cốt lõi</h2>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="p-4 bg-gray-50 rounded-lg">
              <h3 className="font-semibold text-gray-900 mb-2">Đáng tin cậy</h3>
              <p className="text-sm text-gray-600">
                Cam kết cung cấp thông tin chính xác và dịch vụ chất lượng cao
              </p>
            </div>
            <div className="p-4 bg-gray-50 rounded-lg">
              <h3 className="font-semibold text-gray-900 mb-2">Tiện lợi</h3>
              <p className="text-sm text-gray-600">
                Giao diện thân thiện, quy trình đặt phòng đơn giản và nhanh chóng
              </p>
            </div>
            <div className="p-4 bg-gray-50 rounded-lg">
              <h3 className="font-semibold text-gray-900 mb-2">Giá cả hợp lý</h3>
              <p className="text-sm text-gray-600">
                So sánh giá từ nhiều nguồn, đảm bảo giá tốt nhất cho khách hàng
              </p>
            </div>
            <div className="p-4 bg-gray-50 rounded-lg">
              <h3 className="font-semibold text-gray-900 mb-2">Hỗ trợ 24/7</h3>
              <p className="text-sm text-gray-600">
                Đội ngũ chăm sóc khách hàng luôn sẵn sàng hỗ trợ mọi lúc, mọi nơi
              </p>
            </div>
          </div>
        </motion.div>

        {/* Contact Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="bg-white rounded-xl shadow-sm p-6"
        >
          <h2 className="text-2xl font-semibold text-gray-900 mb-6">Liên hệ với chúng tôi</h2>
          <div className="space-y-4">
            <div className="flex items-center gap-4 p-4 bg-gray-50 rounded-lg">
              <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                <Mail size={20} className="text-blue-600" />
              </div>
              <div>
                <p className="text-sm text-gray-500">Email</p>
                <p className="font-medium text-gray-900">support@triphotel.com</p>
              </div>
            </div>
            <div className="flex items-center gap-4 p-4 bg-gray-50 rounded-lg">
              <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                <Phone size={20} className="text-blue-600" />
              </div>
              <div>
                <p className="text-sm text-gray-500">Điện thoại</p>
                <p className="font-medium text-gray-900">1900 1234</p>
              </div>
            </div>
            <div className="flex items-center gap-4 p-4 bg-gray-50 rounded-lg">
              <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                <MapPin size={20} className="text-blue-600" />
              </div>
              <div>
                <p className="text-sm text-gray-500">Địa chỉ</p>
                <p className="font-medium text-gray-900">
                  123 Đường ABC, Quận XYZ, TP. Hồ Chí Minh
                </p>
              </div>
            </div>
          </div>
        </motion.div>

        {/* Version Info */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.4 }}
          className="text-center mt-8 text-sm text-gray-500"
        >
          <p>Phiên bản 1.0.0</p>
          <p className="mt-2">© 2024 TripHotel. Tất cả quyền được bảo lưu.</p>
        </motion.div>
      </div>
    </div>
  )
}

export default AboutUsPage

