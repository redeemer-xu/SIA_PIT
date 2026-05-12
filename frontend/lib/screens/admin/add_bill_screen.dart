import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme.dart';

class AddBillScreen extends StatefulWidget {
  const AddBillScreen({super.key});

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  final _formKey = GlobalKey<FormState>();
  List _users = [];
  int? _selectedUserId;
  String? _selectedUserName;
  final _kwhCtrl = TextEditingController();
  DateTime _billingDate = DateTime.now();
  bool _loading = false;
  bool _loadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final res = await ApiService.getAllUsers();
      if (mounted) setState(() { _users = (res['users'] as List?) ?? []; _loadingUsers = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _billingDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _billingDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a user.'), backgroundColor: AppTheme.error),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_billingDate);
      final res = await ApiService.addBill(
        _selectedUserId!,
        double.tryParse(_kwhCtrl.text) ?? 0,
        dateStr,
      );
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill added successfully!'), backgroundColor: AppTheme.success),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['error'] ?? 'Failed to add bill.'), backgroundColor: AppTheme.error),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection error.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Add New Bill')),
      body: _loadingUsers
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Customer', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDDE2EC)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          hint: const Text('Choose a customer'),
                          value: _selectedUserId,
                          items: _users.map<DropdownMenuItem<int>>((u) => DropdownMenuItem(
                            value: u['id'] as int,
                            child: Text('${u['firstName']} ${u['lastname']} (${u['meter_number'] ?? 'No meter'})'),
                          )).toList(),
                          onChanged: (v) => setState(() { _selectedUserId = v; }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('kWh Consumed', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _kwhCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        hintText: 'e.g. 125.50',
                        prefixIcon: Icon(Icons.flash_on),
                        suffixText: 'kWh',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter kWh value';
                        if (double.tryParse(v) == null) return 'Enter a valid number';
                        if (double.parse(v) <= 0) return 'Must be greater than 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text('Billing Date', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDDE2EC)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: AppTheme.primary),
                            const SizedBox(width: 12),
                            Text(DateFormat('MMMM dd, yyyy').format(_billingDate),
                                style: const TextStyle(fontSize: 15)),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Bill'),
                            onPressed: _submit,
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
