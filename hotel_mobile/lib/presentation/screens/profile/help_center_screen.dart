import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/services/feedback_service.dart';
import '../../../data/models/feedback_model.dart';

/// Màn hình Trung tâm Trợ giúp
/// 
/// Cung cấp 2 tab chính:
/// 1. FAQ (Frequently Asked Questions) - Câu hỏi thường gặp
///    - 5 câu hỏi mặc định về đặt phòng, thanh toán, hủy phòng, v.v.
///    - Hiển thị dạng ExpansionTile để người dùng xem chi tiết
/// 
/// 2. Gửi phản hồi - Form để người dùng gửi feedback cho admin
///    - Chọn danh mục (Chung, Đặt phòng, Thanh toán, Kỹ thuật, Khác)
///    - Nhập tiêu đề và nội dung
///    - Gửi qua API để admin có thể xem và trả lời
class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({Key? key}) : super(key: key);

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> with SingleTickerProviderStateMixin {
  /// Controller để quản lý 2 tabs (FAQ và Feedback)
  late TabController _tabController;
  
  /// Service để gửi feedback lên backend
  final FeedbackService _feedbackService = FeedbackService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Xây dựng giao diện màn hình Trung tâm Trợ giúp
  /// 
  /// Hiển thị TabBar với 2 tabs:
  /// - Tab FAQ: Danh sách câu hỏi thường gặp
  /// - Tab Feedback: Form gửi phản hồi
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(l10n.helpCenterTitle),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.question_answer),
              text: l10n.faq,
            ),
            Tab(
              icon: const Icon(Icons.feedback),
              text: l10n.sendFeedback,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFAQTab(l10n),
          _buildFeedbackTab(l10n),
        ],
      ),
    );
  }

  /// Tạo tab hiển thị FAQ (Câu hỏi thường gặp)
  /// 
  /// Danh sách gồm 5 câu hỏi mặc định:
  /// 1. Làm thế nào để đặt phòng?
  /// 2. Tôi có thể hủy đặt phòng không?
  /// 3. Những phương thức thanh toán nào được chấp nhận?
  /// 4. Làm thế nào để thay đổi thông tin đặt phòng?
  /// 5. Chính sách hoàn tiền như thế nào?
  /// 
  /// Parameters:
  /// - [l10n]: Đối tượng localization để lấy text đa ngôn ngữ
  Widget _buildFAQTab(AppLocalizations l10n) {
    final faqItems = [
      {
        'question': l10n.faqHowToBook,
        'answer': l10n.faqHowToBookAnswer,
        'icon': Icons.hotel,
        'color': Colors.blue,
      },
      {
        'question': l10n.faqCancelBooking,
        'answer': l10n.faqCancelBookingAnswer,
        'icon': Icons.cancel,
        'color': Colors.orange,
      },
      {
        'question': l10n.faqPaymentMethod,
        'answer': l10n.faqPaymentMethodAnswer,
        'icon': Icons.payment,
        'color': Colors.green,
      },
      {
        'question': l10n.faqChangeBooking,
        'answer': l10n.faqChangeBookingAnswer,
        'icon': Icons.edit,
        'color': Colors.purple,
      },
      {
        'question': l10n.faqRefund,
        'answer': l10n.faqRefundAnswer,
        'icon': Icons.money,
        'color': Colors.teal,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: faqItems.length,
      itemBuilder: (context, index) {
        final item = faqItems[index];
        return _buildFAQItem(
          question: item['question'] as String,
          answer: item['answer'] as String,
          icon: item['icon'] as IconData,
          color: item['color'] as Color,
        );
      },
    );
  }

  /// Tạo một item FAQ dạng ExpansionTile
  /// 
  /// Người dùng có thể click để xem câu trả lời chi tiết
  /// 
  /// Parameters:
  /// - [question]: Câu hỏi
  /// - [answer]: Câu trả lời chi tiết
  /// - [icon]: Icon đại diện cho câu hỏi
  /// - [color]: Màu của icon
  Widget _buildFAQItem({
    required String question,
    required String answer,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  answer,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tạo tab gửi phản hồi
  /// 
  /// Hiển thị form để người dùng:
  /// - Chọn danh mục feedback
  /// - Nhập tiêu đề
  /// - Nhập nội dung chi tiết
  /// - Gửi phản hồi cho admin
  /// 
  /// Parameters:
  /// - [l10n]: Đối tượng localization để lấy text đa ngôn ngữ
  Widget _buildFeedbackTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _FeedbackForm(
        feedbackService: _feedbackService,
        l10n: l10n,
      ),
    );
  }
}

/// Widget Form gửi phản hồi
/// 
/// Cho phép người dùng gửi feedback/phản hồi cho admin
/// Bao gồm các trường:
/// - Category (danh mục): Chung, Đặt phòng, Thanh toán, Kỹ thuật, Khác
/// - Title (tiêu đề): Tóm tắt vấn đề
/// - Message (nội dung): Chi tiết phản hồi
class _FeedbackForm extends StatefulWidget {
  /// Service để gửi feedback lên backend
  final FeedbackService feedbackService;
  
  /// Đối tượng localization
  final AppLocalizations l10n;

  const _FeedbackForm({
    required this.feedbackService,
    required this.l10n,
  });

  @override
  State<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<_FeedbackForm> {
  /// Key để validate form
  final _formKey = GlobalKey<FormState>();
  
  /// Controller cho trường tiêu đề
  final _titleController = TextEditingController();
  
  /// Controller cho trường nội dung
  final _messageController = TextEditingController();
  
  /// Danh mục được chọn (mặc định: general)
  String _selectedCategory = 'general';
  
  /// Trạng thái đang gửi feedback
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// Xử lý gửi feedback lên server
  /// 
  /// Quy trình:
  /// 1. Validate form (kiểm tra tiêu đề và nội dung không được rỗng)
  /// 2. Tạo FeedbackModel với thông tin đã nhập
  /// 3. Gửi lên backend qua FeedbackService
  /// 4. Hiển thị thông báo thành công hoặc lỗi
  /// 5. Clear form nếu thành công
  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final feedback = FeedbackModel(
        id: 0, // Will be set by backend
        nguoiDungId: 0, // Will be set by backend
        tieuDe: _titleController.text.trim(),
        noiDung: _messageController.text.trim(),
        loaiPhanHoi: _selectedCategory,
        trangThai: 'pending',
        uuTien: 2, // Normal priority
        ngayTao: DateTime.now(),
      );

      print('📤 Sending feedback:');
      print('   - Tiêu đề: "${feedback.tieuDe}"');
      print('   - Nội dung: "${feedback.noiDung}"');
      print('   - Loại: ${feedback.loaiPhanHoi}');
      print('   - JSON: ${feedback.toJson()}');

      final response = await widget.feedbackService.createFeedback(feedback);
      
      print('📥 Response:');
      print('   - Success: ${response.success}');
      print('   - Message: ${response.message}');

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.l10n.feedbackSent),
              backgroundColor: Colors.green,
            ),
          );
          _titleController.clear();
          _messageController.clear();
          setState(() => _selectedCategory = 'general');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? widget.l10n.feedbackError),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.l10n.feedbackError}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Xây dựng giao diện form feedback
  /// 
  /// Bao gồm:
  /// - Header với icon và mô tả
  /// - Category selector (ChoiceChip)
  /// - Title input field
  /// - Message input field (multiline)
  /// - Submit button
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.support_agent,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.l10n.sendFeedback,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gửi phản hồi của bạn cho chúng tôi',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Category Selector
          Text(
            widget.l10n.feedbackCategory,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildCategorySelector(),

          const SizedBox(height: 24),

          // Title Field
          Text(
            widget.l10n.feedbackTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: widget.l10n.pleaseEnterTitle,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.title),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return widget.l10n.pleaseEnterTitle;
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Message Field
          Text(
            widget.l10n.feedbackMessage,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _messageController,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: widget.l10n.pleaseEnterMessage,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
              alignLabelWithHint: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return widget.l10n.pleaseEnterMessage;
              }
              return null;
            },
          ),

          const SizedBox(height: 32),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send),
                        const SizedBox(width: 8),
                        Text(
                          widget.l10n.send,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tạo selector để chọn danh mục feedback
  /// 
  /// Hiển thị 5 danh mục dạng ChoiceChip:
  /// - Chung (general)
  /// - Đặt phòng (booking)
  /// - Thanh toán (payment)
  /// - Kỹ thuật (technical)
  /// - Khác (other)
  Widget _buildCategorySelector() {
    final categories = [
      {'value': 'general', 'label': widget.l10n.feedbackGeneral, 'icon': Icons.chat},
      {'value': 'booking', 'label': widget.l10n.feedbackBooking, 'icon': Icons.book},
      {'value': 'payment', 'label': widget.l10n.feedbackPayment, 'icon': Icons.payment},
      {'value': 'technical', 'label': widget.l10n.feedbackTechnical, 'icon': Icons.bug_report},
      {'value': 'other', 'label': widget.l10n.feedbackOther, 'icon': Icons.more_horiz},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        final isSelected = _selectedCategory == category['value'];
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                category['icon'] as IconData,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
              const SizedBox(width: 4),
              Text(category['label'] as String),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedCategory = category['value'] as String;
              });
            }
          },
          selectedColor: Theme.of(context).primaryColor,
          backgroundColor: Colors.grey[200],
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}

