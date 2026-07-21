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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x11000000), blurRadius: 16, offset: Offset(0, -4))],
        ),
        child: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: CvColors.green.withOpacity(0.14),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.search_rounded), selectedIcon: Icon(Icons.search_rounded, color: CvColors.greenDark), label: "Rechercher"),
            NavigationDestination(
                icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle, color: CvColors.greenDark), label: "Publier"),
            NavigationDestination(
                icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route, color: CvColors.greenDark), label: "Mes trajets"),
            NavigationDestination(
                icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: CvColors.greenDark), label: "Profil"),
          ],
        ),
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
      backgroundColor: CvColors.bg,
      body: RefreshIndicator(
        onRefresh: load,
        color: CvColors.green,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            // Héro dégradé + carte de recherche
            Container(
              decoration: const BoxDecoration(
                gradient: kHeroGradient,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Salut 👋",
                                  style: TextStyle(color: Colors.white70, fontSize: 13)),
                              SizedBox(height: 2),
                              Text(
                                "Où vas-tu aujourd'hui ?",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                        const CvLogo(size: 42),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SoftCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          CityPicker(
                            hint: "Ville de départ",
                            icon: Icons.trip_origin,
                            iconColor: CvColors.green,
                            value: from,
                            onChanged: (v) {
                              setState(() => from = v);
                              load();
                            },
                          ),
                          const SizedBox(height: 10),
                          CityPicker(
                            hint: "Ville d'arrivée",
                            icon: Icons.location_on,
                            iconColor: CvColors.amber,
                            value: to,
                            onChanged: (v) {
                              setState(() => to = v);
                              load();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Row(
                children: [
                  const Text("Trajets disponibles",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  if (!loading)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: CvColors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${trips.length}",
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: CvColors.greenDark),
                      ),
                    ),
                ],
              ),
            ),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: CvColors.green)),
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
  final IconData icon;
  final Color iconColor;
  final String? value;
  final ValueChanged<String?> onChanged;
  const CityPicker({
    super.key,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.icon = Icons.place,
    this.iconColor = CvColors.green,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: iconColor, size: 20),
      ),
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

Color _contribBg(String type) {
  switch (type) {
    case 'free':
      return const Color(0xFFE0F2F1);
    case 'fuel':
      return const Color(0xFFFFF3D6);
    case 'fixed':
      return const Color(0xFFE1F5E4);
    default:
      return const Color(0xFFE8EAF6);
  }
}

Color _contribFg(String type) {
  switch (type) {
    case 'free':
      return const Color(0xFF00695C);
    case 'fuel':
      return const Color(0xFF9A6B00);
    case 'fixed':
      return CvColors.greenDark;
    default:
      return const Color(0xFF3949AB);
  }
}

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  const TripCard({super.key, required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final recurring = trip.recurringDays.isNotEmpty;
    final dateTxt = recurring
        ? "🔁 ${trip.recurringDays.map((d) => kWeekDays[d - 1]).join(', ')}"
        : DateFormat("d MMM", "fr_FR").format(trip.departAt);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: SoftCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heure + date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat.Hm().format(trip.departAt),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: CvColors.navy),
                        ),
                        const SizedBox(height: 2),
                        Text(dateTxt,
                            style:
                                const TextStyle(fontSize: 11, color: Colors.black45)),
                      ],
                    ),
                    const SizedBox(width: 14),
                    // Ligne de route
                    Column(
                      children: [
                        const SizedBox(height: 4),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                              color: CvColors.green, shape: BoxShape.circle),
                        ),
                        Container(width: 2, height: 22, color: const Color(0xFFDDE5DF)),
                        const Icon(Icons.location_on,
                            size: 14, color: CvColors.amber),
                      ],
                    ),
                    const SizedBox(width: 10),
                    // Villes
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(trip.fromCity,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 14),
                          Text(trip.toCity,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    // Contribution
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _contribBg(trip.contribType),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        trip.contribLabel,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _contribFg(trip.contribType)),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: Color(0xFFEDF1EE)),
                ),
                Row(
                  children: [
                    InitialsAvatar(
                        name: trip.driver?.fullName ?? "?",
                        size: 28,
                        photoUrl: trip.driver?.photoUrl),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              trip.driver?.fullName ?? "Conducteur",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (trip.driver?.verified == true) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, size: 13, color: CvColors.green),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: CvColors.navy.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${trip.seatsLeft} place${trip.seatsLeft > 1 ? 's' : ''}",
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: CvColors.navy),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
            indicatorColor: CvColors.greenBright,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: "🚗 Je conduis"),
              Tab(text: "🙋 Je suis passager"),
            ],
          ),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator(color: CvColors.green))
            : TabBarView(
                children: [
                  RefreshIndicator(
                    onRefresh: load,
                    color: CvColors.green,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 10),
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
                    color: CvColors.green,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      children: [
                        if (asPassenger.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Text("Aucune réservation pour l'instant.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black54)),
                          ),
                        ...asPassenger.where((b) => b.trip != null).map((b) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => Navigator.of(context)
                                      .push(MaterialPageRoute(
                                          builder: (_) =>
                                              TripDetailScreen(trip: b.trip!)))
                                      .then((_) => load()),
                                  child: SoftCard(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                "${b.trip!.fromCity} → ${b.trip!.toCity}",
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15),
                                              ),
                                            ),
                                            Text(b.statusLabel,
                                                style: const TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "${fmtDate(b.trip!.departAt)} · ${b.seats} place${b.seats > 1 ? 's' : ''}",
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
