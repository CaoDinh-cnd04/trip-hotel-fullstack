const HotelRegistration = require('../models/hotelRegistration');
const NguoiDung = require('../models/nguoidung');
const EmailService = require('../services/emailService');
const path = require('path');

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
        let user = await NguoiDung.findByEmail(registration.owner_email);
        
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
          
          user = await NguoiDung.create(userData);
          console.log('✅ Created hotel manager account:', user.id);
        } else {
          // Update existing user to HotelManager role
          await NguoiDung.updateRole(user.id, 'HotelManager'); // ✅ FIX: Dùng 'HotelManager'
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
            .input('gioNhanPhong', sql.Time, registration.check_in_time || '14:00:00')
            .input('gioTraPhong', sql.Time, registration.check_out_time || '12:00:00')
            .input('yeuCauCoc', sql.Bit, registration.require_deposit !== undefined ? registration.require_deposit : 1)
            .input('tiLeCoc', sql.Decimal(5, 2), registration.deposit_rate || 30)
            .input('chinhSachHuy', sql.NVarChar, registration.cancellation_policy || 'Hủy miễn phí trước 24h. Sau đó mất phí 50% giá trị đặt phòng.')
            .input('tongSoPhong', sql.Int, registration.total_rooms || 10)
            .input('trangThai', sql.Int, 1)
            .query(`
              INSERT INTO dbo.khach_san (
                ten, mo_ta, dia_chi, vi_tri_id, so_sao, 
                chu_khach_san_id, email_lien_he, sdt_lien_he, website,
                gio_nhan_phong, gio_tra_phong, yeu_cau_coc, ti_le_coc,
                chinh_sach_huy, tong_so_phong, trang_thai
              )
              OUTPUT INSERTED.id
              VALUES (
                @ten, @moTa, @diaChi, @viTriId, @soSao,
                @chuKhachSanId, @emailLienHe, @sdtLienHe, @website,
                @gioNhanPhong, @gioTraPhong, @yeuCauCoc, @tiLeCoc,
                @chinhSachHuy, @tongSoPhong, @trangThai
              )
            `);

          const hotelId = hotelResult.recordset[0].id;
          console.log('✅ Created hotel in database:', hotelId);

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
        await EmailService.sendEmail({
          to: registration.owner_email,
          subject: '🎉 Đơn đăng ký khách sạn của bạn đã được duyệt!',
          html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2 style="color: #28a745;">Chúc mừng ${registration.owner_name}!</h2>
              <p>Đơn đăng ký khách sạn <strong>${registration.hotel_name}</strong> của bạn đã được duyệt.</p>
              
              <div style="background-color: #d4edda; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #28a745;">
                <h3 style="margin-top: 0; color: #155724;">Bước tiếp theo:</h3>
                <ol style="margin: 10px 0; padding-left: 20px;">
                  <li>Đăng nhập vào Triphotel bằng email: <strong>${registration.owner_email}</strong></li>
                  <li>Thiết lập mật khẩu mới (nếu chưa có tài khoản)</li>
                  <li>Hoàn thiện hồ sơ khách sạn: thêm ảnh, mô tả chi tiết, tiện nghi</li>
                  <li>Đăng các loại phòng và giá</li>
                  <li>Bắt đầu nhận đặt phòng từ khách hàng!</li>
                </ol>
              </div>

              <div style="text-align: center; margin: 30px 0;">
                <a href="${process.env.APP_URL || 'http://localhost:3000'}/login" 
                   style="background-color: #2c5aa0; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">
                  Đăng nhập ngay
                </a>
              </div>

              ${admin_note ? `<p><strong>Ghi chú từ admin:</strong> ${admin_note}</p>` : ''}

              <p>Chúc bạn thành công với khách sạn của mình!</p>
              <p style="margin-top: 30px;">Trân trọng,<br><strong>Đội ngũ Triphotel</strong></p>
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
          subject: 'Thông báo về đơn đăng ký khách sạn',
          html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2 style="color: #dc3545;">Thông báo về đơn đăng ký</h2>
              <p>Xin chào ${registration.owner_name},</p>
              <p>Chúng tôi rất tiếc phải thông báo rằng đơn đăng ký khách sạn <strong>${registration.hotel_name}</strong> của bạn chưa được chấp nhận.</p>
              
              ${admin_note ? `
                <div style="background-color: #f8d7da; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #dc3545;">
                  <p style="margin: 0;"><strong>Lý do:</strong> ${admin_note}</p>
                </div>
              ` : ''}

              <p>Bạn có thể chỉnh sửa thông tin và gửi lại đơn đăng ký. Nếu cần hỗ trợ, vui lòng liên hệ với chúng tôi.</p>
              
              <p style="margin-top: 30px;">Trân trọng,<br><strong>Đội ngũ Triphotel</strong></p>
            </div>
          `
        });
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

