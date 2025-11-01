# 🎴 HƯỚNG DẪN TEST MOMO TEST/SANDBOX

## 📝 **TÀI KHOẢN TEST**

### **Credentials hiện tại:**
```env
MOMO_PARTNER_CODE=MOMO
MOMO_ACCESS_KEY=F8BBA842ECF85
MOMO_SECRET_KEY=K951B6PE1waDMi640xX08PD3vg6EkVlz
```

**Đây là credentials TEST - Không cần đăng ký thêm!**

---

## 🎯 **LUỒNG TEST**

```
1. User chọn MoMo → Tạo payment request
2. Mở WebView với MoMo Sandbox
3. User scan QR hoặc mở app MoMo
4. Nhập thông tin ví test (số điện thoại test)
5. Confirm → MoMo redirect về return URL
6. Backend verify signature
7. Tạo booking → Return success
```

---

## 📱 **CÁCH TEST**

### **Cách 1: WebView (Trên Emulator)**
1. Mở app → Đặt phòng → Chọn **MoMo**
2. Nhấn **"THANH TOÁN BẰNG VÍ MOMO"**
3. WebView mở MoMo Payment
4. Test với ví MoMo test (nếu có)

### **Cách 2: QR Code (Trên Real Device)**
1. Mở app trên điện thoại thật
2. Chọn **MoMo**
3. Scan QR code bằng app MoMo
4. Confirm payment trong app

---

## 🔍 **KIỂM TRA LOG**

Backend sẽ log:
```bash
🎴 Tạo MoMo payment request...
✅ Payment URL: https://test-payment.momo.vn/...
📱 QR Code URL: https://test-payment.momo.vn/...
🔗 Deep link: momo://...
✅ Verify signature thành công
✅ Booking created: BOOK-20251030-001
```

---

## 🐛 **TROUBLESHOOTING**

### **Lỗi: "Invalid signature"**
- ✅ Check `MOMO_SECRET_KEY` đúng chưa
- ✅ Verify lại quá trình tạo signature

### **Lỗi: "Invalid partner code"**
- ✅ Check `MOMO_PARTNER_CODE` = `MOMO`
- ✅ Verify credentials trong `.env`

### **Payment URL không mở được**
- ✅ Check internet connection
- ✅ Verify API endpoint: `https://test-payment.momo.vn`

---

## 📞 **LIÊN HỆ HỖ TRỢ**

- 📧 Email: developers@momo.vn
- 🌐 Website: https://developers.momo.vn
- 📚 Docs: https://developers.momo.vn/docs

---

**🎉 MoMo ready! Test thanh toán ngay!**

