import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'history_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String nama;

  const HomeScreen({super.key, required this.nama});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String _nama;
  Map<String, dynamic>? _stat;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _nama = widget.nama;
    _muat();
  }

  Future<void> _muat() async {
    try {
      final hasil = await ApiService.ambilProfil();
      if (!mounted) return;
      if (hasil['berhasil'] == true) {
        setState(() {
          _nama = '${hasil['user']['nama']}';
          _stat = hasil['statistik'] as Map<String, dynamic>;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _buka(Widget layar) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => layar));
    _muat();
  }

  String _rupiah(int angka) {
    final s = angka.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp$buf';
  }

  Widget _kartuStat(String judul, String nilai, IconData ikon, Color warna) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(ikon, color: warna, size: 28),
              const SizedBox(height: 8),
              Text(
                nilai,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                judul,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menu(String judul, String sub, IconData ikon, VoidCallback aksi) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFF0E0),
          child: Icon(ikon, color: const Color(0xFFFF6F00)),
        ),
        title: Text(judul, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(sub),
        trailing: const Icon(Icons.chevron_right),
        onTap: aksi,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _stat?['total'] ?? 0;
    final selesai = _stat?['selesai'] ?? 0;
    final dibatalkan = _stat?['dibatalkan'] ?? 0;
    final totalBayar = _stat?['total_bayar'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TowingKu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
            onPressed: _muat,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Profil',
            onPressed: () => _buka(const ProfileScreen()),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6F00),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, $_nama!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Kendaraanmu bermasalah? Kami siap membantu.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ringkasan Pesanan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  Row(
                    children: [
                      _kartuStat(
                        'Total',
                        '$total',
                        Icons.receipt_long,
                        Colors.blue,
                      ),
                      _kartuStat(
                        'Selesai',
                        '$selesai',
                        Icons.check_circle,
                        Colors.green,
                      ),
                      _kartuStat(
                        'Batal',
                        '$dibatalkan',
                        Icons.cancel,
                        Colors.red,
                      ),
                    ],
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.payments, color: Colors.green),
                      title: const Text('Total pembayaran lunas'),
                      trailing: Text(
                        _rupiah(totalBayar as int),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Menu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _menu(
                  'Pesan Towing',
                  'Pilih lokasi jemput dan tujuan',
                  Icons.add_location_alt,
                  () => _buka(const MapScreen()),
                ),
                _menu(
                  'Riwayat Pesanan',
                  'Lihat, lacak, dan bayar pesanan',
                  Icons.history,
                  () => _buka(const HistoryScreen()),
                ),
                _menu(
                  'Profil Saya',
                  'Ubah nama dan nomor telepon',
                  Icons.person,
                  () => _buka(const ProfileScreen()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
