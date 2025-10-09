# Hotel Booking API v2.0 - SQL Server Edition

API hệ thống đặt phòng khách sạn được thiết kế để hỗ trợ cả mobile app và web application với database SQL Server.

## 🚀 Tính năng chính

- ✅ **Database SQL Server** - Chuyển từ MySQL sang SQL Server
- ✅ **Mobile App Support** - API tối ưu cho mobile application  
- ✅ **Web App Support** - CORS được cấu hình cho web browser
- ✅ **Advanced Search** - Tìm kiếm khách sạn với nhiều bộ lọc
- ✅ **Real-time Data** - Cập nhật thông tin theo thời gian thực
- ✅ **Secure Authentication** - JWT token authentication
- ✅ **File Upload** - Hỗ trợ upload hình ảnh

## 📋 Yêu cầu hệ thống

- **Node.js** >= 14.x
- **SQL Server** (SQL Server Express hoặc cao hơn)
- **npm** hoặc **yarn**

## 🛠️ Cài đặt và cấu hình

### 1. Clone repository và cài đặt dependencies
```bash
cd hotel-booking-backend
npm install
```

### 2. Cấu hình SQL Server

#### a) Kích hoạt SQL Server Authentication:
1. Mở **SQL Server Management Studio (SSMS)**
2. Kết nối với **Windows Authentication**
3. Chuột phải vào Server → **Properties** → **Security**
4. Chọn **"SQL Server and Windows Authentication mode"**
5. **Restart SQL Server service**

#### b) Kích hoạt user "sa":
1. Trong SSMS: **Security** → **Logins** → **"sa"**
2. Chuột phải → **Properties**
3. **General tab**: Đặt mật khẩu mới (ví dụ: "123")
4. **Status tab**: Bỏ tích **"Login is disabled"**
5. Click **OK**

### 3. Tạo database và bảng
```sql
-- Chạy script này trong SSMS:
-- 1. Tạo database
CREATE DATABASE khach_san;

-- 2. Chạy toàn bộ script tạo bảng từ file database schema (xem user request)

-- 3. Chạy script tạo dữ liệu mẫu
-- Chạy file: sample-data.sql
```

### 4. Cấu hình file .env
```env
PORT=5000
# SQL Server Configuration  
DB_SERVER=LAPTOP-K91T0OHE\SQLEXPRESS01
DB_USER=sa
DB_PASS=123
DB_NAME=khach_san
DB_ENCRYPT=true
DB_TRUST_CERT=true
JWT_SECRET=your_jwt_secret_key_123456
```

### 5. Chạy ứng dụng
```bash
# Development mode
npm run dev

# Production mode  
npm start
```

## 📡 API Endpoints

### Base URL
```
http://localhost:5000/api
```

### Authentication
```
POST /api/auth/login     - Đăng nhập
POST /api/auth/register  - Đăng ký
```

### Hotels (V2 - Optimized)
```
GET  /api/v2/hotels                    - Lấy danh sách khách sạn (có phân trang)
GET  /api/v2/hotels/search             - Tìm kiếm khách sạn với bộ lọc
GET  /api/v2/hotels/:id                - Lấy thông tin khách sạn
GET  /api/v2/hotels/:id/details        - Lấy thông tin chi tiết (bao gồm phòng, tiện nghi)
POST /api/v2/hotels                    - Tạo khách sạn mới
PUT  /api/v2/hotels/:id                - Cập nhật khách sạn  
DELETE /api/v2/hotels/:id              - Xóa khách sạn
```

### Reference Data
```
GET /api/v2/reference/all              - Lấy tất cả dữ liệu tham chiếu
GET /api/v2/reference/countries        - Lấy danh sách quốc gia
GET /api/v2/reference/countries/:id    - Lấy thông tin quốc gia
GET /api/v2/reference/countries/:id/provinces - Lấy tỉnh thành theo quốc gia
```

### Users
```
GET  /api/nguoidung         - Lấy danh sách người dùng
GET  /api/nguoidung/:id     - Lấy thông tin người dùng
POST /api/nguoidung         - Tạo người dùng mới
PUT  /api/nguoidung/:id     - Cập nhật người dùng
```

### Health Check
```
GET /api/health            - Kiểm tra trạng thái API
GET /api                   - Thông tin API và endpoints
```

## 🔍 Tìm kiếm khách sạn

### URL: `/api/v2/hotels/search`

### Parameters:
```javascript
{
  vi_tri_id: "1",           // ID vị trí
  so_sao: "4",              // Số sao tối thiểu (1-5)
  gia_min: "500000",        // Giá tối thiểu
  gia_max: "2000000",       // Giá tối đa
  keyword: "hanoi",         // Từ khóa tìm kiếm
  ngay_den: "2024-12-01",   // Ngày đến (YYYY-MM-DD)
  ngay_di: "2024-12-03",    // Ngày đi (YYYY-MM-DD)
  so_khach: "2"             // Số khách
}
```

### Response:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "ten": "Hanoi Heritage Hotel",
      "mo_ta": "Khách sạn boutique tại trung tâm Hà Nội...",
      "hinh_anh": "/images/hotels/hanoi_heritage.jpg",
      "so_sao": 4,
      "dia_chi": "25 Phố Hàng Trống, Hoàn Kiếm, Hà Nội",
      "diem_danh_gia_trung_binh": 4.5,
      "so_luot_danh_gia": 128,
      "ten_vi_tri": "Hoàn Kiếm",
      "ten_tinh_thanh": "Hà Nội",
      "ten_quoc_gia": "Việt Nam"
    }
  ],
  "total": 1,
  "search_params": { ... }
}
```

## 📱 Mobile App Integration

### CORS Configuration
API đã được cấu hình CORS để hỗ trợ:
- React Native apps
- Ionic apps  
- Flutter web views
- Native mobile HTTP requests

### Recommended Headers
```javascript
// For mobile requests
headers: {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Authorization': 'Bearer ' + token  // Nếu cần authentication
}
```

## 🌐 Web App Integration  

### CORS Domains
API hỗ trợ requests từ:
- `http://localhost:3000` (React dev server)
- `http://localhost:8080` (Vue dev server)
- Local network IPs for testing

### Example Usage (JavaScript/React)
```javascript
// Lấy danh sách khách sạn
const response = await fetch('http://localhost:5000/api/v2/hotels?page=1&limit=10');
const data = await response.json();

if (data.success) {
  console.log('Hotels:', data.data);
  console.log('Pagination:', data.pagination);
}

// Tìm kiếm khách sạn
const searchResponse = await fetch('http://localhost:5000/api/v2/hotels/search?keyword=hanoi&so_sao=4');
const searchData = await searchResponse.json();
```

## 🔧 Troubleshooting

### Lỗi kết nối SQL Server
1. **Kiểm tra SQL Server service đang chạy**
   ```cmd
   services.msc → Tìm "SQL Server" services
   ```

2. **Kiểm tra tên server**
   ```cmd
   # Trong SSMS, kiểm tra server name chính xác
   SELECT @@SERVERNAME
   ```

3. **Kiểm tra port**
   ```cmd
   # SQL Server Configuration Manager
   # SQL Server Network Configuration → Protocols → TCP/IP
   ```

### Lỗi authentication
- Đảm bảo SQL Server Authentication đã được bật
- Kiểm tra user "sa" đã được kích hoạt
- Xác nhận mật khẩu trong file .env đúng

### Lỗi CORS (web app)
- Kiểm tra domain của web app có trong whitelist
- Đảm bảo headers được gửi đúng
- Kiểm tra preflight OPTIONS requests

## 📊 Database Schema

Database gồm các bảng chính:
- `nguoi_dung` - Người dùng
- `quoc_gia` - Quốc gia  
- `tinh_thanh` - Tỉnh thành
- `vi_tri` - Vị trí cụ thể
- `khach_san` - Khách sạn
- `phong` - Phòng
- `phieu_dat_phong` - Phiếu đặt phòng
- `danh_gia` - Đánh giá
- `tien_nghi` - Tiện nghi

## 🔐 Security Features

- **JWT Authentication** - Token-based authentication
- **Password Hashing** - bcrypt encryption
- **SQL Injection Protection** - Parameterized queries
- **CORS Protection** - Domain whitelist
- **Input Validation** - Request validation

## 📈 Performance Features

- **Connection Pooling** - SQL Server connection pool
- **Indexing** - Database indexes for fast queries  
- **Pagination** - Limit results for large datasets
- **Caching** - Response caching capabilities

## 🚀 Deployment

### Production Environment Variables
```env
NODE_ENV=production
PORT=80
DB_SERVER=your-production-server
DB_USER=your-production-user
DB_PASS=your-secure-password
DB_NAME=khach_san
JWT_SECRET=your-super-secure-jwt-secret
```

### PM2 Process Manager
```bash
npm install -g pm2
pm2 start server.js --name "hotel-api"
pm2 save
pm2 startup
```

---

## 📞 Support

Nếu cần hỗ trợ:
1. Kiểm tra logs trong console
2. Chạy health check: `GET /api/health`
3. Xem API documentation: `GET /api`

**API Version**: 2.0.0  
**Database**: SQL Server  
**Node.js**: 14.x+  
**Last Updated**: December 2024