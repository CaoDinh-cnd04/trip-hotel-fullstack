const TinNhan = require('../models/tinnhan');
const NguoiDung = require('../models/nguoidung');
const { validationResult } = require('express-validator');

const tinnhanController = {
    // Lấy danh sách cuộc trò chuyện
    async getConversations(req, res) {
        try {
            const { page = 1, limit = 10 } = req.query;
            const tinNhan = new TinNhan();
            
            // Lấy danh sách cuộc trò chuyện (người đã nhắn tin với user)
            const conversationsQuery = `
                WITH LatestMessages AS (
                    SELECT 
                        CASE 
                            WHEN ma_nguoi_gui = @ma_nguoi_dung THEN ma_nguoi_nhan
                            ELSE ma_nguoi_gui
                        END as other_user_id,
                        MAX(ngay_gui) as latest_time,
                        ROW_NUMBER() OVER (
                            PARTITION BY CASE 
                                WHEN ma_nguoi_gui = @ma_nguoi_dung THEN ma_nguoi_nhan
                                ELSE ma_nguoi_gui
                            END 
                            ORDER BY ngay_gui DESC
                        ) as rn
                    FROM tin_nhan 
                    WHERE (ma_nguoi_gui = @ma_nguoi_dung OR ma_nguoi_nhan = @ma_nguoi_dung)
                        AND trang_thai = 1
                    GROUP BY 
                        CASE 
                            WHEN ma_nguoi_gui = @ma_nguoi_dung THEN ma_nguoi_nhan
                            ELSE ma_nguoi_gui
                        END
                )
                SELECT 
                    lm.other_user_id,
                    nd.ho_ten,
                    nd.anh_dai_dien,
                    tn.noi_dung as last_message,
                    tn.ngay_gui as last_time,
                    tn.ma_nguoi_gui as last_sender_id,
                    (SELECT COUNT(*) FROM tin_nhan 
                     WHERE ma_nguoi_gui = lm.other_user_id 
                     AND ma_nguoi_nhan = @ma_nguoi_dung 
                     AND da_doc = 0 AND trang_thai = 1) as unread_count
                FROM LatestMessages lm
                INNER JOIN nguoi_dung nd ON lm.other_user_id = nd.ma_nguoi_dung
                INNER JOIN tin_nhan tn ON (
                    (tn.ma_nguoi_gui = @ma_nguoi_dung AND tn.ma_nguoi_nhan = lm.other_user_id) OR
                    (tn.ma_nguoi_gui = lm.other_user_id AND tn.ma_nguoi_nhan = @ma_nguoi_dung)
                ) AND tn.ngay_gui = lm.latest_time
                WHERE lm.rn = 1
                ORDER BY lm.latest_time DESC
                OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
            `;

            const offset = (parseInt(page) - 1) * parseInt(limit);
            const conversations = await tinNhan.executeQuery(conversationsQuery, {
                ma_nguoi_dung: req.user.ma_nguoi_dung,
                offset,
                limit: parseInt(limit)
            });

            res.status(200).json({
                success: true,
                message: 'Lấy danh sách cuộc trò chuyện thành công',
                data: {
                    conversations,
                    pagination: {
                        page: parseInt(page),
                        limit: parseInt(limit)
                    }
                }
            });
        } catch (error) {
            console.error('Error in getConversations:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy danh sách cuộc trò chuyện',
                error: error.message
            });
        }
    },

    // Lấy tin nhắn trong cuộc trò chuyện
    async getMessages(req, res) {
        try {
            const { user_id } = req.params;
            const { page = 1, limit = 20 } = req.query;
            const tinNhan = new TinNhan();
            
            const messagesQuery = `
                SELECT tn.*, ng.ho_ten as ten_nguoi_gui, nn.ho_ten as ten_nguoi_nhan
                FROM tin_nhan tn
                INNER JOIN nguoi_dung ng ON tn.ma_nguoi_gui = ng.ma_nguoi_dung
                INNER JOIN nguoi_dung nn ON tn.ma_nguoi_nhan = nn.ma_nguoi_dung
                WHERE ((tn.ma_nguoi_gui = @current_user AND tn.ma_nguoi_nhan = @other_user) OR 
                       (tn.ma_nguoi_gui = @other_user AND tn.ma_nguoi_nhan = @current_user))
                    AND tn.trang_thai = 1
                ORDER BY tn.ngay_gui DESC
                OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
            `;

            const offset = (parseInt(page) - 1) * parseInt(limit);
            const messages = await tinNhan.executeQuery(messagesQuery, {
                current_user: req.user.ma_nguoi_dung,
                other_user: user_id,
                offset,
                limit: parseInt(limit)
            });

            // Đánh dấu đã đọc các tin nhắn từ người kia
            await tinNhan.executeQuery(`
                UPDATE tin_nhan 
                SET da_doc = 1 
                WHERE ma_nguoi_gui = @other_user 
                    AND ma_nguoi_nhan = @current_user 
                    AND da_doc = 0
            `, {
                current_user: req.user.ma_nguoi_dung,
                other_user: user_id
            });

            res.status(200).json({
                success: true,
                message: 'Lấy tin nhắn thành công',
                data: {
                    messages: messages.reverse(), // Sắp xếp lại theo thời gian tăng dần
                    pagination: {
                        page: parseInt(page),
                        limit: parseInt(limit)
                    }
                }
            });
        } catch (error) {
            console.error('Error in getMessages:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy tin nhắn',
                error: error.message
            });
        }
    },

    // Gửi tin nhắn
    async sendMessage(req, res) {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    message: 'Dữ liệu không hợp lệ',
                    errors: errors.array()
                });
            }

            const { ma_nguoi_nhan, noi_dung, loai_tin_nhan = 'text' } = req.body;
            const tinNhan = new TinNhan();
            
            // Kiểm tra người nhận tồn tại
            const nguoiDung = new NguoiDung();
            const recipient = await nguoiDung.findById(ma_nguoi_nhan);
            if (!recipient) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy người nhận'
                });
            }

            const newMessage = await tinNhan.create({
                ma_nguoi_gui: req.user.ma_nguoi_dung,
                ma_nguoi_nhan,
                noi_dung,
                loai_tin_nhan,
                ngay_gui: new Date(),
                da_doc: 0,
                trang_thai: 1
            });

            // Lấy thông tin tin nhắn vừa tạo với thông tin người gửi
            const messageWithDetails = await tinNhan.executeQuery(`
                SELECT tn.*, ng.ho_ten as ten_nguoi_gui, nn.ho_ten as ten_nguoi_nhan
                FROM tin_nhan tn
                INNER JOIN nguoi_dung ng ON tn.ma_nguoi_gui = ng.ma_nguoi_dung
                INNER JOIN nguoi_dung nn ON tn.ma_nguoi_nhan = nn.ma_nguoi_dung
                WHERE tn.ma_tin_nhan = @ma_tin_nhan
            `, { ma_tin_nhan: newMessage.ma_tin_nhan });

            res.status(201).json({
                success: true,
                message: 'Gửi tin nhắn thành công',
                data: messageWithDetails[0]
            });
        } catch (error) {
            console.error('Error in sendMessage:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi gửi tin nhắn',
                error: error.message
            });
        }
    },

    // Đánh dấu đã đọc tin nhắn
    async markAsRead(req, res) {
        try {
            const { message_id } = req.params;
            const tinNhan = new TinNhan();
            
            const message = await tinNhan.findById(message_id);
            if (!message) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy tin nhắn'
                });
            }

            // Chỉ người nhận mới có thể đánh dấu đã đọc
            if (message.ma_nguoi_nhan !== req.user.ma_nguoi_dung) {
                return res.status(403).json({
                    success: false,
                    message: 'Bạn không có quyền đánh dấu tin nhắn này'
                });
            }

            await tinNhan.update(message_id, { da_doc: 1 });

            res.status(200).json({
                success: true,
                message: 'Đánh dấu đã đọc thành công'
            });
        } catch (error) {
            console.error('Error in markAsRead:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi đánh dấu đã đọc',
                error: error.message
            });
        }
    },

    // Đánh dấu đã đọc tất cả tin nhắn từ một người
    async markAllAsRead(req, res) {
        try {
            const { user_id } = req.params;
            const tinNhan = new TinNhan();
            
            await tinNhan.executeQuery(`
                UPDATE tin_nhan 
                SET da_doc = 1 
                WHERE ma_nguoi_gui = @sender_id 
                    AND ma_nguoi_nhan = @receiver_id 
                    AND da_doc = 0
            `, {
                sender_id: user_id,
                receiver_id: req.user.ma_nguoi_dung
            });

            res.status(200).json({
                success: true,
                message: 'Đánh dấu đã đọc tất cả tin nhắn thành công'
            });
        } catch (error) {
            console.error('Error in markAllAsRead:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi đánh dấu đã đọc',
                error: error.message
            });
        }
    },

    // Xóa tin nhắn
    async deleteMessage(req, res) {
        try {
            const { message_id } = req.params;
            const tinNhan = new TinNhan();
            
            const message = await tinNhan.findById(message_id);
            if (!message) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy tin nhắn'
                });
            }

            // Chỉ người gửi hoặc Admin mới có thể xóa
            if (req.user.vai_tro !== 'Admin' && message.ma_nguoi_gui !== req.user.ma_nguoi_dung) {
                return res.status(403).json({
                    success: false,
                    message: 'Bạn không có quyền xóa tin nhắn này'
                });
            }

            await tinNhan.update(message_id, { trang_thai: 0 });

            res.status(200).json({
                success: true,
                message: 'Xóa tin nhắn thành công'
            });
        } catch (error) {
            console.error('Error in deleteMessage:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi xóa tin nhắn',
                error: error.message
            });
        }
    },

    // Lấy số tin nhắn chưa đọc
    async getUnreadCount(req, res) {
        try {
            const tinNhan = new TinNhan();
            
            const result = await tinNhan.executeQuery(`
                SELECT COUNT(*) as unread_count
                FROM tin_nhan 
                WHERE ma_nguoi_nhan = @ma_nguoi_dung 
                    AND da_doc = 0 
                    AND trang_thai = 1
            `, { ma_nguoi_dung: req.user.ma_nguoi_dung });

            res.status(200).json({
                success: true,
                message: 'Lấy số tin nhắn chưa đọc thành công',
                data: {
                    unread_count: result[0]?.unread_count || 0
                }
            });
        } catch (error) {
            console.error('Error in getUnreadCount:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi lấy số tin nhắn chưa đọc',
                error: error.message
            });
        }
    },

    // Tìm kiếm tin nhắn
    async searchMessages(req, res) {
        try {
            const { keyword, user_id, page = 1, limit = 10 } = req.query;
            
            if (!keyword) {
                return res.status(400).json({
                    success: false,
                    message: 'Vui lòng nhập từ khóa tìm kiếm'
                });
            }

            const tinNhan = new TinNhan();
            let searchQuery = `
                SELECT tn.*, ng.ho_ten as ten_nguoi_gui, nn.ho_ten as ten_nguoi_nhan
                FROM tin_nhan tn
                INNER JOIN nguoi_dung ng ON tn.ma_nguoi_gui = ng.ma_nguoi_dung
                INNER JOIN nguoi_dung nn ON tn.ma_nguoi_nhan = nn.ma_nguoi_dung
                WHERE (tn.ma_nguoi_gui = @ma_nguoi_dung OR tn.ma_nguoi_nhan = @ma_nguoi_dung)
                    AND tn.noi_dung LIKE @keyword
                    AND tn.trang_thai = 1
            `;

            const params = {
                ma_nguoi_dung: req.user.ma_nguoi_dung,
                keyword: `%${keyword}%`
            };

            if (user_id) {
                searchQuery += ` AND ((tn.ma_nguoi_gui = @user_id AND tn.ma_nguoi_nhan = @ma_nguoi_dung) OR 
                                     (tn.ma_nguoi_gui = @ma_nguoi_dung AND tn.ma_nguoi_nhan = @user_id))`;
                params.user_id = user_id;
            }

            searchQuery += ` ORDER BY tn.ngay_gui DESC OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY`;
            
            const offset = (parseInt(page) - 1) * parseInt(limit);
            params.offset = offset;
            params.limit = parseInt(limit);

            const messages = await tinNhan.executeQuery(searchQuery, params);

            res.status(200).json({
                success: true,
                message: 'Tìm kiếm tin nhắn thành công',
                data: {
                    messages,
                    pagination: {
                        page: parseInt(page),
                        limit: parseInt(limit)
                    }
                }
            });
        } catch (error) {
            console.error('Error in searchMessages:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server khi tìm kiếm tin nhắn',
                error: error.message
            });
        }
    }
};

module.exports = tinnhanController;