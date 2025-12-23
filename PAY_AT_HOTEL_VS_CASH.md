# 💰 PAY AT HOTEL vs CASH - So Sánh Chi Tiết

## 📋 Tóm Tắt Nhanh

**TL;DR:** Cả hai đều là "thanh toán sau", nhưng **Pay at Hotel linh hoạt hơn** (không giới hạn) còn **Cash bị giới hạn nghiêm ngặt** (< 2 phòng, < 3M VNĐ).

---

## 🔍 So Sánh Chi Tiết

| Tiêu chí | **Pay at Hotel** 🏨 | **Cash** 💵 |
|----------|---------------------|-------------|
| **Tên hiển thị** | "Thanh toán tại khách sạn" | "Thanh toán tiền mặt" |
| **Icon** | 🏨 (Hotel - Màu xanh lá) | 💰 (Money - Màu xanh) |
| **Subtitle** | "Thanh toán khi nhận phòng<br>(Tiền mặt hoặc thẻ)" | "Thanh toán trực tiếp<br>tại khách sạn" |
| **Điều kiện hiển thị** | ✅ LUÔN hiển thị<br>(trừ >= 3 phòng) | ⚠️ CHỈ khi:<br>• < 2 phòng<br>• < 3,000,000 VNĐ |
| **Số phòng tối đa** | 🔓 Không giới hạn<br>(2 phòng OK) | 🔒 < 2 phòng<br>(chỉ 1 phòng) |
| **Giá trị tối đa** | 🔓 Không giới hạn<br>(5M, 10M OK) | 🔒 < 3,000,000 VNĐ |
| **Phương thức thanh toán** | 💳 **Tiền mặt HOẶC thẻ**<br>(Visa/Master/ATM) | 💵 **CHỈ tiền mặt** |
| **Linh hoạt** | ✅ Cao (user chọn cách thanh toán sau) | ⚠️ Thấp (chỉ tiền mặt) |
| **Xử lý code** | ✅ Giống nhau 100% | ✅ Giống nhau 100% |
| **Database field** | `payment_method = "Pay at Hotel"` | `payment_method = "Cash"` |
| **Status ban đầu** | `status = "pending"` | `status = "pending"` |
| **Paid flag** | `paid = 0` | `paid = 0` |
| **API endpoint** | `POST /api/bookings/cash` | `POST /api/bookings/cash` |

---

## 💡 Điều Kiện Hiển Thị (Code)

### **Cash - Có giới hạn:**

```dart
// hotel_mobile/lib/presentation/screens/payment/payment_screen.dart
// Line 231-233

bool get _canUseCash {
  return widget.roomCount < 2 && _subtotal <= 3000000;
}
```

**Logic:**
```
CÓ THỂ DÙNG CASH nếu:
  ✅ roomCount < 2  (chỉ 1 phòng)
  VÀ
  ✅ _subtotal <= 3,000,000 VNĐ

KHÔNG DÙNG CASH nếu:
  ❌ roomCount >= 2  (từ 2 phòng trở lên)
  HOẶC
  ❌ _subtotal > 3,000,000 VNĐ
```

### **Pay at Hotel - Không giới hạn:**

```dart
// payment_options.dart - Line 79-85

_buildPaymentCard(
  method: PaymentMethod.payAtHotel,
  title: 'Thanh toán tại khách sạn',
  subtitle: 'Thanh toán khi nhận phòng (Tiền mặt hoặc thẻ)',
  icon: Icons.hotel,
  iconColor: const Color(0xFF4CAF50),
),
// ✅ LUÔN hiển thị (không check điều kiện _canUseCash)
```

**Logic:**
```
CÓ THỂ DÙNG PAY AT HOTEL nếu:
  ✅ roomCount < 3  (1-2 phòng OK)
  
KHÔNG DÙNG PAY AT HOTEL nếu:
  ❌ roomCount >= 3  (từ 3 phòng trở lên → BẮT BUỘC VNPay)
```

---

## 📊 Ví Dụ Thực Tế

### **Trường hợp 1: Đặt 1 phòng, giá 2,500,000 VNĐ**

```
✅ VNPay:          Hiển thị
✅ Pay at Hotel:   Hiển thị
✅ Cash:           Hiển thị  ← PASS (< 2 phòng, < 3M)
```

### **Trường hợp 2: Đặt 1 phòng, giá 3,500,000 VNĐ**

```
✅ VNPay:          Hiển thị
✅ Pay at Hotel:   Hiển thị
❌ Cash:           ẨN (giá > 3M)
```

### **Trường hợp 3: Đặt 2 phòng, giá 2,000,000 VNĐ**

```
✅ VNPay:          Hiển thị
✅ Pay at Hotel:   Hiển thị
❌ Cash:           ẨN (>= 2 phòng)
```

### **Trường hợp 4: Đặt 2 phòng, giá 4,500,000 VNĐ**

```
✅ VNPay:          Hiển thị
✅ Pay at Hotel:   Hiển thị
❌ Cash:           ẨN (>= 2 phòng VÀ > 3M)
```

### **Trường hợp 5: Đặt 3 phòng, giá bất kỳ**

```
✅ VNPay:          Hiển thị (BẮT BUỘC)
❌ Pay at Hotel:   ẨN (>= 3 phòng)
❌ Cash:           ẨN (>= 3 phòng)
```

---

## 🔄 Luồng Xử Lý (GIỐNG NHAU 100%)

### **Code xử lý:**

```dart
// hotel_mobile/lib/presentation/screens/payment/payment_screen.dart
// Line 864-973

// ✅ CẢ HAI DÙNG CÙNG MỘT ĐOẠN CODE
if (_selectedPaymentMethod == PaymentMethod.cash || 
    _selectedPaymentMethod == PaymentMethod.payAtHotel) {
  
  // 1. Chuẩn bị data
  final bookingData = {
    'userName': _nameController.text,
    'userEmail': _emailController.text,
    'userPhone': _phoneController.text,
    'hotelId': widget.hotel.id,
    'roomId': widget.room.id,
    'totalAmount': _fullTotal,
    'paymentMethod': _selectedPaymentMethod == PaymentMethod.cash 
        ? 'Cash'           // ← CHỈ KHÁC TÊN NÀY
        : 'Pay at Hotel',  // ← CHỈ KHÁC TÊN NÀY
    'paid': 0,  // Chưa thanh toán
    'status': 'pending',
    ...
  };
  
  // 2. Gọi API tạo booking
  final booking = await _bookingService.createCashBooking(bookingData);
  
  // 3. Auto-create conversation với hotel manager
  await messageService.createBookingConversation(...);
  
  // 4. Navigate to success screen
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => PaymentSuccessScreen(...)),
  );
}
```

### **Database:**

```sql
-- CẢ HAI TẠO BOOKING GIỐNG NHAU
INSERT INTO phieu_dat_phong (
  booking_code,
  hotel_id,
  room_id,
  status,          -- "pending"
  paid,            -- 0 (chưa thanh toán)
  payment_method,  -- "Cash" hoặc "Pay at Hotel" ← CHỈ KHÁC NÀY
  total_amount,
  ...
) VALUES (...);
```

---

## 🎯 Tại Sao Cần 2 Option Riêng?

### **1. UX/UI - Rõ ràng cho user:**

**Cash** = Chỉ tiền mặt (hạn chế)
- User hiểu ngay: "Tôi phải mang tiền mặt"
- Áp dụng cho booking nhỏ
- Giảm rủi ro cho khách sạn

**Pay at Hotel** = Linh hoạt (tiền mặt HOẶC thẻ)
- User có nhiều lựa chọn
- Áp dụng cho mọi booking (trừ >= 3 phòng)
- Tăng conversion rate

### **2. Business Logic:**

| Loại booking | Phương thức phù hợp |
|--------------|---------------------|
| 1 phòng, giá thấp (< 3M) | **Cash** hoặc **Pay at Hotel** |
| 1 phòng, giá cao (> 3M) | **Pay at Hotel** (không Cash) |
| 2 phòng | **Pay at Hotel** (không Cash) |
| 3+ phòng | **VNPay** (bắt buộc online) |

### **3. Quản lý rủi ro:**

**Cash** = Low risk:
- Giá trị thấp
- Chỉ 1 phòng
- Dễ xử lý nếu no-show

**Pay at Hotel** = Medium risk:
- Giá trị cao hơn
- Nhiều phòng hơn
- Cần confirmation từ manager

**VNPay** = No risk:
- Đã thanh toán trước
- Auto-confirm
- Không lo no-show

---

## 🔧 Thông Báo Lỗi

### **Khi user chọn Cash nhưng không đủ điều kiện:**

```dart
// payment_screen.dart - Line 101-115

if (method == PaymentMethod.cash && !_canUseCash) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        widget.roomCount >= 2
            ? 'Đặt từ 2 phòng trở lên không được thanh toán tiền mặt'
            : 'Tổng giá trị trên 3 triệu không được thanh toán tiền mặt',
      ),
      backgroundColor: Colors.orange,
    ),
  );
  return;
}
```

### **Disabled Cash Card:**

```dart
// payment_options.dart - Line 185-244

Widget _buildDisabledCashCard() {
  String reason = '';
  if (widget.roomCount >= 2) {
    reason = 'Đặt từ 2 phòng trở lên không được thanh toán tiền mặt';
  } else if (widget.totalAmount > 3000000) {
    reason = 'Tổng giá trị trên 3 triệu không được thanh toán tiền mặt';
  }
  
  return Container(
    // ... hiển thị card bị disabled với icon ❌
  );
}
```

---

## 📝 Kết Luận

### **Giống nhau:**
✅ Cùng luồng xử lý code  
✅ Cùng API endpoint  
✅ Cùng database structure  
✅ Cùng status "pending"  
✅ Cùng paid = 0  

### **Khác nhau:**

| Điểm khác | Pay at Hotel | Cash |
|-----------|--------------|------|
| **Điều kiện** | Dễ dàng (< 3 phòng) | Nghiêm ngặt (< 2 phòng, < 3M) |
| **Phương thức** | Tiền mặt **HOẶC** thẻ | **CHỈ** tiền mặt |
| **Use case** | Booking trung bình đến lớn | Booking nhỏ |
| **Rủi ro** | Trung bình | Thấp |
| **Database name** | "Pay at Hotel" | "Cash" |

### **Recommendation:**

🎯 **Khuyến nghị cho user:**
- **Booking nhỏ (1 phòng, < 3M):** Dùng **Cash** - đơn giản, truyền thống
- **Booking vừa (1-2 phòng, bất kỳ giá):** Dùng **Pay at Hotel** - linh hoạt hơn
- **Booking lớn (3+ phòng):** **BẮT BUỘC VNPay** - an toàn, auto-confirm

🏨 **Khuyến nghị cho khách sạn:**
- Chấp nhận **Cash** cho booking nhỏ (low risk)
- Khuyến khích **Pay at Hotel** cho booking trung bình (có thể dùng thẻ)
- Bắt buộc **VNPay** cho booking lớn (eliminate no-show risk)

---

**Version:** 1.0  
**Last Updated:** 2024-12-23  
**Author:** Trip Hotel Dev Team

