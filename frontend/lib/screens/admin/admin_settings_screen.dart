import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _rate       = TextEditingController();
  final _dueDays    = TextEditingController();
  final _systemName = TextEditingController();
  final _city       = TextEditingController();
  bool _loading = true;
  bool _saving  = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _rate.dispose();
    _dueDays.dispose();
    _systemName.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getSettings();
      if (mounted && res['success'] == true) {
        _rate.text       = res['rate_per_kwh'].toString();
        _dueDays.text    = res['due_days'].toString();
        _systemName.text = res['system_name'] ?? '';
        _city.text       = res['city'] ?? '';
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final res = await ApiService.updateSettings({
        'rate_per_kwh': double.parse(_rate.text),
        'due_days':     int.parse(_dueDays.text),
        'system_name':  _systemName.text.trim(),
        'city':         _city.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['success'] == true
              ? '✅ Settings saved successfully!'
              : res['error'] ?? 'Failed to save.'),
          backgroundColor:
              res['success'] == true ? AppTheme.success : AppTheme.error,
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Connection error.'),
            backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryDark)),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    TextInputType? type,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: validator ?? (v) => v!.isEmpty ? 'Required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('System Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Billing Settings ──────────────────────────────
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader(Icons.bolt, 'Billing Settings'),
                            const SizedBox(height: 16),
                            _field(
                              'Rate per kWh (₱)',
                              _rate,
                              hint: 'e.g. 11.00',
                              type: const TextInputType.numberWithOptions(
                                  decimal: true),
                              validator: (v) {
                                if (v!.isEmpty) return 'Required';
                                if (double.tryParse(v) == null)
                                  return 'Enter a valid number';
                                if (double.parse(v) <= 0)
                                  return 'Must be greater than 0';
                                return null;
                              },
                            ),
                            _field(
                              'Due Days (after billing date)',
                              _dueDays,
                              hint: 'e.g. 30',
                              type: TextInputType.number,
                              validator: (v) {
                                if (v!.isEmpty) return 'Required';
                                if (int.tryParse(v) == null)
                                  return 'Enter a whole number';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ── System Information ────────────────────────────
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader(
                                Icons.info_outline, 'System Information'),
                            const SizedBox(height: 16),
                            _field('System Name', _systemName,
                                hint: 'e.g. Electricity Billing System'),
                            _field('City / Municipality', _city,
                                hint: 'e.g. Libona'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // ── Save Button ───────────────────────────────────
                    _saving
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('Save Settings'),
                            onPressed: _save,
                          ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}