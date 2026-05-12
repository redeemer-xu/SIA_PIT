import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme.dart';

class PayBillScreen extends StatefulWidget {
  final Map<String, dynamic> bill;
  const PayBillScreen({super.key, required this.bill});

  @override
  State<PayBillScreen> createState() => _PayBillScreenState();
}

class _PayBillScreenState extends State<PayBillScreen> {
  String _method = 'cash';
  bool _loading = false;

  final _methods = [
    {'value': 'cash', 'label': 'Cash', 'icon': Icons.money},
    {'value': 'gcash', 'label': 'GCash', 'icon': Icons.phone_android},
    {'value': 'maya', 'label': 'Maya', 'icon': Icons.account_balance_wallet},
    {'value': 'bank', 'label': 'Bank Transfer', 'icon': Icons.account_balance},
  ];

  String _currency(dynamic v) =>
      '₱${NumberFormat('#,##0.00').format(double.tryParse(v.toString()) ?? 0)}';

  Future<void> _pay() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.payBill(
        widget.bill['id'],
        double.tryParse(widget.bill['amount_due'].toString()) ?? 0,
        _method,
      );
      if (!mounted) return;
      if (res['success'] == true) {
        _showSuccess();
      } else {
        _showError(res['error'] ?? 'Payment failed.');
      }
    } catch (e) {
      _showError('Cannot connect to server.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: AppTheme.success, size: 56),
            ),
            const SizedBox(height: 16),
            const Text('Payment Successful!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Your payment of ${_currency(widget.bill['amount_due'])} has been recorded.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // back to bills
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.error));
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Pay Bill')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bill Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryDark, AppTheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bill Summary', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 12),
                  Text(_currency(bill['amount_due']),
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _summaryRow('Billing Date', bill['billing_date'].toString()),
                  _summaryRow('Due Date', bill['due_date'].toString()),
                  _summaryRow('kWh Consumed', '${bill['kwh_consumed']} kWh'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Select Payment Method',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ..._methods.map((m) => _methodTile(m)),
            const SizedBox(height: 28),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    icon: const Icon(Icons.payment),
                    label: Text('Pay ${_currency(bill['amount_due'])}'),
                    onPressed: _confirmAndPay,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      );

  Widget _methodTile(Map<String, dynamic> m) {
    final selected = _method == m['value'];
    return GestureDetector(
      onTap: () => setState(() => _method = m['value'] as String),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppTheme.primary : const Color(0xFFDDE2EC), width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(m['icon'] as IconData, color: selected ? AppTheme.primary : Colors.grey),
            const SizedBox(width: 14),
            Text(m['label'] as String,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? AppTheme.primary : Colors.black87)),
            const Spacer(),
            if (selected) const Icon(Icons.check_circle, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

  void _confirmAndPay() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text(
            'Pay ${_currency(widget.bill['amount_due'])} via ${_method.toUpperCase()}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 40)),
            onPressed: () { Navigator.pop(context); _pay(); },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
