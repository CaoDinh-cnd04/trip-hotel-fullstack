# Hướng dẫn cấu hình đăng nhập Google và Facebook

## Bước 1: Tạo file .env

Tạo file `.env` trong thư mục `hotel_web` với nội dung sau:

```env
# API Configuration
VITE_API_BASE_URL=http://localhost:5000/api
VITE_API_ROOT_URL=http://localhost:5000
VITE_IMAGES_BASE_URL=http://localhost:5000/images

# Google OAuth
VITE_GOOGLE_CLIENT_ID=YOUR_GOOGLE_CLIENT_ID

# Facebook OAuth
VITE_FACEBOOK_APP_ID=1361581552264816
```

## Bước 2: Lấy Google Client ID

1. Truy cập [Google Cloud Console](https://console.cloud.google.com/)
2. Tạo một dự án mới hoặc chọn dự án hiện có
3. Vào **APIs & Services** > **Credentials**
4. Nhấn **Create Credentials** > **OAuth 2.0 Client ID**
5. Chọn **Web application**
6. Thêm **Authorized JavaScript origins**:
   - `http://localhost:3000`
7. Thêm **Authorized redirect URIs**:
   - `http://localhost:3000`
8. Copy **Client ID** và dán vào file `.env` thay cho `YOUR_GOOGLE_CLIENT_ID`

## Bước 3: Cấu hình Facebook (đã có sẵn)

Facebook App ID đã được cấu hình sẵn: `1361581552264816`

Nếu cần tạo mới:
1. Truy cập [Facebook Developers](https://developers.facebook.com/apps/)
2. Tạo ứng dụng mới
3. Thêm sản phẩm **Facebook Login**
4. Vào **Settings** > **Basic** và copy **App ID**
5. Thêm `http://localhost:3000` vào **Valid OAuth Redirect URIs**

## Bước 4: Khởi động lại server

Sau khi cấu hình xong, khởi động lại server Vite:

```bash
npm run dev
```

## Lưu ý

- File `.env` không được commit lên Git (đã có trong `.gitignore`)
- Sau khi thay đổi `.env`, cần **restart server** để áp dụng thay đổi
- Đảm bảo backend đang chạy tại `http://localhost:5000`

