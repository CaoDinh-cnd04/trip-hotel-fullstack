# 🧪 HƯỚNG DẪN TEST VNPAY SANDBOX

## 📝 **ĐĂNG KÝ TÀI KHOẢN TEST**

### **Bước 1: Đăng ký tài khoản**
1. Truy cập: **https://sandbox.vnpayment.vn/devreg/**
2. Điền đầy đủ thông tin:
   - Tên công ty
   - Email (quan trọng - sẽ nhận credentials)
   - Số điện thoại
   - Website (có thể để localhost)

3. Submit form và kiểm tra **email** để nhận:
   - **TMN_CODE** (Terminal ID)
   - **HASH_SECRET** (Secret Key)

---

## 🔑 **CẤU HÌNH BACKEND**

### **Bước 2: Thêm credentials vào `.env`**
```env
# VNPay Sandbox Configuration
VNP_TMN_CODE=YOUR_TMN_CODE_HERE
VNP_HASH_SECRET=YOUR_HASH_SECRET_HERE
VNP_URL=https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
VNP_RETURN_URL=http://localhost:5000/api/payment/vnpay-return
```

### **Bước 3: Restart backend**
```bash
npm run dev
```

---

## 🧪 **TEST THANH TOÁN**

### **Cách 1: Chọn ngân hàng và thanh toán**
1. Mở app → Đặt phòng → Chọn **VNPay**
2. **Chọn ngân hàng** bất kỳ (VCB, TCB, BIDV, etc.)
3. Nhấn **"XÁC THỰC THANH TOÁN"**
4. Màn hình WebView VNPay Sandbox sẽ hiện ra

### **Cách 2: Quét QR Code**
1. Mở app → Đặt phòng → Chọn **VNPay**
2. **Quét QR Code** bằng app Mobile Banking (nếu có QR scanner)
3. Hoặc nhấn **"XÁC THỰC THANH TOÁN"** để mở WebView

---

## 💳 **THẺ TEST CỦA VNPAY**

Sau khi đăng ký xong, **VNPay sẽ gửi email** với thông tin test:

### **Ví dụ thông tin test (tham khảo):**
```
🔸 Số thẻ: 9704198526191432198
🔸 Tên chủ thẻ: NGUYEN VAN A
🔸 Ngày hết hạn: 07/07
🔸 CVV: 123
🔸 OTP: 123456
```

**Lưu ý:** Thông tin thật sẽ được VNPay gửi qua email!

---

## 🎯 **LUỒNG TEST**

```
1. User chọn VNPay → Tạo payment URL
2. Mở WebView với VNPay Sandbox
3. User chọn ngân hàng
4. Nhập thông tin thẻ TEST (từ email VNPay)
5. Nhập OTP: 123456 (hoặc mã VNPay cung cấp)
6. VNPay redirect về return URL
7. Backend verify signature
8. Tạo booking → Return success
```

---

## 🔍 **KIỂM TRA LOG**

Backend sẽ log đầy đủ:
```bash
🎯 Tạo VNPay payment URL...
🏦 Bank code: VIETCOMBANK
✅ Tạo payment URL thành công
🔗 Navigation URL: http://localhost:5000/api/payment/vnpay-return?vnp_ResponseCode=00&...
✅ Verify signature thành công
✅ Booking created: BOOK-20251030-001
```

---

## 🐛 **TROUBLESHOOTING**

### **Lỗi: "Invalid signature"**
- ✅ Kiểm tra `VNP_HASH_SECRET` đúng chưa
- ✅ Verify lại quá trình tạo signature

### **Lỗi: "Invalid TMN code"**
- ✅ Kiểm tra `VNP_TMN_CODE` đúng chưa
- ✅ Đảm bảo đã active tài khoản sandbox

### **Payment URL không mở được**
- ✅ Kiểm tra mạng internet
- ✅ Truy cập trực tiếp `https://sandbox.vnpayment.vn` xem có vào được không

---

## 📞 **LIÊN HỆ HỖ TRỢ**

- 📧 Email: support@vnpayment.vn
- 🌐 Website: https://sandbox.vnpayment.vn
- 📚 Docs: https://sandbox.vnpayment.vn/apis/docs/

---

**🎉 Hoàn thành! Bạn có thể test VNPay thanh toán ngay bây giờ!**

