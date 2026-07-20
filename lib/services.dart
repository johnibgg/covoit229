import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

final supa = Supabase.instance.client;

// Le téléphone sert d'identifiant : on le convertit en pseudo-email interne
// (pas de SMS à payer, connexion simple par numéro + mot de passe).
String phoneToEmail(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  return "u$digits@covoit229.app";
}

class Db {
  static String get uid => supa.auth.currentUser?.id ?? '';

  // ---- Auth ----
  static Future<void> signUp({
    required String phone,
    required String password,
    required String fullName,
  }) async {
    final res = await supa.auth.signUp(
      email: phoneToEmail(phone),
      password: password,
    );
    final user = res.user;
    if (user == null) {
      throw Exception("Inscription impossible. Réessaie.");
    }
    await supa.from('cv_profiles').upsert({
      'id': user.id,
      'full_name': fullName.trim(),
      'phone': phone.trim(),
    });
  }

  static Future<void> signIn({
    required String phone,
    required String password,
  }) async {
    await supa.auth.signInWithPassword(
      email: phoneToEmail(phone),
      password: password,
    );
  }

  static Future<void> signOut() => supa.auth.signOut();

  // ---- Profils ----
  static Future<Profile?> myProfile() async {
    if (uid.isEmpty) return null;
    final rows = await supa.from('cv_profiles').select().eq('id', uid).limit(1);
    if (rows.isEmpty) return null;
    return Profile.fromMap(rows.first);
  }

  static Future<void> updateProfile({String? fullName, String? vehicle, bool? isDriver}) async {
    final patch = <String, dynamic>{};
    if (fullName != null) patch['full_name'] = fullName;
    if (vehicle != null) patch['vehicle'] = vehicle;
    if (isDriver != null) patch['is_driver'] = isDriver;
    if (patch.isEmpty) return;
    await supa.from('cv_profiles').update(patch).eq('id', uid);
  }

  // ---- Trajets ----
  static Future<List<Trip>> searchTrips({String? from, String? to}) async {
    var q = supa
        .from('cv_trips')
        .select('*, cv_profiles!cv_trips_driver_id_fkey(*)')
        .eq('status', 'open')
        .gte('depart_at', DateTime.now().toUtc().subtract(const Duration(hours: 2)).toIso8601String());
    if (from != null && from.isNotEmpty) q = q.eq('from_city', from);
    if (to != null && to.isNotEmpty) q = q.eq('to_city', to);
    final rows = await q.order('depart_at', ascending: true).limit(60);
    return (rows as List).map((m) => Trip.fromMap(m as Map<String, dynamic>)).toList();
  }

  static Future<List<Trip>> myTrips() async {
    final rows = await supa
        .from('cv_trips')
        .select('*, cv_profiles!cv_trips_driver_id_fkey(*)')
        .eq('driver_id', uid)
        .order('depart_at', ascending: false)
        .limit(50);
    return (rows as List).map((m) => Trip.fromMap(m as Map<String, dynamic>)).toList();
  }

  static Future<String> publishTrip(Map<String, dynamic> data) async {
    data['driver_id'] = uid;
    final rows = await supa.from('cv_trips').insert(data).select('id');
    return rows.first['id'] as String;
  }

  static Future<void> updateTrip(String id, Map<String, dynamic> patch) async {
    await supa.from('cv_trips').update(patch).eq('id', id);
  }

  // ---- Réservations ----
  static Future<void> book(String tripId, int seats) async {
    await supa.from('cv_bookings').insert({
      'trip_id': tripId,
      'passenger_id': uid,
      'seats': seats,
    });
  }

  static Future<List<Booking>> tripBookings(String tripId) async {
    final rows = await supa
        .from('cv_bookings')
        .select('*, cv_profiles!cv_bookings_passenger_id_fkey(*)')
        .eq('trip_id', tripId)
        .order('created_at');
    return (rows as List).map((m) => Booking.fromMap(m as Map<String, dynamic>)).toList();
  }

  static Future<List<Booking>> myBookings() async {
    final rows = await supa
        .from('cv_bookings')
        .select('*, cv_trips!cv_bookings_trip_id_fkey(*, cv_profiles!cv_trips_driver_id_fkey(*))')
        .eq('passenger_id', uid)
        .order('created_at', ascending: false)
        .limit(50);
    return (rows as List).map((m) => Booking.fromMap(m as Map<String, dynamic>)).toList();
  }

  static Future<Booking?> myBookingFor(String tripId) async {
    final rows = await supa
        .from('cv_bookings')
        .select()
        .eq('trip_id', tripId)
        .eq('passenger_id', uid)
        .limit(1);
    if ((rows as List).isEmpty) return null;
    return Booking.fromMap(rows.first as Map<String, dynamic>);
  }

  static Future<void> setBookingStatus(Booking b, String status, {Trip? trip}) async {
    await supa.from('cv_bookings').update({'status': status}).eq('id', b.id);
    // Met à jour les places prises côté trajet (fait par le conducteur).
    if (trip != null) {
      int taken = trip.seatsTaken;
      if (status == 'accepted' && b.status != 'accepted') taken += b.seats;
      if ((status == 'rejected' || status == 'cancelled') && b.status == 'accepted') {
        taken -= b.seats;
      }
      if (taken < 0) taken = 0;
      final newStatus = taken >= trip.seatsTotal ? 'full' : 'open';
      await supa.from('cv_trips').update({
        'seats_taken': taken,
        if (trip.status == 'open' || trip.status == 'full') 'status': newStatus,
      }).eq('id', trip.id);
    }
  }

  // ---- Messages ----
  static Stream<List<ChatMessage>> messagesStream(String tripId) {
    return supa
        .from('cv_messages')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .order('created_at', ascending: true)
        .map((rows) => rows.map((m) => ChatMessage.fromMap(m)).toList());
  }

  static Future<void> sendMessage(String tripId, String receiverId, String body) async {
    await supa.from('cv_messages').insert({
      'trip_id': tripId,
      'sender_id': uid,
      'receiver_id': receiverId,
      'body': body,
    });
  }

  // ---- Notations ----
  static Future<void> rate({
    required String tripId,
    required String ratedId,
    required int stars,
    String? comment,
  }) async {
    await supa.from('cv_ratings').upsert({
      'trip_id': tripId,
      'rater_id': uid,
      'rated_id': ratedId,
      'stars': stars,
      'comment': (comment ?? '').trim().isEmpty ? null : comment!.trim(),
    }, onConflict: 'trip_id,rater_id,rated_id');
  }

  static Future<List<Rating>> ratingsFor(String userId) async {
    final rows = await supa
        .from('cv_ratings')
        .select('*, cv_profiles!cv_ratings_rater_id_fkey(*)')
        .eq('rated_id', userId)
        .order('created_at', ascending: false)
        .limit(30);
    return (rows as List).map((m) => Rating.fromMap(m as Map<String, dynamic>)).toList();
  }

  static double avgStars(List<Rating> list) {
    if (list.isEmpty) return 0;
    return list.map((r) => r.stars).reduce((a, b) => a + b) / list.length;
  }
}
