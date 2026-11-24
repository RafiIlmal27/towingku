import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';
import 'tracking_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _pusat = LatLng(-7.2575, 112.7521);

  // Tarif: [tarif dasar, tarif per km]
  static const Map<String, List<int>> _tarif = {
    'Motor': [50000, 5000],
    'Mobil': [100000, 10000],
    'Truk': [200000, 15000],
  };

  LatLng? _jemput;
  LatLng? _tujuan;
  String _kendaraan = 'Mobil';
  bool _mengirim = false;

  void _ketukPeta(TapPosition tap, LatLng titik) {
    setState(() {
      if (_jemput == null) {
        _jemput = titik;
      } else if (_tujuan == null) {
        _tujuan = titik;
      }
    });
  }

  void _ulang() {
    setState(() {
      _jemput = null;
      _tujuan = null;
    });
  }

  double get _jarakKm {
    if (_jemput == null || _tujuan == null) return 0;
    return const Distance().as(LengthUnit.Kilometer, _jemput!, _tujuan!);
  }

  int get _biaya {
    final t = _tarif[_kendaraan]!;
    return t[0] + (_jarakKm * t[1]).round();
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

  Future<void> _lanjut() async {
    setState(() => _mengirim = true);
    try {
      final hasil = await ApiService.buatPesanan(
        jemputLat: _jemput!.latitude,
        jemputLng: _jemput!.longitude,
        tujuanLat: _tujuan!.latitude,
        tujuanLng: _tujuan!.longitude,
        jarakKm: double.parse(_jarakKm.toStringAsFixed(2)),
        biaya: _biaya,
        jenisKendaraan: _kendaraan,
      );

      if (!mounted) return;
      setState(() => _mengirim = false);

      final berhasil = hasil['berhasil'] == true;

      if (berhasil) {
        final id = hasil['order']['id'] as int;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => TrackingScreen(orderId: id)),
        );
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Gagal'),
            content: Text(hasil['error'] ?? 'Pesanan gagal dibuat'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _mengirim = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa terhubung ke server')),
      );
    }
  }

  Widget _panelBawah() {
    if (_jemput == null || _tujuan == null) {
      final teks = _jemput == null
          ? 'Ketuk peta untuk menentukan lokasi JEMPUT'
          : 'Ketuk peta untuk menentukan lokasi TUJUAN';
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(teks, textAlign: TextAlign.center),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Motor', label: Text('Motor')),
                ButtonSegment(value: 'Mobil', label: Text('Mobil')),
                ButtonSegment(value: 'Truk', label: Text('Truk')),
              ],
              selected: {_kendaraan},
              onSelectionChanged: (s) => setState(() => _kendaraan = s.first),
            ),
            const SizedBox(height: 12),
            Text('Jarak: ${_jarakKm.toStringAsFixed(1)} km'),
            const SizedBox(height: 4),
            Text(
              'Estimasi: ${_rupiah(_biaya)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _mengirim ? null : _lanjut,
                child: _mengirim
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Pesan Sekarang'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Ulang',
            onPressed: _ulang,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _pusat,
              initialZoom: 13,
              onTap: _ketukPeta,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.towingku',
              ),
              if (_jemput != null && _tujuan != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_jemput!, _tujuan!],
                      strokeWidth: 4,
                      color: Colors.blue,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_jemput != null)
                    Marker(
                      point: _jemput!,
                      width: 44,
                      height: 44,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 44,
                      ),
                    ),
                  if (_tujuan != null)
                    Marker(
                      point: _tujuan!,
                      width: 44,
                      height: 44,
                      child: const Icon(
                        Icons.flag,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(left: 16, right: 16, bottom: 24, child: _panelBawah()),
        ],
      ),
    );
  }
}
