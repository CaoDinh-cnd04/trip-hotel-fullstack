# 🏦 MOCK BANK TRANSFER - Test Payment Method

## 📋 Tổng Quan

**Mock Bank Transfer** là phương thức thanh toán **GIẢ LẬP** để **TEST**, hoạt động giống VNPay nhưng đơn giản hơn và không cần payment gateway thật.

⚠️ **LƯU Ý: CHỈ DÙNG ĐỂ TEST - KHÔNG PHẢI THANH TOÁN THẬT!**

---

## 🎯 Mục Đích

- ✅ **Test luồng thanh toán online** mà không cần tích hợp gateway thật
- ✅ **Simulate thành công/thất bại** để test error handling
- ✅ **Test auto-confirm booking** sau khi thanh toán
- ✅ **Test deep link** redirect về app
- ✅ **Test polling mechanism** của payment status

---

## 🔄 Luồng Hoạt Động

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. USER CHỌN "CHUYỂN KHOẢN NGÂN HÀNG"                          │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. APP GỌI API TẠO PAYMENT URL                                 │
│    POST /api/v2/bank-transfer/create-payment-url               │
│    {                                                            │
│      "amount": 997500,                                          │
│      "orderInfo": "Đặt phòng Deluxe tại Grand Hotel",         │
│      "orderId": "BT_1703331234567_123"                         │
│    }                                                            │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. BACKEND TẠO PAYMENT RECORD                                   │
│    INSERT INTO payments (                                       │
│      order_id = 'BT_...',                                      │
│      status = 'pending',                                        │
│      amount = 997500,                                           │
│      ...                                                        │
│    )                                                            │
│                                                                 │
│    Return payment URL:                                          │
│    http://localhost:5000/api/bank-transfer/test-page?...       │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. APP MỞ BROWSER VỚI TEST PAGE                                │
│    Launch external browser                                      │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. USER THẤY TEST PAGE (HTML)                                  │
│    ┌──────────────────────────────────────────────┐           │
│    │  🏦 Mock Bank Transfer                       │           │
│    │  ⚠️ TEST MODE                                │           │
│    │                                               │           │
│    │  Mã đơn hàng: BT_1703331234567_123          │           │
│    │  Nội dung: Đặt phòng Deluxe...              │           │
│    │  Số tiền: 997,500 ₫                         │           │
│    │                                               │           │
│    │  [✅ Thành công]  [❌ Thất bại]              │           │
│    └──────────────────────────────────────────────┘           │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. USER CLICK NÚT (Thành công hoặc Thất bại)                   │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 7. REDIRECT ĐẾN RETURN URL                                     │
│    GET /api/bank-transfer/return?                              │
│      orderId=BT_...&                                            │
│      responseCode=00&  (00 = success, 99 = fail)              │
│      transactionStatus=00                                       │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 8. BACKEND XỬ LÝ RETURN                                        │
│    • UPDATE payments SET status = 'completed'                   │
│    • AUTO-CONFIRM BOOKING (if success)                         │
│    • UPDATE phieu_dat_phong SET status = 'confirmed'           │
│    • SEND EMAIL (if configured)                                │
│    • REDIRECT về app: banktransfer://return                    │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 9. APP NHẬN DEEP LINK                                          │
│    Deep link: banktransfer://return?success=true               │
│    • App detect deep link                                       │
│    • Start polling payment status                               │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 10. APP POLLING PAYMENT STATUS                                 │
│     GET /api/v2/bank-transfer/payment-status/BT_...           │
│     Every 2 seconds, max 60 attempts (2 minutes)               │
│                                                                 │
│     Response:                                                   │
│     {                                                           │
│       "success": true,                                          │
│       "data": {                                                 │
│         "status": "completed"  // hoặc "failed"               │
│       }                                                         │
│     }                                                           │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 11. HIỂN THỊ SUCCESS SCREEN                                    │
│     ✅ Payment successful                                        │
│     ✅ Booking confirmed                                         │
│     ✅ Email sent                                                │
│     ✅ Conversation created                                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## 💻 Code Implementation

### **Backend Controller:**

```javascript
// hotel-booking-backend/controllers/bankTransferController.js

class BankTransferController {
  // Create payment URL
  async createPaymentUrl(req, res) {
    const { amount, orderInfo, orderId } = req.body;
    
    // 1. Create payment record (status: pending)
    await pool.query(`
      INSERT INTO payments (order_id, amount, status, ...)
      VALUES (?, ?, 'pending', ...)
    `);
    
    // 2. Generate test page URL
    const paymentUrl = `${baseUrl}/api/bank-transfer/test-page?` +
      `orderId=${orderId}&amount=${amount}&...`;
    
    return res.json({ success: true, data: { paymentUrl } });
  }
  
  // Display test page (HTML)
  async testPage(req, res) {
    res.send(`
      <html>
        <button onclick="handlePayment(true)">✅ Thành công</button>
        <button onclick="handlePayment(false)">❌ Thất bại</button>
        <script>
          function handlePayment(success) {
            window.location.href = '/api/bank-transfer/return?...' +
              'responseCode=' + (success ? '00' : '99');
          }
        </script>
      </html>
    `);
  }
  
  // Handle return (like VNPay)
  async bankTransferReturn(req, res) {
    const { orderId, responseCode } = req.query;
    const isSuccess = responseCode === '00';
    
    // 1. Update payment status
    await pool.query(`
      UPDATE payments SET status = ?
      WHERE order_id = ?
    `, [isSuccess ? 'completed' : 'failed', orderId]);
    
    // 2. Auto-confirm booking if success
    if (isSuccess) {
      await AutoConfirmBookingService.autoConfirmBookingAfterPayment(orderId);
    }
    
    // 3. Redirect to app
    const deepLink = `banktransfer://return?success=${isSuccess}`;
    res.send(`<script>window.location.href='${deepLink}'</script>`);
  }
}
```

### **Flutter App:**

```dart
// payment_screen.dart

if (_selectedPaymentMethod == PaymentMethod.bankTransfer) {
  // 1. Call API to get payment URL
  final response = await ApiService.post(
    '/v2/bank-transfer/create-payment-url',
    {
      'amount': _finalTotal,
      'orderInfo': 'Đặt phòng...',
      'orderId': orderId,
    },
  );
  
  // 2. Launch browser with test page
  final paymentUrl = response['data']['paymentUrl'];
  await launchUrl(Uri.parse(paymentUrl));
  
  // 3. Start polling payment status
  _pollBankTransferPaymentStatus(orderId);
}

void _pollBankTransferPaymentStatus(String orderId) {
  Timer.periodic(Duration(seconds: 2), (timer) async {
    final response = await ApiService.get(
      '/v2/bank-transfer/payment-status/$orderId',
    );
    
    final status = response['data']['status'];
    
    if (status == 'completed') {
      timer.cancel();
      // Navigate to success screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PaymentSuccessScreen(...)),
      );
    } else if (status == 'failed') {
      timer.cancel();
      // Show error
      _showPaymentErrorDialog('Thanh toán thất bại');
    }
  });
}
```

---

## 📊 So Sánh Với VNPay

| Tiêu chí | VNPay | Mock Bank Transfer |
|----------|-------|-------------------|
| **Gateway** | VNPay API thật | Mock HTML page |
| **Payment** | Nhập thẻ thật | Click button test |
| **Signature** | HMAC SHA512 | Không có |
| **Security** | Cao (production) | Thấp (test only) |
| **Auto-confirm** | ✅ Có | ✅ Có |
| **Email** | ✅ Gửi thật | ✅ Gửi thật |
| **Deep link** | vnpaypayment:// | banktransfer:// |
| **Polling** | ✅ Có | ✅ Có |
| **Database** | ✅ Lưu payments | ✅ Lưu payments |

---

## 🎨 Test Page UI

Test page có thiết kế đẹp với:

- 🏦 Icon ngân hàng
- ⚠️ Badge "TEST MODE" màu cam
- 💰 Số tiền hiển thị lớn
- 📋 Thông tin đơn hàng
- ✅ Nút "Thành công" màu xanh
- ❌ Nút "Thất bại" màu đỏ
- 🔄 Loading spinner khi xử lý
- ⚡ Smooth animations

---

## 🔐 Deep Link Configuration

### **Android Manifest:**

```xml
<!-- AndroidManifest.xml -->
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="banktransfer" android:host="return" />
</intent-filter>
```

### **iOS Info.plist:**

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>banktransfer</string>
    </array>
  </dict>
</array>
```

---

## 📝 API Endpoints

### **1. Create Payment URL**

**POST** `/api/v2/bank-transfer/create-payment-url`

**Request:**
```json
{
  "amount": 997500,
  "orderInfo": "Đặt phòng Deluxe tại Grand Hotel",
  "orderId": "BT_1703331234567_123",
  "userName": "Nguyen Van A",
  "userEmail": "user@email.com",
  "userPhone": "0901234567"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Tạo link thanh toán thành công",
  "data": {
    "paymentUrl": "http://localhost:5000/api/bank-transfer/test-page?...",
    "orderId": "BT_1703331234567_123",
    "txnRef": "BANK_1703331234567_...",
    "amount": 997500
  }
}
```

### **2. Test Page (HTML)**

**GET** `/api/bank-transfer/test-page`

Query params: `orderId`, `amount`, `orderInfo`, `txnRef`

Returns: HTML page với buttons

### **3. Return URL**

**GET** `/api/bank-transfer/return`

Query params:
- `orderId`: Order ID
- `responseCode`: "00" (success) or "99" (fail)
- `transactionStatus`: "00" or "02"

Returns: HTML với redirect to deep link

### **4. Get Payment Status**

**GET** `/api/v2/bank-transfer/payment-status/:orderId`

**Response:**
```json
{
  "success": true,
  "data": {
    "order_id": "BT_1703331234567_123",
    "amount": 997500,
    "status": "completed",  // "pending", "completed", "failed"
    "response_code": "00",
    "transaction_id": "BANK_...",
    "created_at": "2024-12-23T10:30:00",
    "updated_at": "2024-12-23T10:31:00"
  }
}
```

---

## ✅ Testing Scenarios

### **Test Case 1: Thanh toán thành công**

1. Chọn "Chuyển khoản ngân hàng"
2. Browser mở test page
3. Click "✅ Thành công"
4. Chờ 1.5 giây (loading)
5. Redirect về app
6. App polling → status = "completed"
7. Navigate to PaymentSuccessScreen
8. ✅ **Expected:** Booking confirmed, email sent

### **Test Case 2: Thanh toán thất bại**

1. Chọn "Chuyển khoản ngân hàng"
2. Browser mở test page
3. Click "❌ Thất bại"
4. Chờ 1.5 giây (loading)
5. Redirect về app
6. App polling → status = "failed"
7. Show error dialog
8. ✅ **Expected:** Booking NOT confirmed, no email

### **Test Case 3: User đóng browser (không click gì)**

1. Chọn "Chuyển khoản ngân hàng"
2. Browser mở test page
3. User đóng browser (không click)
4. App polling → timeout sau 2 phút
5. Show timeout message
6. ✅ **Expected:** Payment status vẫn "pending"

---

## 🎯 Advantages

✅ **Không cần payment gateway thật**  
✅ **Test luồng end-to-end**  
✅ **Test cả success và failure**  
✅ **Giống VNPay về cấu trúc code**  
✅ **Dễ debug (có full control)**  
✅ **Không mất phí test**  

---

## ⚠️ Limitations

❌ **KHÔNG được dùng production**  
❌ **Không có security (no signature)**  
❌ **Không có real bank integration**  
❌ **Test page có thể bị bypass**  

---

## 🚀 Future: Chuyển sang Real Bank Transfer

Khi muốn dùng thật, thay thế bằng:

1. **VietQR API** - Generate QR code thật
2. **Bank API** - Check transaction thật
3. **Remove test page** - Thay bằng QR display
4. **Add verification** - Verify với bank

---

**Version:** 1.0  
**Last Updated:** 2024-12-23  
**Author:** Trip Hotel Dev Team  
**Purpose:** Testing Only - Not for Production

