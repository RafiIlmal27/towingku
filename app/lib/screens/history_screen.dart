import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'tracking_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final hasil = await ApiService.ambilRiwayat();
      if (!mounted) return;
      if (hasil['berhasil'] == true) {
        setState(() {
          _orders = hasil['orders'] as List<dynamic>;
          _loading = false;
        });
      } else {
        setState(() {
          _error = hasil['error'] ?? 'Gagal memuat riwayat';
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

  Future<void> _bayar(int id) async {
    final metode = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Pilih metode pembayaran'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'tunai'),
            child: const ListTile(
                leading: Icon(Icons.payments), title: Text('Tunai')),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'transfer'),
            child: const ListTile(
                leading: Icon(Icons.account_balance),
                title: Text('Transfer Bank')),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'ewallet'),
            child: const ListTile(
                leading: Icon(Icons.account_balance_wallet),
                title: Text('E-Wallet')),
          ),
        ],
      ),
    );
    if (metode == null) return;

    try {
      final hasil = await ApiService.bayarPesanan(id, metode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hasil['berhasil'] == true
              ? 'Pembayaran berhasil'
              : (hasil['error'] ?? 'Pembayaran gagal')),
        ),
      );
      _muat();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa terhubung ke server')),
      );
    }
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

  String _namaStatus(String status) {
    switch (status) {
      case 'menunggu':
        return 'Menunggu driver';
      case 'diterima':
        return 'Driver diterima';
      case 'menuju_lokasi':
        return 'Driver menuju lokasi';
      case 'dalam_perjalanan':
        return 'Dalam perjalanan';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Color _warnaStatus(String status) {
    if (status == 'selesai') return Colors.green;
    if (status == 'dibatalkan') return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
            onPressed: _muat,
          ),
        ],
      ),
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
    if (_orders.isEmpty) {
      return const Center(child: Text('Belum ada pesanan'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _orders.length,
      itemBuilder: (context, i) {
        final o = _orders[i] as Map<String, dynamic>;
        final id = o['id'] as int;
        final status = (o['status'] ?? '') as String;
        final lunas = o['status_bayar'] == 'lunas';
        final jarak = double.tryParse('${o['jarak_km']}') ?? 0;
        final biaya = int.tryParse('${o['biaya']}') ?? 0;
        final tanggal = '${o['created_at'] ?? ''}'.split('T').first;
        final kendaraan =
            '${o['jemput_alamat'] ?? ''}'.replaceFirst('Kendaraan: ', '');

        return Card(
          child: Column(
            children: [
              ListTile(
                leading:
                    const Icon(Icons.local_shipping, color: Colors.orange),
                title: Text('Pesanan #$id  •  $kendaraan'),
                subtitle: Text(
                  '${jarak.toStringAsFixed(1)} km  •  ${_rupiah(biaya)}\n'
                  '$tanggal  •  ${lunas ? 'Lunas' : 'Belum dibayar'}',
                ),
                isThreeLine: true,
                trailing: Text(
                  _namaStatus(status),
                  style: TextStyle(
                    color: _warnaStatus(status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrackingScreen(orderId: id),
                  ),
                ),
              ),
              if (status == 'selesai' && !lunas)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _bayar(id),
                      icon: const Icon(Icons.payment),
                      label: const Text('Bayar Sekarang'),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}