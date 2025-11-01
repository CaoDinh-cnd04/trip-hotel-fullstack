import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hotel_mobile/data/services/admin_service.dart';
import 'package:intl/intl.dart';

class SystemReportsScreen extends StatefulWidget {
  const SystemReportsScreen({super.key});

  @override
  State<SystemReportsScreen> createState() => _SystemReportsScreenState();
}

class _SystemReportsScreenState extends State<SystemReportsScreen> {
  final AdminService _adminService = AdminService();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  String? _error;
  String _selectedPeriod = '7days';

  final List<Map<String, String>> _periodOptions = [
    {'value': '7days', 'label': '7 ngày qua'},
    {'value': '30days', 'label': '30 ngày qua'},
    {'value': '90days', 'label': '90 ngày qua'},
    {'value': 'year', 'label': 'Năm nay'},
  ];

  @override
  void initState() {
    super.initState();
    _adminService.initialize();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      DateTime fromDate;
      DateTime toDate = DateTime.now();

      switch (_selectedPeriod) {
        case '7days':
          fromDate = toDate.subtract(const Duration(days: 7));
          break;
        case '30days':
          fromDate = toDate.subtract(const Duration(days: 30));
          break;
        case '90days':
          fromDate = toDate.subtract(const Duration(days: 90));
          break;
        case 'year':
          fromDate = DateTime(toDate.year, 1, 1);
          break;
        default:
          fromDate = toDate.subtract(const Duration(days: 30));
      }

      final stats = await _adminService.getSystemStatistics(
        fromDate: fromDate,
        toDate: toDate,
      );

      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể kết nối đến server. Vui lòng thử lại sau.';
        // Use mock data for demo
        _statistics = _getMockStatistics();
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _getMockStatistics() {
    return {
      'total_bookings': 1234,
      'total_revenue': 150000000,
      'total_hotels': 45,
      'total_users': 890,
      'average_rating': 4.5,
      'booking_trend': [
        {'date': '2024-10-15', 'count': 45},
        {'date': '2024-10-16', 'count': 52},
        {'date': '2024-10-17', 'count': 48},
        {'date': '2024-10-18', 'count': 61},
        {'date': '2024-10-19', 'count': 55},
        {'date': '2024-10-20', 'count': 58},
        {'date': '2024-10-21', 'count': 63},
      ],
      'revenue_trend': [
        {'date': '2024-10-15', 'amount': 18500000},
        {'date': '2024-10-16', 'amount': 21300000},
        {'date': '2024-10-17', 'amount': 19800000},
        {'date': '2024-10-18', 'amount': 24500000},
        {'date': '2024-10-19', 'amount': 22100000},
        {'date': '2024-10-20', 'amount': 23200000},
        {'date': '2024-10-21', 'amount': 25600000},
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Báo cáo Hệ thống',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.purple[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildStatistics(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text(
            'Khoảng thời gian:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedPeriod,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: _periodOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option['value'],
                  child: Text(option['label']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value!;
                });
                _loadStatistics();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    if (_statistics == null) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            _buildSummaryCards(),
            const SizedBox(height: 24),
            
            // Booking trend chart
            _buildChart(
              title: 'Xu hướng Đặt phòng',
              data: _statistics!['booking_trend'] ?? [],
              color: Colors.blue,
              valueKey: 'count',
            ),
            const SizedBox(height: 24),
            
            // Revenue trend chart
            _buildChart(
              title: 'Xu hướng Doanh thu',
              data: _statistics!['revenue_trend'] ?? [],
              color: Colors.green,
              valueKey: 'amount',
              isRevenue: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildSummaryCard(
          'Đặt phòng',
          _statistics!['total_bookings']?.toString() ?? '0',
          Icons.book_online,
          Colors.blue,
        ),
        _buildSummaryCard(
          'Doanh thu',
          currencyFormat.format(_statistics!['total_revenue'] ?? 0),
          Icons.attach_money,
          Colors.green,
        ),
        _buildSummaryCard(
          'Khách sạn',
          _statistics!['total_hotels']?.toString() ?? '0',
          Icons.hotel,
          Colors.purple,
        ),
        _buildSummaryCard(
          'Người dùng',
          _statistics!['total_users']?.toString() ?? '0',
          Icons.people,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart({
    required String title,
    required List<dynamic> data,
    required Color color,
    required String valueKey,
    bool isRevenue = false,
  }) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: isRevenue ? 5000000 : 10,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200],
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isRevenue ? 60 : 40,
                      getTitlesWidget: (value, meta) {
                        if (isRevenue) {
                          return Text(
                            '${(value / 1000000).toStringAsFixed(0)}M',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          );
                        }
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          final date = DateTime.parse(data[index]['date']);
                          return Text(
                            DateFormat('dd/MM').format(date),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((entry) {
                      final value = entry.value[valueKey] ?? 0;
                      return FlSpot(
                        entry.key.toDouble(),
                        (value is int ? value.toDouble() : value as double),
                      );
                    }).toList(),
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.1),
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
}

