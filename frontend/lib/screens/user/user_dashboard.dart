import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../auth/login_screen.dart';
import 'pay_bill_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  bool _loading = true;
  Map<String, dynamic> _data = {};
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _userName = (await AuthService.getUserName()) ?? '';
      final res = await ApiService.getMyBills();
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _currency(dynamic v) => '₱${NumberFormat('#,##0.00').format(double.tryParse(v.toString()) ?? 0)}';

  @override
  Widget build(BuildContext context) {
    final bills = (_data['bills'] as List?) ?? [];
    final unpaidBills = bills.where((b) => b['status'] == 'unpaid').toList();
    final totalUnpaid = unpaidBills.fold<double>(0, (s, b) => s + (double.tryParse(b['amount_due'].toString()) ?? 0));
    final latestBill = bills.isNotEmpty ? bills.first : null;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryDark, AppTheme.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Hello, $_userName 👋', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 4),
                          const Text('Your Electricity Account', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () async {
                    await AuthService.logout();
                    if (!mounted) return;
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                ),
              ],
            ),
            if (_loading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Summary cards
                    Row(
                      children: [
                        Expanded(child: _summaryCard('Total Bills', bills.length.toString(), Icons.receipt_long, AppTheme.primary)),
                        const SizedBox(width: 12),
                        Expanded(child: _summaryCard('Unpaid', unpaidBills.length.toString(), Icons.warning_amber, AppTheme.warning)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Balance card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFE65100), Color(0xFFFF6D00)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Outstanding Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(_currency(totalUnpaid), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Icon(Icons.account_balance_wallet, color: Colors.white54, size: 40),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Recent Bills', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: 12),
                    if (bills.isEmpty)
                      const Center(child: Text('No bills yet.', style: TextStyle(color: Colors.grey)))
                    else
                      ...bills.take(5).map((b) => _billTile(b)),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _billTile(Map<String, dynamic> bill) {
    final isPaid = bill['status'] == 'paid';
    final color = isPaid ? AppTheme.success : AppTheme.warning;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(isPaid ? Icons.check_circle : Icons.pending, color: color),
        ),
        title: Text('${bill['billing_date']}', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${bill['kwh_consumed']} kWh consumed'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_currency(bill['amount_due']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(bill['status'].toString().toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        onTap: !isPaid
            ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => PayBillScreen(bill: bill))).then((_) => _load())
            : null,
      ),
    );
  }
}
