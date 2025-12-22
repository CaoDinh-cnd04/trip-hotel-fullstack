const HotelRegistration = require('../models/hotelRegistration');
const NguoiDung = require('../models/nguoidung');
const EmailService = require('../services/emailService');
const path = require('path');
const fs = require('fs');

/**
 * Tạo đơn đăng ký khách sạn mới
 */
exports.createRegistration = async (req, res) => {
  try {
    const {
      owner_name,
      owner_email,
      owner_phone,
      hotel_name,
      hotel_type,
      address,
      province_id,
      district,
      latitude,
      longitude,
      description,
      star_rating,
      tax_id,
      business_license,
      // New fields
      contact_email,
      contact_phone,
      website,
      check_in_time,
      check_out_time,
      require_deposit,
      deposit_rate,
      cancellation_policy,
      total_rooms,
      rooms, // Array of room types
    } = req.body;

    // Validate required fields
    if (!owner_name || !owner_email || !owner_phone || !hotel_name || !hotel_type || !address || !province_id) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng điền đầy đủ thông tin bắt buộc'
      });
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(owner_email)) {
      return res.status(400).json({
        success: false,
        message: 'Email không hợp lệ'
      });
    }

    // Validate phone number (Vietnam format)
    const phoneRegex = /^(0|\+84)[0-9]{9,10}$/;
    if (!phoneRegex.test(owner_phone)) {
      return res.status(400).json({
        success: false,
        message: 'Số điện thoại không hợp lệ'
      });
    }

    // Validate rooms (if provided)
    if (rooms && rooms.length > 0) {
      console.log(`📝 Registration includes ${rooms.length} room types`);
    }

    // Create registration
    const registrationData = {
      owner_name,
      owner_email: owner_email.toLowerCase(),
      owner_phone,
      hotel_name,
      hotel_type,
      address,
      province_id,
      district,
      latitude,
      longitude,
      description,
      star_rating,
      tax_id,
      business_license,
      // New fields
      contact_email: contact_email || owner_email,
      contact_phone: contact_phone || owner_phone,
      website,
      check_in_time,
      check_out_time,
      require_deposit,
      deposit_rate,
      cancellation_policy,
      total_rooms,
      rooms_data: rooms ? JSON.stringify(rooms) : null, // Store as JSON string
    };

    const registrationId = await HotelRegistration.create(registrationData);

    console.log('✅ Hotel registration created:', registrationId);
    if (rooms && rooms.length > 0) {
      console.log(`📝 With ${rooms.length} room types:`, rooms.map(r => `${r.name} (x${r.quantity})`).join(', '));
    }

    // Send confirmation email to owner
    try {
      await EmailService.sendEmail({
        to: owner_email,
        subject: 'Xác nhận đăng ký khách sạn trên Triphotel',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #2c5aa0;">Xin chào ${owner_name}!</h2>
            <p>Cảm ơn bạn đã đăng ký cơ sở lưu trú <strong>${hotel_name}</strong> trên Triphotel.</p>
            
            <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
              <h3 style="margin-top: 0;">Thông tin đăng ký:</h3>
              <p><strong>Tên khách sạn:</strong> ${hotel_name}</p>
              <p><strong>Loại hình:</strong> ${hotel_type}</p>
              <p><strong>Địa chỉ:</strong> ${address}</p>
              <p><strong>Mã đơn:</strong> #${registrationId}</p>
            </div>

            <p><strong>Bước tiếp theo:</strong></p>
            <ol>
              <li>Đội ngũ Triphotel sẽ xem xét đơn đăng ký của bạn trong vòng 24-48 giờ</li>
              <li>Sau khi được duyệt, bạn sẽ nhận được email hướng dẫn thiết lập tài khoản quản lý</li>
              <li>Bạn có thể bắt đầu đăng phòng và nhận đặt phòng từ khách hàng</li>
            </ol>

            <p>Nếu có bất kỳ thắc mắc nào, vui lòng liên hệ với chúng tôi qua email này.</p>
            
            <p style="margin-top: 30px;">Trân trọng,<br><strong>Đội ngũ Triphotel</strong></p>
          </div>
        `
      });
    } catch (emailError) {
      console.error('❌ Error sending confirmation email:', emailError);
      // Continue even if email fails
    }

    // Notify admin (optional)
    try {
      // Send notification to admin email
      await EmailService.sendEmail({
        to: process.env.ADMIN_EMAIL || 'admin@triphotel.com',
        subject: `Đơn đăng ký khách sạn mới #${registrationId}`,
        html: `
          <h3>Đơn đăng ký khách sạn mới</h3>
          <p><strong>Tên khách sạn:</strong> ${hotel_name}</p>
          <p><strong>Chủ sở hữu:</strong> ${owner_name}</p>
          <p><strong>Email:</strong> ${owner_email}</p>
          <p><strong>SĐT:</strong> ${owner_phone}</p>
          <p><strong>Loại hình:</strong> ${hotel_type}</p>
          <p><a href="${process.env.ADMIN_URL || 'http://localhost:3000'}/admin/hotel-registrations/${registrationId}">Xem chi tiết</a></p>
        `
      });
    } catch (error) {
      console.error('❌ Error sending admin notification:', error);
    }

    res.status(201).json({
      success: true,
      message: 'Đăng ký thành công! Chúng tôi sẽ xem xét và liên hệ với bạn trong vòng 24-48 giờ.',
      data: {
        registration_id: registrationId,
        status: 'pending'
      }
    });

  } catch (error) {
    console.error('❌ Create registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi tạo đơn đăng ký',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Lấy tất cả đơn đăng ký (Admin)
 */
exports.getAllRegistrations = async (req, res) => {
  try {
    const { status } = req.query;
    
    const filters = {};
    if (status) {
      filters.status = status;
    }

    const registrations = await HotelRegistration.getAll(filters);

    res.json({
      success: true,
      count: registrations.length,
      data: registrations
    });

  } catch (error) {
    console.error('❌ Get all registrations error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy danh sách đơn đăng ký'
    });
  }
};

/**
 * Lấy đơn đăng ký theo ID
 */
exports.getRegistrationById = async (req, res) => {
  try {
    const { id } = req.params;

    const registration = await HotelRegistration.getById(id);

    if (!registration) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy đơn đăng ký'
      });
    }

    res.json({
      success: true,
      data: registration
    });

  } catch (error) {
    console.error('❌ Get registration by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy thông tin đơn đăng ký'
    });
  }
};

/**
 * Lấy đơn đăng ký của user (theo email)
 */
exports.getMyRegistrations = async (req, res) => {
  try {
    const userEmail = req.user?.email; // From auth middleware

    if (!userEmail) {
      return res.status(401).json({
        success: false,
        message: 'Vui lòng đăng nhập'
      });
    }

    const registrations = await HotelRegistration.getByEmail(userEmail);

    res.json({
      success: true,
      count: registrations.length,
      data: registrations
    });

  } catch (error) {
    console.error('❌ Get my registrations error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy danh sách đơn đăng ký'
    });
  }
};

/**
 * Cập nhật trạng thái đơn đăng ký (Admin)
 */
exports.updateRegistrationStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, admin_note } = req.body;

    // Validate status
    const validStatuses = ['pending', 'approved', 'rejected', 'completed'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Trạng thái không hợp lệ'
      });
    }

    const registration = await HotelRegistration.getById(id);
    if (!registration) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy đơn đăng ký'
      });
    }

    await HotelRegistration.updateStatus(id, status, admin_note);

    // If approved, create hotel manager account
    if (status === 'approved') {
      try {
        // Check if user already exists
        const nguoiDung = new NguoiDung();
        let user = await nguoiDung.findByEmail(registration.owner_email);
        
        if (!user) {
          // Create new hotel manager account
          const userData = {
            ho_ten: registration.owner_name,
            email: registration.owner_email,
            mat_khau: 'temp_password_' + Date.now(), // Temporary password, user will reset via email
            sdt: registration.owner_phone,
            chuc_vu: 'HotelManager', // ✅ FIX: Dùng 'HotelManager' thay vì 'Manager'
            trang_thai: 1,
            ngay_dang_ky: new Date()
          };
          
          const userId = await nguoiDung.create(userData);
          user = await nguoiDung.findById(userId);
          console.log('✅ Created hotel manager account:', user.id);
        } else {
          // Update existing user to HotelManager role
          await nguoiDung.updateRole(user.id, 'HotelManager'); // ✅ FIX: Dùng 'HotelManager'
          console.log('✅ Updated user role to HotelManager:', user.id);
        }

        // === TỰ ĐỘNG TẠO KHÁCH SẠN TRONG SQL SERVER ===
        try {
          const { getPool } = require('../config/db');
          const sql = require('mssql');
          const pool = await getPool();

          // Tìm hoặc tạo vi_tri từ province_id
          let viTriId = null;
          const viTriResult = await pool.request()
            .input('tinhThanhId', sql.Int, registration.province_id)
            .query(`
              SELECT TOP 1 id 
              FROM dbo.vi_tri 
              WHERE tinh_thanh_id = @tinhThanhId
            `);

          if (viTriResult.recordset.length > 0) {
            viTriId = viTriResult.recordset[0].id;
          } else {
            // Tạo vi_tri mới nếu chưa có
            const newViTriResult = await pool.request()
              .input('ten', sql.NVarChar, registration.district || 'Trung tâm')
              .input('tinhThanhId', sql.Int, registration.province_id)
              .input('trangThai', sql.Int, 1)
              .query(`
                INSERT INTO dbo.vi_tri (ten, tinh_thanh_id, trang_thai)
                OUTPUT INSERTED.id
                VALUES (@ten, @tinhThanhId, @trangThai)
              `);
            viTriId = newViTriResult.recordset[0].id;
            console.log('✅ Created new vi_tri:', viTriId);
          }

          // Xử lý hình ảnh khách sạn (nếu có)
          let hinhAnh = null;
          let hotelImages = []; // Lưu danh sách hình ảnh đã xử lý
          
          if (registration.hotel_images) {
            try {
              const hotelImages = JSON.parse(registration.hotel_images);
              if (hotelImages && hotelImages.length > 0) {
                console.log(`📸 Processing ${hotelImages.length} hotel images...`);
                
                // Di chuyển và xử lý tất cả hình ảnh
                const processedImages = [];
                const imagesDir = path.join(__dirname, '..', 'images', 'hotels');
                const uploadsDir = path.join(__dirname, '..', 'uploads');
                
                // Đảm bảo thư mục images/hotels tồn tại
                if (!fs.existsSync(imagesDir)) {
                  fs.mkdirSync(imagesDir, { recursive: true });
                }
                
                for (let i = 0; i < hotelImages.length; i++) {
                  const imagePath = hotelImages[i];
                  let finalImagePath = imagePath;
                  
                  // Nếu ảnh ở trong uploads/hotel_registration, di chuyển sang images/hotels
                  if (imagePath.includes('/uploads/hotel_registration/')) {
                    const fileName = imagePath.split('/').pop();
                    const sourcePath = path.join(uploadsDir, 'hotel_registration', fileName);
                    const destPath = path.join(imagesDir, fileName);
                    
                    try {
                      if (fs.existsSync(sourcePath)) {
                        fs.copyFileSync(sourcePath, destPath);
                        console.log(`✅ Moved image: ${fileName}`);
                        finalImagePath = `/images/hotels/${fileName}`;
                      } else {
                        console.log(`⚠️ Source image not found: ${sourcePath}`);
                        // Giữ nguyên đường dẫn nếu file không tồn tại
                        finalImagePath = imagePath;
                      }
                    } catch (copyError) {
                      console.error(`❌ Error copying image ${fileName}:`, copyError);
                      finalImagePath = imagePath; // Giữ nguyên nếu lỗi
                    }
                  } else if (!imagePath.startsWith('/images/') && !imagePath.startsWith('http')) {
                    // Nếu chỉ là tên file, thêm prefix
                    finalImagePath = `/images/hotels/${imagePath}`;
                  }
                  
                  processedImages.push(finalImagePath);
                }
                
                // Lưu danh sách hình ảnh đã xử lý
                hotelImages = processedImages;
                
                // Lưu danh sách hình ảnh đã xử lý
                hotelImages = processedImages;
                
                // Lấy ảnh đầu tiên làm ảnh đại diện
                hinhAnh = processedImages[0];
                // Nếu là đường dẫn đầy đủ, chỉ lấy tên file cho cột hinh_anh
                if (hinhAnh.includes('/')) {
                  const fileName = hinhAnh.split('/').pop();
                  hinhAnh = fileName;
                }
                
                console.log(`✅ Processed ${processedImages.length} images, main image: ${hinhAnh}`);
              }
            } catch (e) {
              console.log('⚠️ Could not parse hotel_images:', e.message);
            }
          }

          // Tạo khách sạn trong bảng khach_san với dữ liệu từ registration
          const hotelResult = await pool.request()
            .input('ten', sql.NVarChar, registration.hotel_name)
            .input('moTa', sql.NVarChar, registration.description || '')
            .input('diaChi', sql.NVarChar, registration.address)
            .input('viTriId', sql.Int, viTriId)
            .input('soSao', sql.Int, registration.star_rating || 3)
            .input('chuKhachSanId', sql.Int, user.id)
            .input('emailLienHe', sql.NVarChar, registration.contact_email || registration.owner_email)
            .input('sdtLienHe', sql.NVarChar, registration.contact_phone || registration.owner_phone)
            .input('website', sql.NVarChar, registration.website || null)
            .input('hinhAnh', sql.NVarChar, hinhAnh || null)
            .input('gioNhanPhong', sql.Time, registration.check_in_time || '14:00:00')
            .input('gioTraPhong', sql.Time, registration.check_out_time || '12:00:00')
            .input('yeuCauCoc', sql.Bit, registration.require_deposit !== undefined ? registration.require_deposit : 1)
            .input('tiLeCoc', sql.Decimal(5, 2), registration.deposit_rate || 30)
            .input('chinhSachHuy', sql.NVarChar, registration.cancellation_policy || 'Hủy miễn phí trước 24h. Sau đó mất phí 50% giá trị đặt phòng.')
            .input('tongSoPhong', sql.Int, registration.total_rooms || 10)
            .input('trangThai', sql.NVarChar, 'Hoạt động') // Đảm bảo khách sạn hiển thị trên giao diện chính
            .query(`
              INSERT INTO dbo.khach_san (
                ten, mo_ta, dia_chi, vi_tri_id, so_sao, 
                chu_khach_san_id, email_lien_he, sdt_lien_he, website, hinh_anh,
                gio_nhan_phong, gio_tra_phong, yeu_cau_coc, ti_le_coc,
                chinh_sach_huy, tong_so_phong, trang_thai
              )
              OUTPUT INSERTED.id
              VALUES (
                @ten, @moTa, @diaChi, @viTriId, @soSao,
                @chuKhachSanId, @emailLienHe, @sdtLienHe, @website, @hinhAnh,
                @gioNhanPhong, @gioTraPhong, @yeuCauCoc, @tiLeCoc,
                @chinhSachHuy, @tongSoPhong, @trangThai
              )
            `);

          const hotelId = hotelResult.recordset[0].id;
          console.log('✅ Created hotel in database:', hotelId);

          // === LƯU TẤT CẢ HÌNH ẢNH KHÁCH SẠN ===
          if (hotelImages && hotelImages.length > 0) {
            try {
              // Tạo bảng anh_khach_san nếu chưa có
              try {
                const checkTableQuery = `
                  SELECT TABLE_NAME 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'anh_khach_san'
                `;
                const tableExists = await pool.request().query(checkTableQuery);
                
                if (tableExists.recordset.length === 0) {
                  // Tạo bảng mới để lưu nhiều hình ảnh
                  await pool.request().query(`
                    CREATE TABLE dbo.anh_khach_san (
                      id INT IDENTITY(1,1) PRIMARY KEY,
                      khach_san_id INT NOT NULL,
                      duong_dan_anh NVARCHAR(500) NOT NULL,
                      thu_tu INT DEFAULT 0,
                      la_anh_dai_dien BIT DEFAULT 0,
                      created_at DATETIME DEFAULT GETDATE(),
                      FOREIGN KEY (khach_san_id) REFERENCES dbo.khach_san(id) ON DELETE CASCADE
                    )
                  `);
                  console.log('✅ Created table anh_khach_san');
                }
              } catch (tableError) {
                // Bảng có thể đã tồn tại hoặc có lỗi, tiếp tục
                console.log('⚠️ Table check/create error (may already exist):', tableError.message);
              }
              
              // Lưu tất cả hình ảnh vào bảng anh_khach_san
              for (let i = 0; i < hotelImages.length; i++) {
                const imagePath = hotelImages[i];
                const isMain = i === 0; // Ảnh đầu tiên là ảnh đại diện
                
                try {
                  await pool.request()
                    .input('khachSanId', sql.Int, hotelId)
                    .input('duongDanAnh', sql.NVarChar, imagePath)
                    .input('thuTu', sql.Int, i + 1)
                    .input('laAnhDaiDien', sql.Bit, isMain ? 1 : 0)
                    .query(`
                      INSERT INTO dbo.anh_khach_san (khach_san_id, duong_dan_anh, thu_tu, la_anh_dai_dien)
                      VALUES (@khachSanId, @duongDanAnh, @thuTu, @laAnhDaiDien)
                    `);
                } catch (insertError) {
                  console.error(`❌ Error inserting image ${i + 1}:`, insertError.message);
                  // Continue with next image
                }
              }
              
              console.log(`✅ Saved ${hotelImages.length} images to database for hotel ${hotelId}`);
            } catch (imageSaveError) {
              console.error('❌ Error saving hotel images to database:', imageSaveError);
              // Continue even if image saving fails
            }
          }

          // === TỰ ĐỘNG TẠO CÁC LOẠI PHÒNG TỪ ROOMS_DATA ===
          if (registration.rooms_data) {
            try {
              const roomsData = JSON.parse(registration.rooms_data);
              console.log(`📝 Creating ${roomsData.length} room types...`);

              for (const roomData of roomsData) {
                // Tạo từng phòng với số lượng tương ứng
                for (let i = 1; i <= roomData.quantity; i++) {
                  const roomCode = `${registration.hotel_name.substring(0, 3).toUpperCase()}-${roomData.room_type}-${String(i).padStart(3, '0')}`;
                  
                  await pool.request()
                    .input('ten', sql.NVarChar, `${roomData.name} ${i}`)
                    .input('maPhong', sql.NVarChar, roomCode)
                    .input('moTa', sql.NVarChar, roomData.description || '')
                    .input('giaTien', sql.Decimal(18, 2), roomData.price)
                    .input('dienTich', sql.Float, roomData.area || null)
                    .input('khachSanId', sql.Int, hotelId)
                    .input('loaiPhongId', sql.Int, parseInt(roomData.room_type)) // 1-6: Standard, Superior, Double, Family, Suite, Deluxe
                    .input('trangThai', sql.NVarChar, 'Trống')
                    .query(`
                      INSERT INTO dbo.phong (
                        ten, ma_phong, mo_ta, gia_tien, dien_tich,
                        khach_san_id, loai_phong_id, trang_thai
                      )
                      VALUES (
                        @ten, @maPhong, @moTa, @giaTien, @dienTich,
                        @khachSanId, @loaiPhongId, @trangThai
                      )
                    `);
                }
              }

              console.log(`✅ Created all rooms for hotel ${hotelId}`);
            } catch (roomCreationError) {
              console.error('❌ Error creating rooms:', roomCreationError);
              // Continue even if room creation fails
            }
          }

          // Update registration với hotel_id
          await pool.request()
            .input('registrationId', sql.Int, id)
            .input('hotelId', sql.Int, hotelId)
            .query(`
              UPDATE dbo.hotel_registrations 
              SET hotel_id = @hotelId
              WHERE id = @registrationId
            `);

        } catch (hotelCreationError) {
          console.error('❌ Error creating hotel in database:', hotelCreationError);
          // Continue even if hotel creation fails, user can create manually
        }

        // Send approval email with setup instructions
        const tempPassword = user.mat_khau && user.mat_khau.startsWith('temp_password_') 
          ? 'Vui lòng đặt lại mật khẩu khi đăng nhập lần đầu' 
          : 'Sử dụng mật khẩu hiện tại của bạn';
        
        await EmailService.sendEmail({
          to: registration.owner_email,
          subject: '🎉 Đơn đăng ký khách sạn của bạn đã được duyệt!',
          html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2 style="color: #28a745;">Chúc mừng ${registration.owner_name}!</h2>
              <p>Đơn đăng ký khách sạn <strong>${registration.hotel_name}</strong> của bạn đã được duyệt thành công.</p>
              
              <div style="background-color: #d4edda; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #28a745;">
                <h3 style="margin-top: 0; color: #155724;">✅ Tài khoản của bạn đã được tạo:</h3>
                <ul style="margin: 10px 0; padding-left: 20px; color: #155724;">
                  <li><strong>Email đăng nhập:</strong> ${registration.owner_email}</li>
                  <li><strong>Quyền truy cập:</strong> Quản lý khách sạn (HotelManager)</li>
                  <li><strong>Mật khẩu:</strong> ${tempPassword}</li>
                </ul>
              </div>

              <div style="background-color: #fff3cd; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #ffc107;">
                <h3 style="margin-top: 0; color: #856404;">📋 Khách sạn của bạn đã được thêm vào hệ thống:</h3>
                <ul style="margin: 10px 0; padding-left: 20px; color: #856404;">
                  <li>Khách sạn <strong>${registration.hotel_name}</strong> đã được tạo trong hệ thống</li>
                  <li>Khách sạn đã hiển thị trên giao diện chính của website</li>
                  <li>Bạn có thể quản lý khách sạn ngay bây giờ</li>
                </ul>
              </div>

              <div style="background-color: #d1ecf1; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #0c5460;">
                <h3 style="margin-top: 0; color: #0c5460;">🚀 Bước tiếp theo:</h3>
                <ol style="margin: 10px 0; padding-left: 20px; color: #0c5460;">
                  <li>Đăng nhập vào Triphotel bằng email: <strong>${registration.owner_email}</strong></li>
                  <li>${user.mat_khau && user.mat_khau.startsWith('temp_password_') ? 'Thiết lập mật khẩu mới (bắt buộc)' : 'Sử dụng mật khẩu hiện tại'}</li>
                  <li>Truy cập phần quản lý khách sạn để hoàn thiện thông tin</li>
                  <li>Thêm ảnh, mô tả chi tiết, tiện nghi cho khách sạn</li>
                  <li>Quản lý phòng và giá cả</li>
                  <li>Bắt đầu nhận đặt phòng từ khách hàng!</li>
                </ol>
              </div>

              <div style="text-align: center; margin: 30px 0;">
                <a href="${process.env.APP_URL || 'http://localhost:3000'}/login" 
                   style="background-color: #2c5aa0; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;">
                  🔐 Đăng nhập ngay
                </a>
              </div>

              ${admin_note ? `
                <div style="background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0;">
                  <p style="margin: 0;"><strong>💬 Ghi chú từ admin:</strong></p>
                  <p style="margin: 5px 0 0 0;">${admin_note}</p>
                </div>
              ` : ''}

              <p style="margin-top: 30px;">Chúc bạn thành công với khách sạn của mình!</p>
              <p>Trân trọng,<br><strong>Đội ngũ Triphotel</strong></p>
            </div>
          `
        });

      } catch (error) {
        console.error('❌ Error creating manager account:', error);
        // Continue even if account creation fails
      }
    }

    // If rejected, send rejection email
    if (status === 'rejected') {
      try {
        await EmailService.sendEmail({
          to: registration.owner_email,
          subject: '❌ Thông báo về đơn đăng ký khách sạn',
          html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2 style="color: #dc3545;">Thông báo về đơn đăng ký</h2>
              <p>Xin chào <strong>${registration.owner_name}</strong>,</p>
              
              <div style="background-color: #f8d7da; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #dc3545;">
                <p style="margin: 0; color: #721c24;">
                  Chúng tôi rất tiếc phải thông báo rằng đơn đăng ký khách sạn <strong>${registration.hotel_name}</strong> của bạn chưa được chấp nhận tại thời điểm này.
                </p>
              </div>
              
              ${admin_note ? `
                <div style="background-color: #fff3cd; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #ffc107;">
                  <p style="margin: 0; color: #856404;"><strong>📝 Lý do từ chối:</strong></p>
                  <p style="margin: 5px 0 0 0; color: #856404;">${admin_note}</p>
                </div>
              ` : `
                <div style="background-color: #fff3cd; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #ffc107;">
                  <p style="margin: 0; color: #856404;">
                    Vui lòng kiểm tra lại thông tin đăng ký và đảm bảo đã điền đầy đủ, chính xác các thông tin bắt buộc.
                  </p>
                </div>
              `}

              <div style="background-color: #d1ecf1; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #0c5460;">
                <h3 style="margin-top: 0; color: #0c5460;">🔄 Bạn có thể:</h3>
                <ul style="margin: 10px 0; padding-left: 20px; color: #0c5460;">
                  <li>Chỉnh sửa thông tin đăng ký dựa trên phản hồi (nếu có)</li>
                  <li>Gửi lại đơn đăng ký mới với thông tin đã được cập nhật</li>
                  <li>Liên hệ với chúng tôi nếu cần hỗ trợ hoặc có thắc mắc</li>
                </ul>
              </div>

              <div style="text-align: center; margin: 30px 0;">
                <a href="${process.env.APP_URL || 'http://localhost:3000'}/hotel-registration" 
                   style="background-color: #2c5aa0; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;">
                  📝 Đăng ký lại
                </a>
              </div>

              <p>Nếu bạn có bất kỳ câu hỏi nào, vui lòng liên hệ với chúng tôi qua email này hoặc hotline hỗ trợ.</p>
              
              <p style="margin-top: 30px;">Trân trọng,<br><strong>Đội ngũ Triphotel</strong></p>
            </div>
          `
        });
        console.log('✅ Rejection email sent to:', registration.owner_email);
      } catch (error) {
        console.error('❌ Error sending rejection email:', error);
      }
    }

    res.json({
      success: true,
      message: `Đã cập nhật trạng thái thành "${status}"`,
      data: {
        id,
        status
      }
    });

  } catch (error) {
    console.error('❌ Update registration status error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi cập nhật trạng thái'
    });
  }
};

/**
 * Cập nhật thông tin đơn đăng ký
 */
exports.updateRegistration = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const registration = await HotelRegistration.getById(id);
    if (!registration) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy đơn đăng ký'
      });
    }

    // Check permission: only owner or admin can update
    const userEmail = req.user?.email;
    const isAdmin = req.user?.chuc_vu === 'Admin';
    
    if (!isAdmin && registration.owner_email !== userEmail) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không có quyền cập nhật đơn đăng ký này'
      });
    }

    await HotelRegistration.update(id, updateData);

    res.json({
      success: true,
      message: 'Cập nhật thành công'
    });

  } catch (error) {
    console.error('❌ Update registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi cập nhật đơn đăng ký'
    });
  }
};

/**
 * Xóa đơn đăng ký (Admin)
 */
exports.deleteRegistration = async (req, res) => {
  try {
    const { id } = req.params;

    const registration = await HotelRegistration.getById(id);
    if (!registration) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy đơn đăng ký'
      });
    }

    await HotelRegistration.delete(id);

    res.json({
      success: true,
      message: 'Xóa đơn đăng ký thành công'
    });

  } catch (error) {
    console.error('❌ Delete registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi xóa đơn đăng ký'
    });
  }
};

/**
 * Tạo đơn đăng ký với upload ảnh (multipart/form-data)
 * Endpoint này nhận cả data và files
 */
exports.createRegistrationWithImages = async (req, res) => {
  try {
    console.log('📸 Creating registration with images...');
    console.log('📦 Files received:', req.files ? Object.keys(req.files) : 'none');
    console.log('📝 Body data:', req.body);

    // Parse JSON data from body
    const registrationData = JSON.parse(req.body.registration_data || '{}');
    
    // Validate required fields
    const {
      owner_name,
      owner_email,
      owner_phone,
      hotel_name,
      hotel_type,
      address,
      province_id
    } = registrationData;

    if (!owner_name || !owner_email || !owner_phone || !hotel_name || !hotel_type || !address || !province_id) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng điền đầy đủ thông tin bắt buộc'
      });
    }

    // Process uploaded images
    const hotelImages = req.files['hotel_images'] || [];
    const roomImages = req.files['room_images'] || [];

    // Save image paths (relative to uploads folder)
    const hotelImagePaths = hotelImages.map(file => `/uploads/hotel_registration/${file.filename}`);
    const roomImagePaths = roomImages.map(file => `/uploads/hotel_registration/${file.filename}`);

    console.log(`✅ Hotel images: ${hotelImagePaths.length}`);
    console.log(`✅ Room images: ${roomImagePaths.length}`);

    // Create registration with image paths
    const fullRegistrationData = {
      ...registrationData,
      hotel_images: JSON.stringify(hotelImagePaths),
      room_images: JSON.stringify(roomImagePaths),
    };

    const registrationId = await HotelRegistration.create(fullRegistrationData);

    console.log('✅ Hotel registration created with images:', registrationId);

    // Send confirmation email
    try {
      await EmailService.sendEmail({
        to: owner_email,
        subject: 'Xác nhận đăng ký khách sạn trên Triphotel',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #2c5aa0;">Xin chào ${owner_name}!</h2>
            <p>Cảm ơn bạn đã đăng ký cơ sở lưu trú <strong>${hotel_name}</strong> trên Triphotel.</p>
            
            <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
              <h3 style="margin-top: 0;">Thông tin đăng ký:</h3>
              <p><strong>Tên khách sạn:</strong> ${hotel_name}</p>
              <p><strong>Loại hình:</strong> ${hotel_type}</p>
              <p><strong>Địa chỉ:</strong> ${address}</p>
              <p><strong>Mã đơn:</strong> #${registrationId}</p>
              <p><strong>Số ảnh khách sạn:</strong> ${hotelImagePaths.length}</p>
              <p><strong>Số ảnh phòng:</strong> ${roomImagePaths.length}</p>
            </div>

            <p><strong>Bước tiếp theo:</strong></p>
            <ol>
              <li>Đội ngũ Triphotel sẽ xem xét đơn đăng ký của bạn trong vòng 24-48 giờ</li>
              <li>Sau khi được duyệt, bạn sẽ nhận được email hướng dẫn thiết lập tài khoản quản lý</li>
              <li>Bạn có thể bắt đầu đăng phòng và nhận đặt phòng từ khách hàng</li>
            </ol>

            <p>Nếu có bất kỳ thắc mắc nào, vui lòng liên hệ với chúng tôi qua email này.</p>
            
            <p style="margin-top: 30px;">Trân trọng,<br><strong>Đội ngũ Triphotel</strong></p>
          </div>
        `
      });
    } catch (emailError) {
      console.error('❌ Error sending confirmation email:', emailError);
    }

    res.status(201).json({
      success: true,
      message: 'Đăng ký thành công! Chúng tôi sẽ xem xét và liên hệ với bạn trong vòng 24-48 giờ.',
      data: {
        registration_id: registrationId,
        status: 'pending',
        hotel_images_count: hotelImagePaths.length,
        room_images_count: roomImagePaths.length,
      }
    });

  } catch (error) {
    console.error('❌ Create registration with images error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi tạo đơn đăng ký',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

