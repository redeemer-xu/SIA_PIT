import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import 'pay_bill_screen.dart';

class MyBillsScreen extends StatefulWidget {
  const MyBillsScreen({super.key});

  @override
  State<MyBillsScreen> createState() => _MyBillsScreenState();
}

class _MyBillsScreenState extends State<MyBillsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List _allBills = [];
  List _filtered = [];
  bool _loading = true;
  final _search = TextEditingController();
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(_filter);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getMyBills();
      if (mounted) {
        setState(() {
          _allBills = (res['bills'] as List?) ?? [];
          _filtered = _allBills;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filter() {
    final q = _search.text.toLowerCase();
    setState(() {
      _filtered = _allBills.where((b) {
        final matchStatus = _statusFilter == 'all' || b['status'] == _statusFilter;
        final matchSearch = q.isEmpty ||
            b['billing_date'].toString().contains(q) ||
            b['status'].toString().contains(q) ||
            b['amount_due'].toString().contains(q);
        return matchStatus && matchSearch;
      }).toList();
    });
  }

  String _currency(dynamic v) => '₱${NumberFormat('#,##0.00').format(double.tryParse(v.toString()) ?? 0)}';

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('My Bills')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    hintText: 'Search bills...',
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['all', 'unpaid', 'paid', 'overdue'].map((s) {
                      final active = _statusFilter == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(s.toUpperCase()),
                          selected: active,
                          selectedColor: AppTheme.primary,
                          labelStyle: TextStyle(color: active ? Colors.white : Colors.grey),
                          onSelected: (_) { setState(() => _statusFilter = s); _filter(); },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? const Center(child: Text('No bills found.', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => _billCard(_filtered[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _billCard(Map<String, dynamic> bill) {
    final status = bill['status'] as String;
    final color = status == 'paid' ? AppTheme.success : status == 'overdue' ? AppTheme.error : AppTheme.warning;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Billing: ${bill['billing_date']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                _infoChip(Icons.flash_on, '${bill['kwh_consumed']} kWh'),
                const SizedBox(width: 12),
                _infoChip(Icons.calendar_today, 'Due: ${bill['due_date']}'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Amount Due', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(_currency(bill['amount_due']), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                  ],
                ),
                if (status != 'paid')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('Pay Now'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(120, 42)),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PayBillScreen(bill: bill))).then((_) => _load()),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
