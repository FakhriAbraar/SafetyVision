import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Hasil pengambilan lokasi: koordinat + alamat hasil reverse-geocode.
class ReportLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String subLocality;

  const ReportLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.subLocality,
  });
}

/// Dilempar ketika izin lokasi ditolak / layanan lokasi mati.
class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => message;
}

class LocationService {
  /// Meminta izin lokasi, memastikan GPS aktif, lalu mengambil posisi
  /// terkini beserta alamat (reverse geocoding). Lemparkan [LocationException]
  /// dengan pesan yang ramah jika gagal.
  static Future<ReportLocation> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        'Layanan lokasi (GPS) tidak aktif. Aktifkan terlebih dahulu.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Izin lokasi ditolak permanen. Aktifkan dari pengaturan aplikasi.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    String address = '${position.latitude.toStringAsFixed(5)}, '
        '${position.longitude.toStringAsFixed(5)}';
    String subLocality = '';

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[
          if ((p.street ?? '').isNotEmpty) p.street!,
          if ((p.subLocality ?? '').isNotEmpty) p.subLocality!,
          if ((p.locality ?? '').isNotEmpty) p.locality!,
        ];
        if (parts.isNotEmpty) address = parts.join(', ');
        subLocality = [
          if ((p.subLocality ?? '').isNotEmpty) 'Kel. ${p.subLocality}',
          if ((p.subAdministrativeArea ?? '').isNotEmpty)
            p.subAdministrativeArea!,
        ].join(', ');
      }
    } catch (_) {
      // Reverse geocoding gagal (mis. offline) — cukup pakai koordinat.
    }

    return ReportLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
      subLocality: subLocality,
    );
  }
}
