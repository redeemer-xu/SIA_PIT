import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import 'add_bill_screen.dart';

class AdminBillsScreen extends StatefulWidget {
  const AdminBillsScreen({super.key});

  @override
  State<AdminBillsScreen> createState() => _AdminBillsScreenState();
}

class _AdminBillsScreenState extends State<AdminBillsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List _all = [], _filtered = [];
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
      final res = await ApiService.getAllBills();
      if (mounted) {
        setState(() {
          _all = (res['bills'] as List?) ?? [];
          _filtered = _all;
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
      _filtered = _all.where((b) {
        final matchStatus = _statusFilter == 'all' || b['status'] == _statusFilter;
        final matchSearch = q.isEmpty ||
            (b['full_name'] ?? '').toString().toLowerCase().contains(q) ||
            (b['meter_number'] ?? '').toString().toLowerCase().contains(q) ||
            b['billing_date'].toString().contains(q) ||
            b['amount_due'].toString().contains(q);
        return matchStatus && matchSearch;
      }).toList();
    });
  }

  String _currency(dynamic v) =>
      '₱${NumberFormat('#,##0.00').format(double.tryParse(v.toString()) ?? 0)}';

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('All Bills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddBillScreen()))
                .then((_) => _load()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    hintText: 'Search by name, meter, date...',
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
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(bill['full_name'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(status.toUpperCase(),
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Meter: ${bill['meter_number'] ?? 'N/A'}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const Divider(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _chip(Icons.calendar_today, bill['billing_date'].toString()),
                _chip(Icons.flash_on, '${bill['kwh_consumed']} kWh'),
                Text(_currency(bill['amount_due']),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 13, color: Colors.grey),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      );
}
