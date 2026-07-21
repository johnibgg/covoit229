import 'package:flutter/material.dart';

import 'theme.dart';
import 'models.dart';
import 'services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Profile? me;
  String? myPhone;
  List<Rating> ratings = [];
  bool loading = true;
  final nameC = TextEditingController();
  final vehicleC = TextEditingController();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      me = await Db.myProfile();
      myPhone = await Db.myPhone();
      if (me != null) {
        nameC.text = me!.fullName;
        vehicleC.text = me!.vehicle ?? '';
        ratings = await Db.ratingsFor(me!.id);
      }
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    try {
      await Db.updateProfile(
        fullName: nameC.text.trim(),
        vehicle: vehicleC.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("✅ Profil mis à jour.")));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final avg = Db.avgStars(ratings);
    return Scaffold(
      appBar: AppBar(title: const Text("Mon profil")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: CvColors.navy,
                  child: Icon(Icons.person, size: 44, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    ratings.isEmpty
                        ? "Pas encore d'avis"
                        : "⭐ ${avg.toStringAsFixed(1)} · ${ratings.length} avis",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameC,
                  decoration: const InputDecoration(labelText: "Nom complet"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: vehicleC,
                  decoration: const InputDecoration(
                      labelText: "Mon véhicule (optionnel) — ex : Toyota Corolla grise"),
                ),
                const SizedBox(height: 12),
                Text("📱 Numéro : ${myPhone ?? '—'}",
                    style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 4),
                const Text(
                  "🔒 Ton numéro reste privé : il n'est communiqué qu'à un partenaire dont la réservation est acceptée.",
                  style: TextStyle(fontSize: 11, color: Colors.black45),
                ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: save, child: const Text("Enregistrer")),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Db.signOut(),
                  child: const Text("Se déconnecter"),
                ),
                const SizedBox(height: 20),
                if (ratings.isNotEmpty) ...[
                  const Text("Mes avis reçus",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...ratings.map((r) => Card(
                        child: ListTile(
                          leading: Text('⭐' * r.stars,
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
}
