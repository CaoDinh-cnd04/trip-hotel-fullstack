import 'package:flutter/material.dart';
import '../../../data/models/feedback_model.dart';
import '../../../data/services/feedback_service.dart';

class FeedbackManagementScreen extends StatefulWidget {
  const FeedbackManagementScreen({super.key});

  @override
  State<FeedbackManagementScreen> createState() =>
      _FeedbackManagementScreenState();
}

class _FeedbackManagementScreenState extends State<FeedbackManagementScreen> {
  final FeedbackService _feedbackService = FeedbackService();
  final TextEditingController _searchController = TextEditingController();

  List<FeedbackModel> _feedbacks = [];
  List<FeedbackModel> _filteredFeedbacks = [];
  bool _isLoading = true;
  String? _error;
  String _selectedStatus = 'all';
  String _selectedType = 'all';
  int? _selectedPriority;

  final List<Map<String, String>> _statusOptions = [
    {'value': 'all', 'label': 'Tất cả'},
    {'value': 'pending', 'label': 'Chờ xử lý'},
    {'value': 'in_progress', 'label': 'Đang xử lý'},
    {'value': 'resolved', 'label': 'Đã giải quyết'},
    {'value': 'closed', 'label': 'Đã đóng'},
  ];

  final List<Map<String, String>> _typeOptions = [
    {'value': 'all', 'label': 'Tất cả'},
    {'value': 'complaint', 'label': 'Khiếu nại'},
    {'value': 'suggestion', 'label': 'Góp ý'},
    {'value': 'compliment', 'label': 'Khen ngợi'},
    {'value': 'question', 'label': 'Câu hỏi'},
  ];

  final List<Map<String, dynamic>> _priorityOptions = [
    {'value': null, 'label': 'Tất cả'},
    {'value': 1, 'label': 'Thấp'},
    {'value': 2, 'label': 'Trung bình'},
    {'value': 3, 'label': 'Bình thường'},
    {'value': 4, 'label': 'Cao'},
    {'value': 5, 'label': 'Rất cao'},
  ];

  @override
  void initState() {
    super.initState();
    _feedbackService.initialize();
    _loadFeedbacks();
    _searchController.addListener(_filterFeedbacks);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFeedbacks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _feedbackService.getFeedbacks(
        status: _selectedStatus == 'all' ? null : _selectedStatus,
        type: _selectedType == 'all' ? null : _selectedType,
        priority: _selectedPriority,
      );

      if (response.success && response.data != null) {
        setState(() {
          _feedbacks = response.data!;
          _filterFeedbacks();
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

  void _filterFeedbacks() {
    final searchQuery = _searchController.text.toLowerCase();
    setState(() {
      _filteredFeedbacks = _feedbacks.where((feedback) {
        return feedback.tieuDe.toLowerCase().contains(searchQuery) ||
            feedback.noiDung.toLowerCase().contains(searchQuery) ||
            (feedback.hoTen?.toLowerCase().contains(searchQuery) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý phản hồi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeedbacks,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _buildErrorWidget()
                : _filteredFeedbacks.isEmpty
                ? _buildEmptyWidget()
                : _buildFeedbacksList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Tìm kiếm phản hồi...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Filters Row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái',
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
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Loại',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _typeOptions.map((type) {
                    return DropdownMenuItem<String>(
                      value: type['value'],
                      child: Text(type['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                      _loadFeedbacks();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Mức độ ưu tiên',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _priorityOptions.map((priority) {
                    return DropdownMenuItem<int?>(
                      value: priority['value'],
                      child: Text(priority['label']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPriority = value;
                    });
                    _loadFeedbacks();
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.feedback_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Không có phản hồi nào',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text(
            'Chưa có phản hồi nào phù hợp với bộ lọc',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbacksList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredFeedbacks.length,
      itemBuilder: (context, index) {
        final feedback = _filteredFeedbacks[index];
        return _buildFeedbackCard(feedback);
      },
    );
  }

  Widget _buildFeedbackCard(FeedbackModel feedback) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showFeedbackDetail(feedback),
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
                  const SizedBox(width: 8),
                  _buildPriorityChip(feedback.uuTien ?? 3),
                  const Spacer(),
                  Text(
                    feedback.formattedNgayTao,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              if (feedback.hoTen != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Từ: ${feedback.hoTen}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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

  Widget _buildPriorityChip(int priority) {
    Color color;
    String text;

    switch (priority) {
      case 1:
        color = Colors.green;
        text = 'Thấp';
        break;
      case 2:
        color = Colors.blue;
        text = 'TB';
        break;
      case 3:
        color = Colors.orange;
        text = 'BT';
        break;
      case 4:
        color = Colors.red;
        text = 'Cao';
        break;
      case 5:
        color = Colors.purple;
        text = 'Rất cao';
        break;
      default:
        color = Colors.grey;
        text = 'BT';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showFeedbackDetail(FeedbackModel feedback) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FeedbackDetailBottomSheet(
        feedback: feedback,
        onUpdate: _loadFeedbacks,
      ),
    );
  }
}

class FeedbackDetailBottomSheet extends StatefulWidget {
  final FeedbackModel feedback;
  final VoidCallback onUpdate;

  const FeedbackDetailBottomSheet({
    super.key,
    required this.feedback,
    required this.onUpdate,
  });

  @override
  State<FeedbackDetailBottomSheet> createState() =>
      _FeedbackDetailBottomSheetState();
}

class _FeedbackDetailBottomSheetState extends State<FeedbackDetailBottomSheet> {
  final FeedbackService _feedbackService = FeedbackService();
  final _responseController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _respondToFeedback() async {
    if (_responseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập phản hồi')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _feedbackService.respondToFeedback(
        feedbackId: widget.feedback.id,
        response: _responseController.text.trim(),
        status: 'in_progress',
        priority: widget.feedback.uuTien,
      );

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phản hồi thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
          widget.onUpdate();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi phản hồi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _feedbackService.updateFeedbackStatus(
        feedbackId: widget.feedback.id,
        status: status,
      );

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật trạng thái thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
          widget.onUpdate();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Chi tiết phản hồi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Feedback details
                      _buildDetailCard(),
                      const SizedBox(height: 16),

                      // Admin response section
                      if (widget.feedback.phanHoiCuaAdmin == null)
                        _buildResponseSection(),
                      if (widget.feedback.phanHoiCuaAdmin != null)
                        _buildExistingResponseSection(),

                      const SizedBox(height: 16),

                      // Action buttons
                      _buildActionButtons(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.feedback.tieuDe,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              widget.feedback.noiDung,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatusChip(widget.feedback.trangThai),
                const SizedBox(width: 8),
                _buildTypeChip(widget.feedback.loaiPhanHoi),
                const Spacer(),
                Text(
                  widget.feedback.formattedNgayTao,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            if (widget.feedback.hoTen != null) ...[
              const SizedBox(height: 8),
              Text(
                'Từ: ${widget.feedback.hoTen}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResponseSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phản hồi của Admin',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _responseController,
              decoration: const InputDecoration(
                hintText: 'Nhập phản hồi của bạn...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _respondToFeedback,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Gửi phản hồi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingResponseSection() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Phản hồi đã gửi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.feedback.phanHoiCuaAdmin!,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            if (widget.feedback.adminName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Bởi: ${widget.feedback.adminName}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => _updateStatus('in_progress'),
            child: const Text('Đang xử lý'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => _updateStatus('resolved'),
            child: const Text('Đã giải quyết'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => _updateStatus('closed'),
            child: const Text('Đóng'),
          ),
        ),
      ],
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
}
