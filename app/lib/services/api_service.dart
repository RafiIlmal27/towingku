import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  static String? token;

  // REGISTER
  static Future<Map<String, dynamic>> register({
    required String nama,
    required String email,
    required String password,
    String? telepon,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nama': nama,
        'email': email,
        'password': password,
        'telepon': telepon,
      }),
    );
    return _baca(response);
  }

  // LOGIN
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _baca(response);
    if (data['berhasil'] == true) {
      token = data['token'];
    }
    return data;
  }

  // BUAT PESANAN
  static Future<Map<String, dynamic>> buatPesanan({
    required double jemputLat,
    required double jemputLng,
    required double tujuanLat,
    required double tujuanLng,
    required double jarakKm,
    required int biaya,
    required String jenisKendaraan,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'jemput_lat': jemputLat,
        'jemput_lng': jemputLng,
        'tujuan_lat': tujuanLat,
        'tujuan_lng': tujuanLng,
        'jarak_km': jarakKm,
        'biaya': biaya,
        'jenis_kendaraan': jenisKendaraan,
      }),
    );
    return _baca(response);
  }

  // RIWAYAT PESANAN
  static Future<Map<String, dynamic>> ambilRiwayat() async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return _baca(response);
  }

  // DETAIL + TRACKING PESANAN
  static Future<Map<String, dynamic>> ambilPesanan(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return _baca(response);
  }

  // BATALKAN PESANAN
  static Future<Map<String, dynamic>> batalkanPesanan(int id) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$id/cancel'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return _baca(response);
  }

  // BAYAR PESANAN
  static Future<Map<String, dynamic>> bayarPesanan(
    int id,
    String metode,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$id/pay'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'metode': metode}),
    );
    return _baca(response);
  }

  // AMBIL PROFIL + STATISTIK
  static Future<Map<String, dynamic>> ambilProfil() async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return _baca(response);
  }

  // UBAH PROFIL
  static Future<Map<String, dynamic>> ubahProfil({
    required String nama,
    String? telepon,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'nama': nama, 'telepon': telepon}),
    );
    return _baca(response);
  }

  static Map<String, dynamic> _baca(http.Response response) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    data['berhasil'] = response.statusCode >= 200 && response.statusCode < 300;
    return data;
  }
}
