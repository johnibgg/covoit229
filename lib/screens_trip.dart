import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';
import 'theme.dart';
import 'models.dart';
import 'services.dart';
import 'screens_home.dart' show fmtDate;
import 'screens_chat.dart';

Future<void> openWhatsApp(BuildContext context, String phone, String text) async {
  var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length == 10 && digits.startsWith('01')) digits = '229$digits';
  if (digits.length == 8) digits = '229$digits';
  final uri = Uri.parse("https://wa.me/$digits?text=${Uri.encodeComponent(text)}");
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Impossible d'ouvrir WhatsApp.")));
  }
}

class TripDetailScreen extends StatefulWidget {
  final Trip trip;
  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late Trip trip;
  Booking? myBooking;
  List<Booking> bookings = [];
  List<Rating> driverRatings = [];
  bool loading = true;
  bool busy = false;

  bool get isDriver => trip.driverId == Db.uid;

  @override
  void initState() {
    super.initState();
    trip = widget.trip;
    load();
  }

  Future<void> load() async {
    try {
      driverRatings = await Db.ratingsFor(trip.driverId);
      if (isDriver) {
        bookings = await Db.tripBookings(trip.id);
      } else {
        myBooking = await Db.myBookingFor(trip.id);
      }
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> reserve() async {
    int seats = 1;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text("Réserver"),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: seats > 1 ? () => setS(() => seats--) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text("$seats place${seats > 1 ? 's' : ''}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              IconButton(
                onPressed:
                    seats < trip.seatsLeft ? () => setS(() => seats++) : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true), child: const Text("Réserver")),
          ],
        ),
      ),
    );
    if (ok != true) return;
    setState(() => busy = true);
    try {
      await Db.book(trip.id, seats);
      await load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("✅ Demande envoyée ! Le conducteur va confirmer.")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Échec — tu as peut-être déjà réservé ce trajet.")));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> rateUser(String ratedId, String name) async {
    int stars = 5;
    final commentC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text("Noter $name"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final n = i + 1;
                  return IconButton(
                    onPressed: () => setS(() => stars = n),
                    icon: Icon(n <= stars ? Icons.star : Icons.star_border,
                        color: CvColors.amber, size: 30),
                  );
                }),
              ),
              TextField(
                controller: commentC,
                decoration: const InputDecoration(hintText: "Commentaire (optionnel)"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true), child: const Text("Envoyer")),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await Db.rate(
          tripId: trip.id, ratedId: ratedId, stars: stars, comment: commentC.text);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("⭐ Merci pour ton avis !")));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final avg = Db.avgStars(driverRatings);
    return Scaffold(
      appBar: AppBar(title: Text("${trip.fromCity} → ${trip.toCity}")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        infoRow(Icons.trip_origin,
                            "${trip.fromCity}${trip.fromDetail != null ? ' · ${trip.fromDetail}' : ''}"),
                        const SizedBox(height: 8),
                        infoRow(Icons.location_on,
                            "${trip.toCity}${trip.toDetail != null ? ' · ${trip.toDetail}' : ''}"),
                        const Divider(height: 24),
                        infoRow(
                            Icons.schedule,
                            trip.recurringDays.isNotEmpty
                                ? "🔁 ${trip.recurringDays.map((d) => kWeekDays[d - 1]).join(', ')} — départ ${TimeOfDay.fromDateTime(trip.departAt).format(context)}"
                                : fmtDate(trip.departAt)),
                        const SizedBox(height: 8),
                        infoRow(Icons.event_seat,
                            "${trip.seatsLeft} place${trip.seatsLeft > 1 ? 's' : ''} libre${trip.seatsLeft > 1 ? 's' : ''} sur ${trip.seatsTotal}"),
                        const SizedBox(height: 8),
                        infoRow(Icons.handshake, trip.contribLabel),
                        if (trip.note != null) ...[
                          const SizedBox(height: 8),
                          infoRow(Icons.notes, trip.note!),
                        ],
                      ],
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: CvColors.navy,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(trip.driver?.fullName ?? "Conducteur",
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(driverRatings.isEmpty
                        ? "Pas encore d'avis"
                        : "⭐ ${avg.toStringAsFixed(1)} · ${driverRatings.length} avis"),
                    trailing: trip.driver?.vehicle != null
                        ? Text("🚗 ${trip.driver!.vehicle}",
                            style: const TextStyle(fontSize: 12))
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                if (!isDriver) ...[
                  if (myBooking == null && trip.seatsLeft > 0 && trip.status == 'open')
                    ElevatedButton.icon(
                      onPressed: busy ? null : reserve,
                      icon: const Icon(Icons.event_seat),
                      label: Text(busy ? "Un instant…" : "Réserver ma place"),
                    ),
                  if (myBooking != null)
                    Card(
                      color: CvColors.green.withOpacity(0.08),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text("Ta réservation : ${myBooking!.statusLabel}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final p = trip.driver?.phone;
                            if (p == null || p.isEmpty) return;
                            openWhatsApp(context, p,
                                "Salut ! Je te contacte via Covoit229 pour ton trajet ${trip.fromCity} → ${trip.toCity}.");
                          },
                          icon: const Icon(Icons.chat, color: CvColors.green),
                          label: const Text("WhatsApp"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                  trip: trip,
                                  peerId: trip.driverId,
                                  peerName: trip.driver?.fullName ?? "Conducteur"))),
                          icon: const Icon(Icons.forum_outlined),
                          label: const Text("Chat"),
                        ),
                      ),
                    ],
                  ),
                  if (myBooking != null && (myBooking!.status == 'done' || trip.status == 'done'))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: OutlinedButton.icon(
                        onPressed: () => rateUser(
                            trip.driverId, trip.driver?.fullName ?? "le conducteur"),
                        icon: const Icon(Icons.star, color: CvColors.amber),
                        label: const Text("Noter le conducteur"),
                      ),
                    ),
                ],
                if (isDriver) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text("Demandes de réservation",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  if (bookings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text("Personne n'a encore réservé.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54)),
                    ),
                  ...bookings.map((b) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                        "${b.passenger?.fullName ?? 'Passager'} · ${b.seats} place${b.seats > 1 ? 's' : ''}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  Text(b.statusLabel,
                                      style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  if (b.status == 'pending') ...[
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(0, 38)),
                                      onPressed: () async {
                                        await Db.setBookingStatus(b, 'accepted', trip: trip);
                                        await refreshTrip();
                                      },
                                      child: const Text("Accepter"),
                                    ),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(0, 38)),
                                      onPressed: () async {
                                        await Db.setBookingStatus(b, 'rejected', trip: trip);
                                        await refreshTrip();
                                      },
                                      child: const Text("Refuser"),
                                    ),
                                  ],
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(0, 38)),
                                    onPressed: () {
                                      final p = b.passenger?.phone;
                                      if (p == null || p.isEmpty) return;
                                      openWhatsApp(context, p,
                                          "Salut ! C'est le conducteur Covoit229 pour le trajet ${trip.fromCity} → ${trip.toCity}.");
                                    },
                                    icon: const Icon(Icons.chat, size: 16),
                                    label: const Text("WhatsApp"),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(0, 38)),
                                    onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) => ChatScreen(
                                                trip: trip,
                                                peerId: b.passengerId,
                                                peerName: b.passenger?.fullName ??
                                                    "Passager"))),
                                    icon: const Icon(Icons.forum_outlined, size: 16),
                                    label: const Text("Chat"),
                                  ),
                                  if (b.status == 'accepted' && trip.status == 'done')
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(0, 38)),
                                      onPressed: () => rateUser(b.passengerId,
                                          b.passenger?.fullName ?? "le passager"),
                                      icon: const Icon(Icons.star,
                                          size: 16, color: CvColors.amber),
                                      label: const Text("Noter"),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )),
                  const SizedBox(height: 8),
                  if (trip.status == 'open' || trip.status == 'full')
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await Db.updateTrip(trip.id, {'status': 'done'});
                              await refreshTrip();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text(
                                        "🏁 Trajet terminé — vous pouvez vous noter mutuellement.")));
                              }
                            },
                            child: const Text("🏁 Terminer"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await Db.updateTrip(trip.id, {'status': 'cancelled'});
                              await refreshTrip();
                            },
                            child: const Text("🚫 Annuler"),
                          ),
                        ),
                      ],
                    ),
                ],
                const SizedBox(height: 12),
                if (driverRatings.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text("Avis sur le conducteur",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  ...driverRatings.take(5).map((r) => Card(
                        child: ListTile(
                          leading: Text("${'⭐' * r.stars}",
                              style: const TextStyle(fontSize: 12)),
                          title: Text(r.comment ?? "—",
                              style: const TextStyle(fontSize: 14)),
                          subtitle: Text(r.rater?.fullName ?? ""),
                        ),
                      )),
                ],
                const SizedBox(height: 30),
              ],
            ),
    );
  }

  Future<void> refreshTrip() async {
    try {
      final rows = await supa
          .from('cv_trips')
          .select('*, cv_profiles!cv_trips_driver_id_fkey(*)')
          .eq('id', trip.id)
          .limit(1);
      if ((rows as List).isNotEmpty) {
        trip = Trip.fromMap(rows.first as Map<String, dynamic>);
      }
    } catch (_) {}
    await load();
    if (mounted) setState(() {});
  }

  Widget infoRow(IconData ic, String txt) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(ic, size: 18, color: CvColors.greenDark),
        const SizedBox(width: 8),
        Expanded(child: Text(txt, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}
