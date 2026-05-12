import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // TODO: Change this to your classmate's Laravel API base URL
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ─── AUTH ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: await _headers(auth: false),
      body: jsonEncode({'username': username, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: await _headers(auth: false),
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<void> logout() async {
    try {
      await http.post(Uri.parse('$baseUrl/logout'), headers: await _headers());
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ─── USER – BILLS ────────────────────────────────────────
  static Future<Map<String, dynamic>> getMyBills() async {
    final res = await http.get(Uri.parse('$baseUrl/user/bills'), headers: await _headers());
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getBillById(int billId) async {
    final res = await http.get(Uri.parse('$baseUrl/user/bills/$billId'), headers: await _headers());
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> payBill(int billId, double amount, String method) async {
    final res = await http.post(
      Uri.parse('$baseUrl/user/bills/$billId/pay'),
      headers: await _headers(),
      body: jsonEncode({'amount': amount, 'payment_method': method}),
    );
    return jsonDecode(res.body);
  }

  // ─── USER – PROFILE ──────────────────────────────────────
  static Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(Uri.parse('$baseUrl/user/profile'), headers: await _headers());
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/user/profile'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  // ─── ADMIN – DASHBOARD ───────────────────────────────────
  static Future<Map<String, dynamic>> getAdminDashboard() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/dashboard'), headers: await _headers());
    return jsonDecode(res.body);
  }

  // ─── ADMIN – USERS ───────────────────────────────────────
  static Future<Map<String, dynamic>> getAllUsers() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/users'), headers: await _headers());
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> searchUsers(String query) async {
    final res = await http.get(
      Uri.parse('$baseUrl/admin/users?search=$query'),
      headers: await _headers(),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getUserById(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/admin/users/$userId'), headers: await _headers());
    return jsonDecode(res.body);
  }

  // ─── ADMIN – BILLS ───────────────────────────────────────
  static Future<Map<String, dynamic>> getAllBills() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/bills'), headers: await _headers());
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> addBill(int userId, double kwh, String billingDate) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/bills'),
      headers: await _headers(),
      body: jsonEncode({'user_id': userId, 'kwh_consumed': kwh, 'billing_date': billingDate}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> searchBills(String query) async {
    final res = await http.get(
      Uri.parse('$baseUrl/admin/bills?search=$query'),
      headers: await _headers(),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getSettings() async {
    final res = await http.get(
      Uri.parse('$baseUrl/admin/settings'),
      headers: await _headers(),
    );
      return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/admin/settings'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
      return jsonDecode(res.body);
  }
}
