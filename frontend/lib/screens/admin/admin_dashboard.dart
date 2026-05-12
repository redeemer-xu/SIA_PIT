import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../auth/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _loading = true;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getAdminDashboard();
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _currency(dynamic v) =>
      '₱${NumberFormat('#,##0.00').format(double.tryParse(v.toString()) ?? 0)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1a237e), AppTheme.primary],
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
                        children: const [
                          Text('Admin Panel', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          SizedBox(height: 4),
                          Text('E-Bill Dashboard', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
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
                    // Revenue card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF43A047)]),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Revenue', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 6),
                              Text(_currency(_data['total_revenue'] ?? 0),
                                  style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Icon(Icons.trending_up, color: Colors.white54, size: 48),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Stats grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _statCard('Total Users', _data['total_users']?.toString() ?? '0', Icons.people, AppTheme.primary),
                        _statCard('Total Bills', _data['total_bills']?.toString() ?? '0', Icons.receipt_long, Colors.indigo),
                        _statCard('Paid Bills', _data['total_paid']?.toString() ?? '0', Icons.check_circle, AppTheme.success),
                        _statCard('Unpaid Bills', _data['total_unpaid']?.toString() ?? '0', Icons.pending, AppTheme.warning),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Rate info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFDDE2EC)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.flash_on, color: AppTheme.accent, size: 28),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Current Rate', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text('₱${_data['rate'] ?? 0} / kWh',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}
