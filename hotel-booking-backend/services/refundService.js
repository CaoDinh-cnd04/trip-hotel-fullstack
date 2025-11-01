const crypto = require('crypto');
const axios = require('axios');
const vnpayConfig = require('../config/vnpay');
const momoConfig = require('../config/momo');
const Booking = require('../models/booking');

class RefundService {
  /**
   * Hoàn tiền VNPay
   * Documentation: https://sandbox.vnpayment.vn/apis/docs/huong-dan-tich-hop/#ho%C3%A0n-ti%E1%BB%81n-giao-d%E1%BB%8Bch-thanh-to%C3%A1n
   */
  async refundVNPay(booking) {
    try {
      console.log('🔄 Bắt đầu hoàn tiền VNPay cho booking:', booking.booking_code);

      const vnp_RequestId = this.generateRequestId();
      const vnp_Version = '2.1.0';
      const vnp_Command = 'refund';
      const vnp_TmnCode = vnpayConfig.vnp_TmnCode;
      const vnp_TransactionType = '02'; // 02: Hoàn toàn phần, 03: Hoàn toàn bộ
      const vnp_TxnRef = booking.payment_transaction_id; // Mã giao dịch gốc
      const vnp_Amount = Math.floor(booking.final_price * 100); // VNPay yêu cầu nhân 100
      const vnp_OrderInfo = `Hoàn tiền đặt phòng ${booking.booking_code}`;
      const vnp_TransactionNo = '0'; // Mã GD tại VNPay (có thể để 0)
      const vnp_TransactionDate = this.formatVNPayDate(booking.payment_date);
      const vnp_CreateDate = this.formatVNPayDate(new Date());
      const vnp_CreateBy = booking.user_email;
      const vnp_IpAddr = '127.0.0.1';

      // Tạo secure hash
      const dataHash = [
        vnp_RequestId,
        vnp_Version,
        vnp_Command,
        vnp_TmnCode,
        vnp_TransactionType,
        vnp_TxnRef,
        vnp_Amount,
        vnp_TransactionNo,
        vnp_TransactionDate,
        vnp_CreateBy,
        vnp_CreateDate,
        vnp_IpAddr,
        vnp_OrderInfo,
      ].join('|');

      const vnp_SecureHash = crypto
        .createHmac('sha512', vnpayConfig.vnp_HashSecret)
        .update(dataHash)
        .digest('hex');

      const refundData = {
        vnp_RequestId,
        vnp_Version,
        vnp_Command,
        vnp_TmnCode,
        vnp_TransactionType,
        vnp_TxnRef,
        vnp_Amount,
        vnp_OrderInfo,
        vnp_TransactionNo,
        vnp_TransactionDate,
        vnp_CreateDate,
        vnp_CreateBy,
        vnp_IpAddr,
        vnp_SecureHash,
      };

      console.log('📤 Gửi yêu cầu hoàn tiền đến VNPay:', refundData);

      // Gửi request đến VNPay API
      const response = await axios.post(vnpayConfig.vnp_Api, refundData, {
        headers: {
          'Content-Type': 'application/json',
        },
      });

      console.log('📥 Phản hồi từ VNPay:', response.data);

      if (response.data.vnp_ResponseCode === '00') {
        // Hoàn tiền thành công
        await Booking.updateRefundStatus(booking.id, {
          status: 'completed',
          amount: booking.final_price,
          transactionId: response.data.vnp_TransactionNo || vnp_RequestId,
        });

        return {
          success: true,
          message: 'Hoàn tiền VNPay thành công',
          transactionId: response.data.vnp_TransactionNo,
          amount: booking.final_price,
        };
      } else {
        // Hoàn tiền thất bại
        await Booking.updateRefundStatus(booking.id, {
          status: 'failed',
          amount: 0,
          transactionId: vnp_RequestId,
        });

        return {
          success: false,
          message: `Hoàn tiền VNPay thất bại: ${response.data.vnp_Message}`,
          code: response.data.vnp_ResponseCode,
        };
      }
    } catch (error) {
      console.error('❌ Lỗi hoàn tiền VNPay:', error);
      
      await Booking.updateRefundStatus(booking.id, {
        status: 'failed',
        amount: 0,
        transactionId: 'ERROR',
      });

      return {
        success: false,
        message: `Lỗi hệ thống: ${error.message}`,
      };
    }
  }

  /**
   * Hoàn tiền MoMo
   * Documentation: https://developers.momo.vn/#/docs/en/aiov2/?id=refund-api
   */
  async refundMoMo(booking) {
    try {
      console.log('🔄 Bắt đầu hoàn tiền MoMo cho booking:', booking.booking_code);

      const partnerCode = momoConfig.partnerCode;
      const accessKey = momoConfig.accessKey;
      const requestId = this.generateRequestId();
      const orderId = booking.payment_transaction_id; // Mã đơn hàng gốc
      const requestType = 'refund';
      const amount = Math.floor(booking.final_price);
      const transId = booking.payment_transaction_id; // Transaction ID từ MoMo
      const lang = 'vi';
      const description = `Hoàn tiền đặt phòng ${booking.booking_code}`;

      // Tạo signature
      const rawSignature = `accessKey=${accessKey}&amount=${amount}&description=${description}&orderId=${orderId}&partnerCode=${partnerCode}&requestId=${requestId}&requestType=${requestType}&transId=${transId}`;

      const signature = crypto
        .createHmac('sha256', momoConfig.secretKey)
        .update(rawSignature)
        .digest('hex');

      const refundData = {
        partnerCode,
        accessKey,
        requestId,
        orderId,
        requestType,
        amount,
        transId,
        lang,
        description,
        signature,
      };

      console.log('📤 Gửi yêu cầu hoàn tiền đến MoMo:', refundData);

      // Gửi request đến MoMo API
      const response = await axios.post(momoConfig.endpoint, refundData, {
        headers: {
          'Content-Type': 'application/json',
        },
      });

      console.log('📥 Phản hồi từ MoMo:', response.data);

      if (response.data.resultCode === 0) {
        // Hoàn tiền thành công
        await Booking.updateRefundStatus(booking.id, {
          status: 'completed',
          amount: booking.final_price,
          transactionId: response.data.transId || requestId,
        });

        return {
          success: true,
          message: 'Hoàn tiền MoMo thành công',
          transactionId: response.data.transId,
          amount: booking.final_price,
        };
      } else {
        // Hoàn tiền thất bại
        await Booking.updateRefundStatus(booking.id, {
          status: 'failed',
          amount: 0,
          transactionId: requestId,
        });

        return {
          success: false,
          message: `Hoàn tiền MoMo thất bại: ${response.data.message}`,
          code: response.data.resultCode,
        };
      }
    } catch (error) {
      console.error('❌ Lỗi hoàn tiền MoMo:', error);
      
      await Booking.updateRefundStatus(booking.id, {
        status: 'failed',
        amount: 0,
        transactionId: 'ERROR',
      });

      return {
        success: false,
        message: `Lỗi hệ thống: ${error.message}`,
      };
    }
  }

  /**
   * Hoàn tiền theo phương thức thanh toán
   */
  async processRefund(bookingId) {
    try {
      const booking = await Booking.getById(bookingId);

      if (!booking) {
        return {
          success: false,
          message: 'Không tìm thấy đơn đặt phòng',
        };
      }

      if (booking.booking_status !== 'cancelled') {
        return {
          success: false,
          message: 'Đơn đặt phòng chưa bị hủy',
        };
      }

      if (booking.refund_status === 'completed') {
        return {
          success: false,
          message: 'Đã hoàn tiền cho đơn hàng này',
        };
      }

      // Kiểm tra phương thức thanh toán
      if (booking.payment_method === 'vnpay') {
        return await this.refundVNPay(booking);
      } else if (booking.payment_method === 'momo') {
        return await this.refundMoMo(booking);
      } else if (booking.payment_method === 'cash') {
        // Thanh toán tiền mặt - chỉ cập nhật trạng thái
        await Booking.updateRefundStatus(booking.id, {
          status: 'completed',
          amount: booking.final_price,
          transactionId: 'CASH-REFUND',
        });

        return {
          success: true,
          message: 'Đã ghi nhận hoàn tiền mặt. Vui lòng liên hệ khách sạn để nhận lại tiền',
          amount: booking.final_price,
        };
      } else {
        return {
          success: false,
          message: 'Phương thức thanh toán không hỗ trợ hoàn tiền tự động',
        };
      }
    } catch (error) {
      console.error('❌ Lỗi xử lý hoàn tiền:', error);
      return {
        success: false,
        message: `Lỗi xử lý: ${error.message}`,
      };
    }
  }

  /**
   * Tạo request ID duy nhất
   */
  generateRequestId() {
    const timestamp = Date.now();
    const random = Math.floor(Math.random() * 1000000);
    return `${timestamp}${random}`;
  }

  /**
   * Format ngày cho VNPay (yyyyMMddHHmmss)
   */
  formatVNPayDate(date) {
    const d = new Date(date);
    const year = d.getFullYear();
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    const hour = String(d.getHours()).padStart(2, '0');
    const minute = String(d.getMinutes()).padStart(2, '0');
    const second = String(d.getSeconds()).padStart(2, '0');
    return `${year}${month}${day}${hour}${minute}${second}`;
  }
}

module.exports = new RefundService();

