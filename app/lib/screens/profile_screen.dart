import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _namaController = TextEditingController();
  final _teleponController = TextEditingController();
  String _email = '';
  String _bergabung = '';
  bool _loading = true;
  bool _menyimpan = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _teleponController.dispose();
    super.dispose();
  }

  Future<void> _muat() async {
    try {
      final hasil = await ApiService.ambilProfil();
      if (!mounted) return;
      if (hasil['berhasil'] == true) {
        final u = hasil['user'] as Map<String, dynamic>;
        setState(() {
          _namaController.text = '${u['nama'] ?? ''}';
          _teleponController.text = '${u['telepon'] ?? ''}';
          _email = '${u['email'] ?? ''}';
          _bergabung = '${u['created_at'] ?? ''}'.split('T').first;
          _loading = false;
        });
      } else {
        setState(() {
          _error = hasil['error'] ?? 'Gagal memuat profil';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Tidak bisa terhubung ke server';
        _loading = false;
      });
    }
  }

  Future<void> _simpan() async {
    final nama = _namaController.text.trim();
    if (nama.isEmpty) {
      _pesan('Nama wajib diisi');
      return;
    }
    setState(() => _menyimpan = true);
    try {
      final hasil = await ApiService.ubahProfil(
        nama: nama,
        telepon: _teleponController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _menyimpan = false);
      _pesan(
        hasil['berhasil'] == true
            ? 'Profil diperbarui'
            : (hasil['error'] ?? 'Gagal menyimpan'),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _menyimpan = false);
      _pesan('Tidak bisa terhubung ke server');
    }
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  void _keluar() {
    ApiService.token = null;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: _isi(),
    );
  }

  Widget _isi() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }

    final inisial = _namaController.text.isNotEmpty
        ? _namaController.text[0].toUpperCase()
        : '?';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: const Color(0xFFFF6F00),
                child: Text(
                  inisial,
                  style: const TextStyle(
                    fontSize: 36,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(_email, style: const TextStyle(fontSize: 16)),
              Text(
                'Bergabung sejak $_bergabung',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama lengkap',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _teleponController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor telepon',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _menyimpan ? null : _simpan,
                  child: _menyimpan
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Simpan Perubahan'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _keluar,
                  icon: const Icon(Icons.logout),
                  label: const Text('Keluar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
