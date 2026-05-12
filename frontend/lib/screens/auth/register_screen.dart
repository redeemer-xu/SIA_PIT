import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _middle = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _contact = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _street = TextEditingController();
  final _barangay = TextEditingController();
  final _city = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_password.text != _confirm.text) {
      _showError('Passwords do not match.');
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await ApiService.register({
        'firstName': _first.text.trim(),
        'middleName': _middle.text.trim(),
        'lastname': _last.text.trim(),
        'email': _email.text.trim(),
        'contactNumber': _contact.text.trim(),
        'username': _username.text.trim(),
        'password': _password.text,
        'street': _street.text.trim(),
        'barangay': _barangay.text.trim(),
        'city': _city.text.trim(),
      });
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please log in.'), backgroundColor: AppTheme.success),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      } else {
        _showError(res['error'] ?? 'Registration failed.');
      }
    } catch (e) {
      _showError('Cannot connect to server.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.error));
  }

  Widget _field(String label, TextEditingController ctrl, {bool required = true, TextInputType? keyboardType, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, prefixIcon: icon != null ? Icon(icon) : null),
        validator: required ? (v) => v!.isEmpty ? 'Required' : null : null,
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 15)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _section('Personal Information'),
              _field('First Name', _first, icon: Icons.person_outline),
              _field('Middle Name', _middle, required: false, icon: Icons.person_outline),
              _field('Last Name', _last, icon: Icons.person_outline),
              _field('Email Address', _email, keyboardType: TextInputType.emailAddress, icon: Icons.email_outlined),
              _field('Contact Number', _contact, keyboardType: TextInputType.phone, icon: Icons.phone_outlined),
              _section('Address'),
              _field('Street', _street, icon: Icons.home_outlined),
              _field('Barangay', _barangay, icon: Icons.location_on_outlined),
              _field('City / Municipality', _city, icon: Icons.location_city_outlined),
              _section('Account Credentials'),
              _field('Username', _username, icon: Icons.badge_outlined),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => v!.length < 6 ? 'Minimum 6 characters' : null,
                ),
              ),
              TextFormField(
                controller: _confirm,
                obscureText: _obscure,
                decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline)),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(onPressed: _register, child: const Text('Create Account')),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Already have an account? Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
