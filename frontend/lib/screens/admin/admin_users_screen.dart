import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List _all = [], _filtered = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(_filter);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getAllUsers();
      if (mounted) {
        setState(() {
          _all = (res['users'] as List?) ?? [];
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
      _filtered = q.isEmpty
          ? _all
          : _all.where((u) =>
              '${u['firstName']} ${u['lastname']}'.toLowerCase().contains(q) ||
              (u['meter_number'] ?? '').toString().toLowerCase().contains(q) ||
              (u['emailAddress'] ?? '').toString().toLowerCase().contains(q) ||
              (u['city'] ?? '').toString().toLowerCase().contains(q)).toList();
    });
  }

  String _currency(dynamic v) =>
      '₱${NumberFormat('#,##0.00').format(double.tryParse(v.toString()) ?? 0)}';

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: Text('Customers (${_all.length})')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search by name, meter, email, city...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? const Center(child: Text('No users found.', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => _userCard(_filtered[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> user) {
    final isActive = user['status'] == 'active';
    final name = '${user['firstName']} ${user['lastname']}';
    final totalUnpaid = double.tryParse(user['total_unpaid']?.toString() ?? '0') ?? 0;
    final totalBills = user['total_bills'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showUserDetail(user),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary.withOpacity(0.15),
                child: Text(name[0].toUpperCase(),
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isActive ? AppTheme.success : Colors.grey).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(user['status'].toString().toUpperCase(),
                              style: TextStyle(
                                  color: isActive ? AppTheme.success : Colors.grey,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Meter: ${user['meter_number'] ?? 'N/A'}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('${user['city'] ?? ''} · ${user['emailAddress'] ?? ''}',
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _badge('$totalBills Bills', Colors.indigo),
                        const SizedBox(width: 8),
                        if (totalUnpaid > 0)
                          _badge('Unpaid: ${_currency(totalUnpaid)}', AppTheme.warning),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );

  void _showUserDetail(Map<String, dynamic> user) {
    final name = '${user['firstName']} ${user['lastname']}';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppTheme.primary,
                      child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 10),
                    Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(user['username'] ?? '', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _detailRow(Icons.confirmation_number, 'Meter Number', user['meter_number'] ?? 'N/A'),
              _detailRow(Icons.email_outlined, 'Email', user['emailAddress'] ?? 'N/A'),
              _detailRow(Icons.phone_outlined, 'Contact', user['contactNumber'] ?? 'N/A'),
              _detailRow(Icons.location_on_outlined, 'Address',
                  '${user['street']}, ${user['barangay']}, ${user['city']}'),
              _detailRow(Icons.receipt_long, 'Total Bills', user['total_bills'].toString()),
              _detailRow(Icons.account_balance_wallet, 'Total Unpaid', _currency(user['total_unpaid'] ?? 0)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      );
}
