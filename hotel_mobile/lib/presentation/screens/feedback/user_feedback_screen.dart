import 'package:flutter/material.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../data/models/feedback_model.dart';
import '../../../data/services/feedback_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_feedback_screen.dart';
import 'feedback_detail_screen.dart';

class UserFeedbackScreen extends StatefulWidget {
  const UserFeedbackScreen({super.key});

  @override
  State<UserFeedbackScreen> createState() => _UserFeedbackScreenState();
}

class _UserFeedbackScreenState extends State<UserFeedbackScreen> {
  final FeedbackService _feedbackService = FeedbackService();

  List<FeedbackModel> _feedbacks = [];
  bool _isLoading = true;
  String? _error;
  String _selectedStatus = 'all';

  final List<Map<String, String>> _statusOptions = [
    {'value': 'all', 'label': 'Tất cả'},
    {'value': 'pending', 'label': 'Chờ xử lý'},
    {'value': 'in_progress', 'label': 'Đang xử lý'},
    {'value': 'resolved', 'label': 'Đã giải quyết'},
    {'value': 'closed', 'label': 'Đã đóng'},
  ];

  @override
  void initState() {
    super.initState();
    _feedbackService.initialize();
    _loadFeedbacks();
  }

  Future<void> _loadFeedbacks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _error = 'Vui lòng đăng nhập để xem phản hồi';
          _isLoading = false;
        });
        return;
      }

      final response = await _feedbackService.getUserFeedbacks(
        userId: int.parse(currentUser.uid), // Assuming UID is numeric
        status: _selectedStatus == 'all' ? null : _selectedStatus,
      );

      if (response.success && response.data != null) {
        setState(() {
          _feedbacks = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phản hồi của tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCreateFeedback(),
            tooltip: 'Tạo phản hồi mới',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeedbacks,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _buildErrorWidget()
                : _feedbacks.isEmpty
                ? _buildEmptyWidget()
                : _buildFeedbacksList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateFeedback(),
        child: const Icon(Icons.add),
        tooltip: 'Tạo phản hồi mới',
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Lọc theo trạng thái',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: _statusOptions.map((status) {
                return DropdownMenuItem<String>(
                  value: status['value'],
                  child: Text(status['label']!),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedStatus = value;
                  });
                  _loadFeedbacks();
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _loadFeedbacks,
            icon: const Icon(Icons.filter_list),
            label: const Text('Lọc'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Có lỗi xảy ra',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFeedbacks,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return EmptyFeedbackWidget(
      onCreateFeedback: () => _navigateToCreateFeedback(),
    );
  }

  Widget _buildFeedbacksList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _feedbacks.length,
      itemBuilder: (context, index) {
        final feedback = _feedbacks[index];
        return _buildFeedbackCard(feedback);
      },
    );
  }

  Widget _buildFeedbackCard(FeedbackModel feedback) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToFeedbackDetail(feedback),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      feedback.tieuDe,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildStatusChip(feedback.trangThai),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                feedback.noiDung,
                style: const TextStyle(color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildTypeChip(feedback.loaiPhanHoi),
                  const Spacer(),
                  Text(
                    feedback.formattedNgayTao,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              if (feedback.phanHoiCuaAdmin != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.admin_panel_settings,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Admin đã phản hồi',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = 'Chờ xử lý';
        break;
      case 'in_progress':
        color = Colors.blue;
        text = 'Đang xử lý';
        break;
      case 'resolved':
        color = Colors.green;
        text = 'Đã giải quyết';
        break;
      case 'closed':
        color = Colors.grey;
        text = 'Đã đóng';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    Color color;
    String text;

    switch (type) {
      case 'complaint':
        color = Colors.red;
        text = 'Khiếu nại';
        break;
      case 'suggestion':
        color = Colors.blue;
        text = 'Góp ý';
        break;
      case 'compliment':
        color = Colors.green;
        text = 'Khen ngợi';
        break;
      case 'question':
        color = Colors.purple;
        text = 'Câu hỏi';
        break;
      default:
        color = Colors.grey;
        text = type;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _navigateToCreateFeedback() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateFeedbackScreen()),
    );

    if (result == true) {
      _loadFeedbacks();
    }
  }

  void _navigateToFeedbackDetail(FeedbackModel feedback) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeedbackDetailScreen(feedback: feedback),
      ),
    );
  }
}
