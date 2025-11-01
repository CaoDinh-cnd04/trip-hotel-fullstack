# 🔄 HƯỚNG DẪN: CHÍNH SÁCH HỦY PHÒNG 24 GIỜ

## 📋 TỔNG QUAN

Chính sách hủy phòng mới:
- ✅ **Có thể hủy miễn phí**: Nếu hủy **trước 24 giờ** so với thời gian nhận phòng
- ❌ **Không thể hủy**: Nếu còn **< 24 giờ** hoặc phòng **không hoàn tiền** (giá ưu đãi/cash)

---

## 🚀 CÀI ĐẶT

### **Bước 1: Chạy SQL Script**

```bash
# Mở SQL Server Management Studio (SSMS)
# Mở file: hotel-booking-backend/sql/update_cancellation_view_24h.sql
# Chạy script để cập nhật view
```

**Hoặc chạy trực tiếp:**
```sql
USE khach_san;
GO

-- Drop view cũ
DROP VIEW IF EXISTS vw_bookings_with_cancellation;
GO

-- Tạo view mới (xem file SQL để biết chi tiết)
CREATE VIEW vw_bookings_with_cancellation AS
SELECT 
    b.*,
    -- ... (các trường khác)
    CASE 
        WHEN b.cancellation_allowed = 1 
             AND b.booking_status IN ('pending', 'confirmed')
             AND DATEDIFF(HOUR, GETDATE(), b.check_in_date) >= 24
        THEN 1
        ELSE 0
    END as can_cancel_now,
    
    DATEDIFF(MINUTE, GETDATE(), b.check_in_date) as cancel_time_left_minutes
FROM dbo.bookings b
-- ... (các JOIN khác)
GO
```

### **Bước 2: Restart Backend**

```bash
cd hotel-booking-backend
node server.js
```

### **Bước 3: Test trên App**

1. **Hot Reload Flutter:**
   ```bash
   # Không cần restart, code đã được cập nhật
   ```

2. **Kiểm tra UI:**
   - Vào "Lịch sử đặt phòng"
   - Xem các booking có `cancellationAllowed = true`
   - Kiểm tra hiển thị countdown

---

## 🎯 LOGIC HỦY PHÒNG

### **1. Điều kiện để HỦY được:**

```
✅ CÓ THỂ HỦY khi:
   - cancellation_allowed = 1 (phòng refundable)
   - booking_status IN ('pending', 'confirmed')
   - check_in_date - now >= 24 hours

❌ KHÔNG THỂ HỦY khi:
   - cancellation_allowed = 0 (cash, giá ưu đãi)
   - check_in_date - now < 24 hours
   - booking_status NOT IN ('pending', 'confirmed')
```

### **2. Các loại phòng:**

| Loại | `cancellation_allowed` | Có thể hủy? | UI hiển thị |
|------|------------------------|-------------|-------------|
| 🟢 Online (VNPay/MoMo) | `true` | ✅ (nếu > 24h) | Box xanh + Timer |
| 🟢 Giá cao hơn + Khuyến nghị | `true` | ✅ (nếu > 24h) | Box xanh + Timer |
| 🔴 Cash (Thanh toán tại chỗ) | `false` | ❌ Không bao giờ | Box xám "Không thể hủy" |
| 🔴 Giá ưu đãi (Không hoàn tiền) | `false` | ❌ Không bao giờ | Box xám "Không thể hủy" |

---

## 📱 UI HIỂN THỊ

### **Case 1: Có thể hủy (> 24h, refundable)**

```
┌──────────────────────────────────────┐
│ ✅ Hủy miễn phí          [Hủy phòng] │  ← Box xanh
│ ⏱️ Còn 48 giờ để hủy miễn phí       │  ← Countdown
│    (trước 24h check-in)              │
└──────────────────────────────────────┘
```

### **Case 2: Không thể hủy (non-refundable)**

```
┌──────────────────────────────────────┐
│ 🚫 Không thể hủy -                   │  ← Box xám
│    Giá ưu đãi không hoàn tiền        │
└──────────────────────────────────────┘
```

### **Case 3: Không thể hủy (< 24h)**

```
┌──────────────────────────────────────┐
│ 🚫 Không thể hủy -                   │  ← Box xám
│    Chỉ có thể hủy trước 24h check-in │
└──────────────────────────────────────┘
```

---

## 🔍 KIỂM TRA

### **Test Case 1: Booking có thể hủy**

1. Đặt phòng với **VNPay/MoMo** (cancellation_allowed = true)
2. Check-in date = 2 ngày sau
3. Vào "Lịch sử đặt phòng"
4. **Kết quả mong đợi:**
   - ✅ Box xanh "Hủy miễn phí"
   - ✅ Timer hiển thị "Còn 48 giờ..."
   - ✅ Nút "Hủy phòng" xanh

### **Test Case 2: Booking cash (non-refundable)**

1. Đặt phòng với **Cash** (cancellation_allowed = false)
2. Vào "Lịch sử đặt phòng"
3. **Kết quả mong đợi:**
   - ❌ Box xám "Không thể hủy - Giá ưu đãi không hoàn tiền"
   - ❌ Không có nút hủy

### **Test Case 3: Booking < 24h (quá hạn)**

1. Đặt phòng refundable
2. Đợi đến khi check_in_date - now < 24h
3. **Kết quả mong đợi:**
   - ❌ Box xám "Không thể hủy"
   - ❌ Timer = 0
   - ❌ Không có nút hủy

---

## 🛠️ DEBUG

### **1. Kiểm tra view trong SQL:**

```sql
SELECT TOP 10
    booking_code,
    hotel_name,
    check_in_date,
    cancellation_allowed,
    booking_status,
    can_cancel_now,
    hours_left_to_cancel,
    cancel_time_left_minutes,
    DATEDIFF(HOUR, GETDATE(), check_in_date) as actual_hours_diff
FROM vw_bookings_with_cancellation
ORDER BY created_at DESC;
```

### **2. Kiểm tra backend log:**

```bash
# Khi user cố hủy phòng:
❌ Error cancelling booking: Error: Chỉ có thể hủy phòng trước 24 giờ so với thời gian nhận phòng

# Hoặc:
❌ Error cancelling booking: Error: Đơn đặt phòng này không cho phép hủy theo chính sách khách sạn
```

### **3. Kiểm tra Flutter response:**

```dart
// Trong booking_history_service.dart
print('🔍 Booking data: $booking');
print('   - can_cancel_now: ${booking.canCancelNow}');
print('   - seconds_left: ${booking.secondsLeftToCancel}');
print('   - cancellation_allowed: ${booking.cancellationAllowed}');
```

---

## 📝 THAY ĐỔI ĐÃ THỰC HIỆN

### **Backend:**

1. ✅ `hotel-booking-backend/models/booking.js`
   - Thay đổi logic `cancel()` từ 1p45s → 24h
   - Kiểm tra `DATEDIFF(HOUR, now, check_in_date) >= 24`

2. ✅ `hotel-booking-backend/sql/update_cancellation_view_24h.sql`
   - Cập nhật view `vw_bookings_with_cancellation`
   - Thêm trường `hours_left_to_cancel`
   - Logic: `can_cancel_now = 1` nếu >= 24h

### **Frontend (Flutter):**

1. ✅ `hotel_mobile/lib/presentation/widgets/booking_card.dart`
   - Cập nhật `_formatCountdown()` để hiển thị giờ/phút
   - Thêm text "(trước 24h check-in)"
   - UI box xanh cho refundable, xám cho non-refundable

---

## ⚠️ LƯU Ý QUAN TRỌNG

1. **Timezone:**
   - Backend dùng `GETDATE()` (SQL Server local time)
   - Flutter dùng `DateTime.now()` (device local time)
   - Đảm bảo server và device cùng timezone

2. **Grace Period:**
   - Hiện tại: **Chính xác 24h** (không có buffer)
   - Có thể điều chỉnh thành 24h + 1h buffer nếu cần:
     ```sql
     DATEDIFF(HOUR, GETDATE(), b.check_in_date) >= 25
     ```

3. **Refund Logic:**
   - Backend tự động set `refund_status = 'requested'`
   - `refundService.js` xử lý hoàn tiền qua VNPay/MoMo
   - Thời gian hoàn tiền: 3-5 ngày làm việc

---

## 🎉 KẾT LUẬN

✅ **Hoàn tất chính sách hủy phòng 24h:**
- ✅ Backend kiểm tra logic đúng
- ✅ SQL view tính toán chính xác
- ✅ Flutter UI hiển thị rõ ràng
- ✅ User experience tốt hơn

**Next Steps:**
1. Chạy SQL script
2. Restart backend
3. Test trên app
4. Deploy lên production

