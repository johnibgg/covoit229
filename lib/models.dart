// Modèles de données Covoit229.

class Profile {
  final String id;
  final String fullName;
  // Le numéro n'est PLUS chargé avec le profil (confidentialité) : il est
  // révélé à la demande via Db.partnerPhone() seulement entre partenaires
  // d'un trajet confirmé. Reste nullable pour compat.
  final String? phone;
  final bool isDriver;
  final String? vehicle;
  final String? photoUrl;

  Profile({
    required this.id,
    required this.fullName,
    this.phone,
    required this.isDriver,
    this.vehicle,
    this.photoUrl,
  });

  // Un profil avec photo = « vérifié » (on voit le visage).
  bool get verified => (photoUrl ?? '').isNotEmpty;

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        fullName: (m['full_name'] ?? '') as String,
        phone: m['phone'] as String?,
        isDriver: (m['is_driver'] ?? false) as bool,
        vehicle: m['vehicle'] as String?,
        photoUrl: m['photo_url'] as String?,
      );
}

class Trip {
  final String id;
  final String driverId;
  final String fromCity;
  final String? fromDetail;
  final String toCity;
  final String? toDetail;
  final DateTime departAt;
  final int seatsTotal;
  final int seatsTaken;
  final String contribType; // free | fuel | fixed | discuss
  final int? contribAmount; // FCFA si fixed
  final String? note;
  final List<int> recurringDays; // 1=lundi … 7=dimanche
  final String status; // open | full | done | cancelled
  final Profile? driver;

  Trip({
    required this.id,
    required this.driverId,
    required this.fromCity,
    this.fromDetail,
    required this.toCity,
    this.toDetail,
    required this.departAt,
    required this.seatsTotal,
    required this.seatsTaken,
    required this.contribType,
    this.contribAmount,
    this.note,
    required this.recurringDays,
    required this.status,
    this.driver,
  });

  int get seatsLeft => seatsTotal - seatsTaken;

  factory Trip.fromMap(Map<String, dynamic> m) => Trip(
        id: m['id'] as String,
        driverId: m['driver_id'] as String,
        fromCity: (m['from_city'] ?? '') as String,
        fromDetail: m['from_detail'] as String?,
        toCity: (m['to_city'] ?? '') as String,
        toDetail: m['to_detail'] as String?,
        departAt: DateTime.parse(m['depart_at'] as String).toLocal(),
        seatsTotal: (m['seats_total'] ?? 0) as int,
        seatsTaken: (m['seats_taken'] ?? 0) as int,
        contribType: (m['contrib_type'] ?? 'discuss') as String,
        contribAmount: m['contrib_amount'] as int?,
        note: m['note'] as String?,
        recurringDays: ((m['recurring_days'] ?? []) as List)
            .map((e) => (e as num).toInt())
            .toList(),
        status: (m['status'] ?? 'open') as String,
        driver: m['cv_profiles'] is Map<String, dynamic>
            ? Profile.fromMap(m['cv_profiles'] as Map<String, dynamic>)
            : null,
      );

  String get contribLabel {
    switch (contribType) {
      case 'free':
        return "🤝 Gratuit / entraide";
      case 'fuel':
        return "⛽ Partage carburant";
      case 'fixed':
        return "💰 ${contribAmount ?? '?'} FCFA";
      default:
        return "💬 À discuter";
    }
  }
}

class Booking {
  final String id;
  final String tripId;
  final String passengerId;
  final int seats;
  final String status; // pending | accepted | rejected | cancelled | done
  final Profile? passenger;
  final Trip? trip;

  Booking({
    required this.id,
    required this.tripId,
    required this.passengerId,
    required this.seats,
    required this.status,
    this.passenger,
    this.trip,
  });

  factory Booking.fromMap(Map<String, dynamic> m) => Booking(
        id: m['id'] as String,
        tripId: m['trip_id'] as String,
        passengerId: m['passenger_id'] as String,
        seats: (m['seats'] ?? 1) as int,
        status: (m['status'] ?? 'pending') as String,
        passenger: m['cv_profiles'] is Map<String, dynamic>
            ? Profile.fromMap(m['cv_profiles'] as Map<String, dynamic>)
            : null,
        trip: m['cv_trips'] is Map<String, dynamic>
            ? Trip.fromMap(m['cv_trips'] as Map<String, dynamic>)
            : null,
      );

  String get statusLabel {
    switch (status) {
      case 'pending':
        return "🕐 En attente";
      case 'accepted':
        return "✅ Acceptée";
      case 'rejected':
        return "❌ Refusée";
      case 'cancelled':
        return "🚫 Annulée";
      case 'done':
        return "🏁 Terminée";
      default:
        return status;
    }
  }
}

class ChatMessage {
  final int id;
  final String tripId;
  final String senderId;
  final String receiverId;
  final String body;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.tripId,
    required this.senderId,
    required this.receiverId,
    required this.body,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
        id: (m['id'] as num).toInt(),
        tripId: m['trip_id'] as String,
        senderId: m['sender_id'] as String,
        receiverId: m['receiver_id'] as String,
        body: (m['body'] ?? '') as String,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      );
}

class Rating {
  final String raterId;
  final String ratedId;
  final int stars;
  final String? comment;
  final Profile? rater;

  Rating({
    required this.raterId,
    required this.ratedId,
    required this.stars,
    this.comment,
    this.rater,
  });

  factory Rating.fromMap(Map<String, dynamic> m) => Rating(
        raterId: m['rater_id'] as String,
        ratedId: m['rated_id'] as String,
        stars: (m['stars'] ?? 0) as int,
        comment: m['comment'] as String?,
        rater: m['cv_profiles'] is Map<String, dynamic>
            ? Profile.fromMap(m['cv_profiles'] as Map<String, dynamic>)
            : null,
      );
}
