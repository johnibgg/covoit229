import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'config.dart';
import 'theme.dart';
import 'models.dart';
import 'services.dart';
import 'screens_publish.dart';
import 'screens_trip.dart';
import 'screens_profile.dart';

// Coque principale : 4 onglets (Rechercher, Publier, Mes trajets, Profil).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const SearchScreen(),
      const PublishScreen(),
      const MyTripsScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        backgroundColor: Colors.white,
        indicatorColor: CvColors.green.withOpacity(0.15),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: "Rechercher"),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: "Publier"),
          NavigationDestination(icon: Icon(Icons.route), label: "Mes trajets"),
          NavigationDestination(icon: Icon(Icons.person_outline), label: "Profil"),
        ],
      ),
    );
  }
}

// ---- Recherche de trajets ----
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String? from;
  String? to;
  bool loading = true;
  String? error;
  List<Trip> trips = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await Db.searchTrips(from: from, to: to);
      if (mounted) setState(() => trips = res);
    } catch (e) {
      if (mounted) setState(() => error = "Impossible de charger. Vérifie ta connexion.");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Covoit229 🚗")),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Container(
              color: CvColors.navy,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CityPicker(
                          hint: "Départ",
                          value: from,
                          onChanged: (v) {
                            setState(() => from = v);
                            load();
                          },
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward, color: Colors.white70),
                      ),
                      Expanded(
                        child: CityPicker(
                          hint: "Arrivée",
                          value: to,
                          onChanged: (v) {
                            setState(() => to = v);
                            load();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(error!, textAlign: TextAlign.center),
              )
            else if (trips.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Text("🛣️", style: TextStyle(fontSize: 40)),
                    SizedBox(height: 8),
                    Text(
                      "Aucun trajet pour cette recherche.\nÉlargis les villes, ou publie le tien !",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              )
            else
              ...trips.map((t) => TripCard(
                    trip: t,
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => TripDetailScreen(trip: t)))
                        .then((_) => load()),
                  )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class CityPicker extends StatelessWidget {
  final String hint;
  final String? value;
  final ValueChanged<String?> onChanged;
  const CityPicker({super.key, required this.hint, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(hintText: hint),
      items: [
        DropdownMenuItem<String?>(value: null, child: Text("$hint (toutes)")),
        ...kCities.map((c) => DropdownMenuItem<String?>(value: c, child: Text(c))),
      ],
      onChanged: onChanged,
    );
  }
}

String fmtDate(DateTime d) {
  final now = DateTime.now();
  final df = DateFormat("EEE d MMM · HH:mm", "fr_FR");
  final sameDay = d.year == now.year && d.month == now.month && d.day == now.day;
  if (sameDay) return "Aujourd'hui · ${DateFormat.Hm().format(d)}";
  return df.format(d);
}

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  const TripCard({super.key, required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final recurring = trip.recurringDays.isNotEmpty;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "${trip.fromCity} → ${trip.toCity}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: CvColors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      trip.contribLabel,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: CvColors.greenDark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                recurring
                    ? "🔁 ${trip.recurringDays.map((d) => kWeekDays[d - 1]).join(', ')} · ${DateFormat.Hm().format(trip.departAt)}"
                    : "🗓️ ${fmtDate(trip.departAt)}",
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.black45),
                  const SizedBox(width: 4),
                  Text(trip.driver?.fullName ?? "Conducteur",
                      style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  const Spacer(),
                  Text(
                    "${trip.seatsLeft} place${trip.seatsLeft > 1 ? 's' : ''} libre${trip.seatsLeft > 1 ? 's' : ''}",
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: CvColors.navy),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Mes trajets (conducteur + passager) ----
class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  bool loading = true;
  List<Trip> asDriver = [];
  List<Booking> asPassenger = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final t = await Db.myTrips();
      final b = await Db.myBookings();
      if (mounted) {
        setState(() {
          asDriver = t;
          asPassenger = b;
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Mes trajets"),
          bottom: const TabBar(
            indicatorColor: CvColors.green,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: "🚗 Je conduis"),
              Tab(text: "🙋 Je suis passager"),
            ],
          ),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  RefreshIndicator(
                    onRefresh: load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        if (asDriver.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Text("Tu n'as pas encore publié de trajet.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black54)),
                          ),
                        ...asDriver.map((t) => TripCard(
                              trip: t,
                              onTap: () => Navigator.of(context)
                                  .push(MaterialPageRoute(
                                      builder: (_) => TripDetailScreen(trip: t)))
                                  .then((_) => load()),
                            )),
                      ],
                    ),
                  ),
                  RefreshIndicator(
                    onRefresh: load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        if (asPassenger.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Text("Aucune réservation pour l'instant.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black54)),
                          ),
                        ...asPassenger.where((b) => b.trip != null).map((b) => Card(
                              child: ListTile(
                                title: Text(
                                    "${b.trip!.fromCity} → ${b.trip!.toCity}",
                                    style:
                                        const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text(
                                    "${fmtDate(b.trip!.departAt)}\n${b.seats} place${b.seats > 1 ? 's' : ''} · ${b.statusLabel}"),
                                isThreeLine: true,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.of(context)
                                    .push(MaterialPageRoute(
                                        builder: (_) =>
                                            TripDetailScreen(trip: b.trip!)))
                                    .then((_) => load()),
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
