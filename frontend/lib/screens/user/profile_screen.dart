import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Map<String, dynamic> _user = {};
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;

  final _first = TextEditingController();
  final _middle = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _contact = TextEditingController();
  final _street = TextEditingController();
  final _barangay = TextEditingController();
  final _city = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getProfile();
      if (mounted && res['success'] == true) {
        final u = res['user'] as Map<String, dynamic>;
        setState(() {
          _user = u;
          _first.text = u['firstName'] ?? '';
          _middle.text = u['middleName'] ?? '';
          _last.text = u['lastname'] ?? '';
          _email.text = u['emailAddress'] ?? '';
          _contact.text = u['contactNumber'] ?? '';
          _street.text = u['street'] ?? '';
          _barangay.text = u['barangay'] ?? '';
          _city.text = u['city'] ?? '';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final res = await ApiService.updateProfile({
        'firstName': _first.text.trim(),
        'middleName': _middle.text.trim(),
        'lastname': _last.text.trim(),
        'email': _email.text.trim(),
        'contact': _contact.text.trim(),
        'street': _street.text.trim(),
        'barangay': _barangay.text.trim(),
        'city': _city.text.trim(),
      });
      if (!mounted) return;
      if (res['success'] == true) {
        setState(() => _editing = false);
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!'), backgroundColor: AppTheme.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['error'] ?? 'Update failed.'), backgroundColor: AppTheme.error),
        );
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection error.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final name = '${_user['firstName'] ?? ''} ${_user['lastname'] ?? ''}'.trim();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _editing ? null : () => setState(() => _editing = true),
              child: Text(_editing ? '' : 'Edit', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: AppTheme.primary,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            'Meter: ${_user['meter_number'] ?? 'N/A'}',
                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Fields
                  _section('Personal Information'),
                  _field('First Name', _first, Icons.person_outline),
                  _field('Middle Name', _middle, Icons.person_outline),
                  _field('Last Name', _last, Icons.person_outline),
                  _field('Email', _email, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  _field('Contact', _contact, Icons.phone_outlined, keyboardType: TextInputType.phone),
                  _section('Address'),
                  _field('Street', _street, Icons.home_outlined),
                  _field('Barangay', _barangay, Icons.location_on_outlined),
                  _field('City', _city, Icons.location_city_outlined),
                  if (_editing) ...[
                    const SizedBox(height: 20),
                    _saving
                        ? const CircularProgressIndicator()
                        : Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () { setState(() => _editing = false); _load(); },
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _save,
                                  child: const Text('Save Changes'),
                                ),
                              ),
                            ],
                          ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 14)),
        ),
      );

  Widget _field(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        enabled: _editing,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: _editing ? Colors.white : Colors.grey.shade100,
        ),
      ),
    );
  }
}
