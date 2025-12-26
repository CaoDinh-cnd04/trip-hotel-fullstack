# VIP Theme System

## Tổng quan

Hệ thống VIP Theme tự động thay đổi màu sắc của toàn bộ ứng dụng dựa trên VIP tier của user:

- **Bronze (Đồng)**: Màu nâu/đồng (#8B4513)
- **Silver (Bạc)**: Màu xám/bạc (#9E9E9E)
- **Gold (Vàng)**: Màu vàng (#FFB300)
- **Diamond (Kim Cương)**: Màu xanh dương/teal (#00BCD4)

## Cách hoạt động

1. **VipThemeProvider**: Quản lý VIP level và theme colors
   - Tự động load VIP level từ cache khi app khởi động
   - Tự động load VIP level từ API khi user đã đăng nhập
   - Lưu VIP level vào cache để hiển thị ngay

2. **VipTheme**: Tạo ThemeData động dựa trên VIP level
   - AppBar: Màu chính theo VIP tier
   - Buttons: Màu chính theo VIP tier
   - Cards: Border màu theo VIP tier
   - Inputs: Focus border màu theo VIP tier
   - Background: Màu nền nhạt theo VIP tier

3. **Tích hợp vào MaterialApp**: Theme được áp dụng tự động cho toàn bộ app

## Sử dụng trong code

### Cách 1: Sử dụng Theme từ context (Khuyến nghị)

```dart
// AppBar tự động sử dụng VIP theme
AppBar(
  title: Text('Tiêu đề'),
  // backgroundColor sẽ tự động là VIP primary color
)

// Button tự động sử dụng VIP theme
ElevatedButton(
  onPressed: () {},
  child: Text('Nút bấm'),
  // backgroundColor sẽ tự động là VIP primary color
)
```

### Cách 2: Truy cập VIP colors trực tiếp

```dart
import 'package:provider/provider.dart';
import '../../../core/theme/vip_theme_provider.dart';

// Trong build method
final vipTheme = Provider.of<VipThemeProvider>(context, listen: false);

Container(
  color: vipTheme.primaryColor, // Màu chính theo VIP tier
  child: Text('Nội dung'),
)
```

### Cách 3: Sử dụng Extension (Dễ nhất)

```dart
import '../../../core/theme/vip_theme_extensions.dart';

// Trong build method
Container(
  color: context.vipPrimaryColor, // Màu chính
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: context.vipGradientColors, // Gradient colors
    ),
  ),
  child: Text('Nội dung'),
)
```

## Refresh VIP Level

Khi VIP level thay đổi (ví dụ sau khi thanh toán), gọi:

```dart
final vipTheme = Provider.of<VipThemeProvider>(context, listen: false);
await vipTheme.refreshVipLevel();
```

Hoặc sử dụng extension:

```dart
await context.refreshVipLevel();
```

## Lưu ý

- Theme được cache để hiển thị ngay khi app khởi động
- Theme tự động cập nhật khi user đăng nhập và VIP level được load từ API
- Tất cả Material widgets (AppBar, Button, Card, etc.) tự động sử dụng VIP theme
- Nếu cần custom colors, sử dụng `vipTheme.primaryColor` thay vì hardcode

