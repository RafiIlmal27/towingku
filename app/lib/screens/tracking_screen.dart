import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';

class TrackingScreen extends StatefulWidget {
  final int orderId;

  const TrackingScreen({super.key, required this.orderId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  Timer? _timer;
  Map<String, dynamic>? _order;
  Map<String, dynamic>? _driver;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muat();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _muat());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _muat() async {
    try {
      final hasil = await ApiService.ambilPesanan(widget.orderId);
      if (!mounted) return;
      if (hasil['berhasil'] == true) {
        setState(() {
          _order = hasil['order'] as Map<String, dynamic>;
          _driver = hasil['driver'] as Map<String, dynamic>;
          _error = null;
        });
        if (_order!['status'] == 'selesai') _timer?.cancel();
      } else {
        setState(() => _error = hasil['error'] ?? 'Gagal memuat pesanan');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Tidak bisa terhubung ke server');
    }
  }

  String _namaStatus(String status) {
    switch (status) {
      case 'menunggu':
        return 'Mencari driver...';
      case 'menuju_lokasi':
        return 'Driver menuju lokasimu';
      case 'dalam_perjalanan':
        return 'Dalam perjalanan ke tujuan';
      case 'selesai':
        return 'Pesanan selesai';
      case 'dibatalkan':
        return 'Pesanan dibatalkan';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pesanan #${widget.orderId}')),
      body: _isi(),
    );
  }

  Widget _isi() {
    if (_error != null && _order == null) {
      return Center(child: Text(_error!));
    }
    if (_order == null || _driver == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final jemput = LatLng(
      (_order!['jemput_lat'] as num).toDouble(),
      (_order!['jemput_lng'] as num).toDouble(),
    );
    final tujuan = LatLng(
      (_order!['tujuan_lat'] as num).toDouble(),
      (_order!['tujuan_lng'] as num).toDouble(),
    );
    final posisiDriver = LatLng(
      (_driver!['lat'] as num).toDouble(),
      (_driver!['lng'] as num).toDouble(),
    );
    final status = _order!['status'] as String;

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(initialCenter: jemput, initialZoom: 13),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.towingku',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [jemput, tujuan],
                  strokeWidth: 3,
                  color: Colors.blue,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: jemput,
                  width: 44,
                  height: 44,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.green,
                    size: 44,
                  ),
                ),
                Marker(
                  point: tujuan,
                  width: 44,
                  height: 44,
                  child: const Icon(Icons.flag, color: Colors.red, size: 40),
                ),
                Marker(
                  point: posisiDriver,
                  width: 48,
                  height: 48,
                  child: const Icon(
                    Icons.local_shipping,
                    color: Colors.orange,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _namaStatus(status),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Driver: ${_driver!['nama'] ?? '-'}'),
                  Text('Plat: ${_driver!['plat_towing'] ?? '-'}'),
                  Text('Telepon: ${_driver!['telepon'] ?? '-'}'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
