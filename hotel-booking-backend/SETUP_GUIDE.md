# Hướng Dẫn Setup SQL Server cho Hotel Booking API

## 1. Cấu hình SQL Server

### Bước 1: Bật SQL Server Authentication
1. Mở SQL Server Management Studio (SSMS)
2. Kết nối với instance `LAPTOP-K91T00HE\SQLEXPRESS01`
3. Right-click trên server name → Properties
4. Chọn Security → chọn "SQL Server and Windows Authentication mode"
5. Click OK và restart SQL Server service

### Bước 2: Bật sa account
1. Trong SSMS, expand Security → Logins
2. Right-click trên "sa" → Properties
3. Tab General: đặt password là `123`
4. Tab Status: chọn "Enabled" cho Login

### Bước 3: Bật TCP/IP
1. Mở SQL Server Configuration Manager
2. SQL Server Network Configuration → Protocols for SQLEXPRESS01
3. Right-click TCP/IP → Enable
4. Right-click TCP/IP → Properties
5. Tab IP Addresses: tìm IPAll
6. Đặt TCP Port = 1433 (hoặc port bạn muốn)
7. Restart SQL Server service

## 2. Tạo Database và Tables

### Tạo database:
```sql
CREATE DATABASE khach_san;
USE khach_san;
```

### Tạo các bảng cơ bản (nếu chưa có):
```sql
-- Bảng NGUOIDUNG
CREATE TABLE NGUOIDUNG (
    MA_ND INT IDENTITY(1,1) PRIMARY KEY,
    HOTEN NVARCHAR(100) NOT NULL,
    EMAIL NVARCHAR(100) UNIQUE NOT NULL,
    MATKHAU NVARCHAR(255) NOT NULL,
    SODT NVARCHAR(20),
    NGAYSINH DATE,
    GIOITINH NVARCHAR(10),
    ANHDAIDIEN NVARCHAR(255),
    VAITRO NVARCHAR(20) DEFAULT 'user',
    NGAYTAO DATETIME DEFAULT GETDATE(),
    TRANGTHAI BIT DEFAULT 1
);

-- Bảng QUOCGIA
CREATE TABLE QUOCGIA (
    MA_QG INT IDENTITY(1,1) PRIMARY KEY,
    TEN_QG NVARCHAR(100) NOT NULL,
    HINHANH_QG NVARCHAR(255)
);

-- Bảng TINHTHANH
CREATE TABLE TINHTHANH (
    MA_TINHTHANH INT IDENTITY(1,1) PRIMARY KEY,
    TEN_TINHTHANH NVARCHAR(100) NOT NULL,
    MA_QG INT,
    HINHANH_TINHTHANH NVARCHAR(255),
    FOREIGN KEY (MA_QG) REFERENCES QUOCGIA(MA_QG)
);

-- Bảng VITRI
CREATE TABLE VITRI (
    MA_VITRI INT IDENTITY(1,1) PRIMARY KEY,
    TEN_VITRI NVARCHAR(100) NOT NULL,
    MA_TINHTHANH INT,
    FOREIGN KEY (MA_TINHTHANH) REFERENCES TINHTHANH(MA_TINHTHANH)
);

-- Bảng KHACHSAN
CREATE TABLE KHACHSAN (
    MA_KS INT IDENTITY(1,1) PRIMARY KEY,
    TEN_KS NVARCHAR(200) NOT NULL,
    DIACHI NVARCHAR(500),
    MA_VITRI INT,
    HINHANH NVARCHAR(255),
    MOTA NTEXT,
    SOSAO INT CHECK (SOSAO >= 1 AND SOSAO <= 5),
    TRANGTHAI BIT DEFAULT 1,
    NGAYTAO DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (MA_VITRI) REFERENCES VITRI(MA_VITRI)
);
```

## 3. Test Kết Nối

### Bước 1: Test kết nối đơn giản
```bash
cd d:\DACN\baocao\hotel-booking-backend
node test-server.js
```

### Bước 2: Kiểm tra các endpoint
- http://localhost:3001/test - Test kết nối cơ bản
- http://localhost:3001/test/users - Test bảng NGUOIDUNG
- http://localhost:3001/test/countries - Test bảng QUOCGIA
- http://localhost:3001/test/hotels - Test bảng KHACHSAN

### Bước 3: Chạy server chính
```bash
npm start
```

## 4. API Endpoints

### Auth
- POST /api/auth/login - Đăng nhập
- POST /api/auth/register - Đăng ký

### Reference Data
- GET /api/v2/reference/all - Lấy tất cả dữ liệu tham chiếu
- GET /api/v2/reference/countries - Danh sách quốc gia
- GET /api/v2/reference/countries/:id/provinces - Tỉnh thành theo quốc gia

### Hotels
- GET /api/v2/hotels - Danh sách khách sạn
- GET /api/v2/hotels/:id - Chi tiết khách sạn
- GET /api/v2/hotels/search - Tìm kiếm khách sạn

### Health Check
- GET /api/health - Kiểm tra trạng thái API

## 5. Troubleshooting

### Lỗi kết nối:
1. Kiểm tra SQL Server service có chạy không
2. Kiểm tra tên server: `LAPTOP-K91T00HE\SQLEXPRESS01`
3. Kiểm tra sa account đã enable chưa
4. Kiểm tra TCP/IP protocol đã enable chưa

### Lỗi authentication:
1. Đảm bảo Mixed Mode Authentication được bật
2. Đảm bảo sa password = `123`
3. Restart SQL Server service sau khi thay đổi

### Lỗi database:
1. Đảm bảo database `khach_san` đã được tạo
2. Kiểm tra các bảng có tồn tại không
3. Chạy script tạo bảng nếu cần

## 6. File Cấu Hình

### .env
```
PORT=5000
DB_SERVER=LAPTOP-K91T00HE\SQLEXPRESS01
DB_USER=sa
DB_PASS=123
DB_NAME=khach_san
DB_ENCRYPT=false
DB_TRUST_CERT=true
JWT_SECRET=your_jwt_secret_key_123456
```

### package.json scripts
```json
{
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "node test-server.js"
  }
}
```

Sau khi hoàn thành setup, API sẽ hỗ trợ cả mobile app và web với CORS đã được cấu hình phù hợp.