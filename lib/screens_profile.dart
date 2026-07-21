import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  String? photoUrl;
  bool uploadingPhoto = false;
  List<Rating> ratings = [];
  bool loading = true;
  final nameC = TextEditingController();
  final vehicleC = TextEditingController();
  final cniC = TextEditingController();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      me = await Db.myProfile();
      myPhone = await Db.myPhone();
      photoUrl = me?.photoUrl;
      cniC.text = await Db.myCni() ?? '';
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
      if (cniC.text.trim().isNotEmpty) {
        await Db.setCni(cniC.text.trim());
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("✅ Profil mis à jour.")));
      }
    } catch (_) {}
  }

  Future<void> changePhoto() async {
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 70,
      );
      if (x == null) return;
      setState(() => uploadingPhoto = true);
      final bytes = await x.readAsBytes();
      final ext = x.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      final url = await Db.uploadAvatar(bytes, ext: ext);
      if (!mounted) return;
      setState(() {
        uploadingPhoto = false;
        if (url != null) photoUrl = url;
      });
      if (url == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Échec de l'envoi de la photo. Réessaie.")));
      }
    } catch (_) {
      if (mounted) setState(() => uploadingPhoto = false);
    }
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
                Center(
                  child: Stack(
                    children: [
                      InitialsAvatar(
                        name: nameC.text.isEmpty ? (me?.fullName ?? "?") : nameC.text,
                        size: 96,
                        photoUrl: photoUrl,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: InkWell(
                          onTap: uploadingPhoto ? null : changePhoto,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                                color: CvColors.green, shape: BoxShape.circle),
                            child: uploadingPhoto
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.photo_camera,
                                    size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: uploadingPhoto ? null : changePhoto,
                    icon: const Icon(Icons.photo_camera, size: 16),
                    label: Text((photoUrl ?? '').isEmpty
                        ? "Ajouter ma photo"
                        : "Changer ma photo"),
                  ),
                ),
                Center(
                  child: (photoUrl ?? '').isEmpty
                      ? const Text("📸 Ajoute ta photo pour rassurer et obtenir le badge vérifié.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black45))
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 16, color: CvColors.green),
                            SizedBox(width: 4),
                            Text("Profil vérifié",
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: CvColors.greenDark)),
                          ],
                        ),
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 12),
                TextField(
                  controller: cniC,
                  decoration: const InputDecoration(
                    labelText: "N° pièce d'identité (CNI/passeport) — privé",
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "🔒 Ton numéro et ta pièce d'identité restent privés : ils ne sont communiqués qu'à un partenaire dont la réservation est acceptée (sécurité anti-arnaque/enlèvement).",
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
