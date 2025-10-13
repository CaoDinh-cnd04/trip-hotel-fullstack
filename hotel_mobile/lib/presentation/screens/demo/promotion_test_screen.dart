import 'package:flutter/material.dart';
import '../../../data/models/discount_voucher.dart';
import '../../../data/models/promotion.dart';
import '../../../data/services/promotion_service.dart';

class PromotionTestScreen extends StatefulWidget {
  const PromotionTestScreen({Key? key}) : super(key: key);

  @override
  State<PromotionTestScreen> createState() => _PromotionTestScreenState();
}

class _PromotionTestScreenState extends State<PromotionTestScreen> {
  final PromotionService _promotionService = PromotionService();
  final TextEditingController _voucherCodeController = TextEditingController();
  final TextEditingController _orderAmountController = TextEditingController(
    text: '1000000',
  );

  List<Promotion> _activePromotions = [];
  List<DiscountVoucher> _activeVouchers = [];
  List<DiscountVoucher> _myVouchers = [];

  bool _isLoading = false;
  String _testResults = '';

  @override
  void initState() {
    super.initState();
    _runAllTests();
  }

  @override
  void dispose() {
    _voucherCodeController.dispose();
    _orderAmountController.dispose();
    super.dispose();
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Bắt đầu test API...\n\n';
    });

    // Test 1: Get active promotions
    await _testGetActivePromotions();

    // Test 2: Get active vouchers
    await _testGetActiveVouchers();

    // Test 3: Get my vouchers
    await _testGetMyVouchers();

    setState(() => _isLoading = false);
  }

  Future<void> _testGetActivePromotions() async {
    try {
      setState(() => _testResults += '🔄 Testing: Get Active Promotions\n');

      final promotions = await _promotionService.getActivePromotions();

      setState(() {
        _activePromotions = promotions;
        _testResults += '✅ Success: Tìm thấy ${promotions.length} khuyến mãi\n';
        if (promotions.isNotEmpty) {
          _testResults +=
              '   - ${promotions.first.ten}: ${promotions.first.phanTramGiam}%\n';
        }
        _testResults += '\n';
      });
    } catch (e) {
      setState(() {
        _testResults += '❌ Error: $e\n\n';
      });
    }
  }

  Future<void> _testGetActiveVouchers() async {
    try {
      setState(() => _testResults += '🔄 Testing: Get Active Vouchers\n');

      final vouchers = await _promotionService.getActiveDiscountVouchers();

      setState(() {
        _activeVouchers = vouchers;
        _testResults += '✅ Success: Tìm thấy ${vouchers.length} mã giảm giá\n';
        if (vouchers.isNotEmpty) {
          _testResults +=
              '   - ${vouchers.first.tenMaGiamGia}: ${vouchers.first.maGiamGia}\n';
        }
        _testResults += '\n';
      });
    } catch (e) {
      setState(() {
        _testResults += '❌ Error: $e\n\n';
      });
    }
  }

  Future<void> _testGetMyVouchers() async {
    try {
      setState(() => _testResults += '🔄 Testing: Get My Vouchers\n');

      final vouchers = await _promotionService.getMyDiscountVouchers();

      setState(() {
        _myVouchers = vouchers;
        _testResults += '✅ Success: Tìm thấy ${vouchers.length} mã của tôi\n';
        if (vouchers.isNotEmpty) {
          _testResults +=
              '   - ${vouchers.first.tenMaGiamGia}: ${vouchers.first.maGiamGia}\n';
        }
        _testResults += '\n';
      });
    } catch (e) {
      setState(() {
        _testResults += '❌ Error: $e\n\n';
      });
    }
  }

  Future<void> _testValidateVoucher() async {
    final voucherCode = _voucherCodeController.text.trim();
    final orderAmount = double.tryParse(_orderAmountController.text) ?? 1000000;

    if (voucherCode.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập mã voucher')));
      return;
    }

    setState(() {
      _isLoading = true;
      _testResults +=
          '🔄 Testing: Validate Voucher "$voucherCode" với ${orderAmount.toStringAsFixed(0)}đ\n';
    });

    try {
      final result = await _promotionService.validateDiscountVoucher(
        voucherCode,
        orderAmount,
      );

      setState(() {
        if (result['success'] && result['isValid']) {
          _testResults +=
              '✅ Success: Mã hợp lệ! Giảm ${result['discountAmount'].toStringAsFixed(0)}đ\n';
        } else {
          _testResults += '❌ Invalid: ${result['message']}\n';
          if (result['errors'] != null && result['errors'].isNotEmpty) {
            for (String error in result['errors']) {
              _testResults += '   - $error\n';
            }
          }
        }
        _testResults += '\n';
      });
    } catch (e) {
      setState(() {
        _testResults += '❌ Error: $e\n\n';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Promotion API'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _runAllTests, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          // Test Controls
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                TextField(
                  controller: _voucherCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Mã Voucher để test',
                    border: OutlineInputBorder(),
                    hintText: 'Nhập mã voucher...',
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _orderAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Số tiền đơn hàng',
                    border: OutlineInputBorder(),
                    suffixText: 'VND',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testValidateVoucher,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Test Validate Voucher'),
                  ),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: SingleChildScrollView(
                child: Text(
                  _testResults,
                  style: const TextStyle(
                    color: Colors.green,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),

          // Quick Stats
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'Khuyến mãi',
                  _activePromotions.length.toString(),
                ),
                _buildStatCard(
                  'Mã công khai',
                  _activeVouchers.length.toString(),
                ),
                _buildStatCard('Mã của tôi', _myVouchers.length.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
