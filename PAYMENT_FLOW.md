# 💳 LUỒNG THANH TOÁN - TRIP HOTEL

## 📋 Tổng Quan

App hỗ trợ **3 phương thức thanh toán**:
1. **VNPay** - Thanh toán online (ATM/Internet Banking)
2. **Pay at Hotel** - Thanh toán tại khách sạn khi nhận phòng
3. **Cash** - Thanh toán tiền mặt (giới hạn < 2 phòng, < 3M VNĐ)

---

## 🔄 LUỒNG 1: VNPay (Online Payment)

### **Quy trình:**

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. USER CHỌN VNPAY                                              │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. APP TẠO PAYMENT URL                                          │
│    - Gọi backend API: POST /api/v2/vnpay/create-payment-url     │
│    - Backend tạo URL VNPay với signature                        │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. MỞ VNPAY TRONG BROWSER                                       │
│    - Launch URL trong external browser                          │
│    - User nhập thông tin thẻ/tài khoản                          │
│    - VNPay xử lý thanh toán                                     │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. VNPAY CALLBACK VỀ BACKEND                                    │
│    A. Return URL: GET /api/payment/vnpay-return                 │
│       - Backend verify signature                                │
│       - Update payment status → "completed"                     │
│       - Auto-confirm booking → "confirmed"                      │
│       - Send email confirmation                                 │
│       - Redirect về app: vnpaypayment://return                  │
│                                                                 │
│    B. IPN URL: POST /api/payment/vnpay-ipn                      │
│       - VNPay gọi callback server-to-server                     │
│       - Backend verify và update payment                        │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. APP NHẬN DEEP LINK                                           │
│    - Deep link: vnpaypayment://return?...                       │
│    - App detect và polling payment status                       │
│    - GET /api/v2/vnpay/payment-status/:orderId                  │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. HIỂN THỊ SUCCESS SCREEN                                      │
│    ✅ Payment successful                                         │
│    ✅ Booking confirmed                                          │
│    ✅ Email sent                                                 │
│    ✅ Auto-created conversation với hotel manager                │
└─────────────────────────────────────────────────────────────────┘
```

### **Chi tiết:**

| Bước | Thành phần | Hành động | Trạng thái |
|------|-----------|----------|-----------|
| 1 | User | Chọn phương thức VNPay | - |
| 2 | Mobile App | Gọi API tạo payment URL | - |
| 3 | Backend | Tạo VNPay URL + signature | - |
| 4 | Mobile App | Launch browser với VNPay URL | - |
| 5 | VNPay | User nhập thẻ và thanh toán | - |
| 6 | VNPay | Callback về backend (Return URL) | payment: "completed" |
| 7 | Backend | Verify signature → Update DB | booking: "confirmed" |
| 8 | Backend | Send email confirmation | email sent ✅ |
| 9 | Backend | Redirect về app deep link | - |
| 10 | Mobile App | Detect deep link → Poll status | - |
| 11 | Mobile App | Hiển thị success screen | Done ✅ |

### **Database Changes:**

```sql
-- Payment record được tạo khi user click "Thanh toán"
INSERT INTO payments (order_id, amount, status, ...)
VALUES ('BK3_...', 997500, 'pending', ...);

-- Sau khi VNPay callback về (Return URL)
UPDATE payments 
SET status = 'completed', transaction_id = '...' 
WHERE order_id = 'BK3_...';

-- Booking được auto-confirm
UPDATE phieu_dat_phong 
SET status = 'confirmed', paid = 1 
WHERE booking_code = 'BK3_...';
```

---

## 🔄 LUỒNG 2: Pay at Hotel (Thanh toán tại khách sạn)

### **Quy trình:**

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. USER CHỌN "PAY AT HOTEL"                                     │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. USER ĐIỀN THÔNG TIN                                          │
│    - Tên khách                                                  │
│    - Email                                                      │
│    - Số điện thoại                                              │
│    - Chọn dịch vụ bổ sung (nếu có)                             │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. APP TẠO BOOKING TRỰC TIẾP                                    │
│    - Gọi API: POST /api/bookings/cash                           │
│    - Không cần thanh toán trước                                 │
│    - Status: "pending" (chờ thanh toán tại khách sạn)           │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. BACKEND LƯU BOOKING                                          │
│    - INSERT phieu_dat_phong (status: "pending")                 │
│    - paymentMethod: "Pay at Hotel"                              │
│    - paid: 0 (chưa thanh toán)                                  │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. AUTO-CREATE CONVERSATION                                     │
│    - Tạo conversation với hotel manager trong Firestore         │
│    - Gửi message tự động thông báo có booking mới               │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. HIỂN THỊ SUCCESS SCREEN                                      │
│    ✅ Booking created                                            │
│    ⏳ Payment: Pending (thanh toán tại khách sạn)                │
│    📧 Email confirmation sent (optional)                         │
│    💬 Conversation created with manager                          │
└─────────────────────────────────────────────────────────────────┘
```

### **Chi tiết:**

| Bước | Thành phần | Hành động | Trạng thái |
|------|-----------|----------|-----------|
| 1 | User | Chọn "Pay at Hotel" | - |
| 2 | User | Điền thông tin khách | - |
| 3 | User | Click "Xác nhận đặt phòng" | - |
| 4 | Mobile App | Gọi API: `POST /api/bookings/cash` | - |
| 5 | Backend | INSERT booking với status "pending" | booking: "pending" |
| 6 | Backend | Lưu paymentMethod: "Pay at Hotel" | paid: 0 |
| 7 | Backend | Auto-create conversation (optional) | - |
| 8 | Mobile App | Hiển thị success screen | Done ✅ |
| 9 | Hotel Manager | Xác nhận booking sau (manual) | booking: "confirmed" |
| 10 | User | Thanh toán khi check-in | paid: 1 |

### **Database Changes:**

```sql
-- Booking được tạo ngay lập tức với status "pending"
INSERT INTO phieu_dat_phong (
  booking_code, 
  hotel_id, 
  room_id, 
  status, 
  paid,
  payment_method,
  total_amount,
  ...
)
VALUES (
  'BK_1234567890', 
  123, 
  456, 
  'pending',      -- Chờ thanh toán tại khách sạn
  0,              -- Chưa thanh toán
  'Pay at Hotel', -- Phương thức
  1500000,
  ...
);

-- Hotel manager có thể confirm booking sau (từ dashboard)
UPDATE phieu_dat_phong 
SET status = 'confirmed' 
WHERE booking_code = 'BK_1234567890';

-- Khi user check-in và thanh toán
UPDATE phieu_dat_phong 
SET paid = 1, payment_date = NOW() 
WHERE booking_code = 'BK_1234567890';
```

### **Ưu điểm:**

✅ **Đơn giản:** Không cần tích hợp payment gateway  
✅ **Linh hoạt:** User không cần thanh toán trước  
✅ **An toàn:** Không xử lý thông tin thẻ  
✅ **Nhanh:** Booking được tạo ngay lập tức  

### **Nhược điểm:**

⚠️ **Rủi ro no-show:** User có thể không đến  
⚠️ **Manual:** Hotel manager phải confirm thủ công  
⚠️ **Không auto-confirm:** Cần human intervention  

---

## 🔄 LUỒNG 3: Cash (Thanh toán tiền mặt)

### **Quy trình:**

**GIỐNG HỆT "Pay at Hotel"**, nhưng:

- **Điều kiện:** Chỉ cho phép nếu:
  - Số phòng < 2
  - Tổng giá trị < 3,000,000 VNĐ
- **PaymentMethod:** `"Cash"` thay vì `"Pay at Hotel"`
- **Logic:** Tương tự 100%

---

## 📊 SO SÁNH CÁC PHƯƠNG THỨC

| Tiêu chí | VNPay | Pay at Hotel | Cash |
|----------|-------|--------------|------|
| **Thanh toán trước** | ✅ Bắt buộc | ❌ Không cần | ❌ Không cần |
| **Auto-confirm booking** | ✅ Tự động | ❌ Manual | ❌ Manual |
| **Email confirmation** | ✅ Tự động | ⚠️ Optional | ⚠️ Optional |
| **Rủi ro no-show** | ❌ Không có | ⚠️ Cao | ⚠️ Cao |
| **Giới hạn** | Không | Không | < 2 phòng, < 3M |
| **Status ban đầu** | pending → completed | pending | pending |
| **Booking status** | confirmed | pending | pending |
| **Paid flag** | 1 (paid) | 0 (unpaid) | 0 (unpaid) |

---

## 🔐 BẢO MẬT VÀ XÁC THỰC

### **VNPay:**
- ✅ Signature verification (HMAC SHA512)
- ✅ IPN callback từ VNPay server
- ✅ Double check: Return URL + IPN
- ✅ Transaction ID từ VNPay

### **Pay at Hotel / Cash:**
- ⚠️ Không có verification online
- ✅ Conversation auto-created với manager
- ✅ Manager có thể liên hệ user để confirm
- ⚠️ Phụ thuộc vào hotel manager confirmation

---

## 🎯 KẾT LUẬN

### **Khi nào dùng VNPay?**
- Booking có giá trị cao
- Cần đảm bảo booking confirmed ngay
- Giảm rủi ro no-show
- User có thẻ ATM/Internet Banking

### **Khi nào dùng Pay at Hotel?**
- User không có thẻ/không muốn thanh toán trước
- Booking linh hoạt
- Khách sạn chấp nhận rủi ro
- Giá trị booking trung bình

### **Khi nào dùng Cash?**
- Booking nhỏ (< 2 phòng, < 3M)
- User ưa thích tiền mặt
- Walk-in booking

---

## 📞 SUPPORT

Nếu có vấn đề với thanh toán:
- **VNPay:** Liên hệ VNPay hotline hoặc backend support
- **Pay at Hotel/Cash:** Liên hệ trực tiếp với khách sạn qua chat

---

**Version:** 1.0  
**Last Updated:** 2024-12-23  
**Author:** Trip Hotel Dev Team

