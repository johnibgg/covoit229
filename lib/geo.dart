// Géolocalisation Covoit229.
// On dérive les coordonnées à partir de la VILLE (pas besoin de stocker de
// lat/lng en base) : chaque trajet a une ville de départ connue.
import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';

import 'models.dart';

// Coordonnées approximatives (lat, lng) des villes proposées dans l'appli.
const Map<String, List<double>> kCityCoords = {
  "Cotonou": [6.3703, 2.3912],
  "Abomey-Calavi": [6.4489, 2.3556],
  "Porto-Novo": [6.4969, 2.6289],
  "Sèmè-Kpodji": [6.3667, 2.6167],
  "Ouidah": [6.3626, 2.0853],
  "Allada": [6.6653, 2.1511],
  "Bohicon": [7.1782, 2.0667],
  "Abomey": [7.1826, 1.9912],
  "Lokossa": [6.6389, 1.7167],
  "Comè": [6.4064, 1.8817],
  "Grand-Popo": [6.2833, 1.8236],
  "Pobè": [6.9800, 2.6650],
  "Kétou": [7.3634, 2.5960],
  "Savè": [8.0342, 2.4864],
  "Dassa-Zoumè": [7.7500, 2.1833],
  "Parakou": [9.3370, 2.6303],
  "Djougou": [9.7085, 1.6660],
  "Natitingou": [10.3042, 1.3796],
  "Kandi": [11.1342, 2.9386],
  "Malanville": [11.8686, 3.3833],
};

double _deg2rad(double d) => d * pi / 180.0;

/// Distance à vol d'oiseau en km entre deux points (formule de haversine).
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = _deg2rad(lat2 - lat1);
  final dLng = _deg2rad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

/// Récupère la position GPS courante. Gère la permission.
/// Renvoie null si le service est coupé, la permission refusée, ou en cas d'erreur.
Future<Position?> currentPosition() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return null;
    }
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    ).timeout(const Duration(seconds: 12));
  } catch (_) {
    return null;
  }
}

/// Ville connue la plus proche d'une position (pour le « départ auto »).
String? nearestCity(double lat, double lng) {
  String? best;
  double bestD = double.infinity;
  kCityCoords.forEach((city, c) {
    final d = haversineKm(lat, lng, c[0], c[1]);
    if (d < bestD) {
      bestD = d;
      best = city;
    }
  });
  return best;
}

/// Distance (km) entre l'utilisateur et la ville de DÉPART d'un trajet.
/// null si la ville n'a pas de coordonnées connues.
double? tripDistanceKm(Trip t, double lat, double lng) {
  final c = kCityCoords[t.fromCity];
  if (c == null) return null;
  return haversineKm(lat, lng, c[0], c[1]);
}
