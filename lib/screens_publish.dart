import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'config.dart';
import 'theme.dart';
import 'services.dart';

class PublishScreen extends StatefulWidget {
  const PublishScreen({super.key});

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  String? from;
  String? to;
  final fromDetailC = TextEditingController();
  final toDetailC = TextEditingController();
  final amountC = TextEditingController();
  final noteC = TextEditingController();
  DateTime departDate = DateTime.now().add(const Duration(hours: 2));
  TimeOfDay departTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 2)));
  int seats = 3;
  String contrib = 'discuss';
  final Set<int> days = {};
  bool busy = false;

  Future<void> pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: departDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (d != null) setState(() => departDate = d);
  }

  Future<void> pickTime() async {
    final t = await showTimePicker(context: context, initialTime: departTime);
    if (t != null) setState(() => departTime = t);
  }

  Future<void> submit() async {
    if (from == null || to == null) {
      msg("Choisis la ville de départ et d'arrivée.");
      return;
    }
    if (from == to) {
      msg("Départ et arrivée doivent être différents.");
      return;
    }
    if (contrib == 'fixed' && (int.tryParse(amountC.text.trim()) ?? 0) <= 0) {
      msg("Indique le montant en FCFA.");
      return;
    }
    final depart = DateTime(
      departDate.year,
      departDate.month,
      departDate.day,
      departTime.hour,
      departTime.minute,
    );
    if (days.isEmpty && depart.isBefore(DateTime.now())) {
      msg("L'heure de départ est déjà passée.");
      return;
    }
    setState(() => busy = true);
    try {
      await Db.publishTrip({
        'from_city': from,
        'from_detail': fromDetailC.text.trim().isEmpty ? null : fromDetailC.text.trim(),
        'to_city': to,
        'to_detail': toDetailC.text.trim().isEmpty ? null : toDetailC.text.trim(),
        'depart_at': depart.toUtc().toIso8601String(),
        'seats_total': seats,
        'contrib_type': contrib,
        'contrib_amount': contrib == 'fixed' ? int.parse(amountC.text.trim()) : null,
        'note': noteC.text.trim().isEmpty ? null : noteC.text.trim(),
        'recurring_days': days.toList()..sort(),
      });
      if (mounted) {
        msg("✅ Trajet publié ! Les passagers peuvent maintenant réserver.");
        setState(() {
          fromDetailC.clear();
          toDetailC.clear();
          noteC.clear();
          amountC.clear();
          days.clear();
        });
      }
    } catch (e) {
      msg("Échec de la publication. Vérifie ta connexion.");
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void msg(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat("EEE d MMMM", "fr_FR");
    return Scaffold(
      appBar: AppBar(title: const Text("Publier un trajet")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: from,
                  isExpanded: true,
                  decoration: const InputDecoration(hintText: "Ville de départ"),
                  items: kCities
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => from = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: to,
                  isExpanded: true,
                  decoration: const InputDecoration(hintText: "Ville d'arrivée"),
                  items: kCities
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => to = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: fromDetailC,
            decoration: const InputDecoration(
                hintText: "Point de départ (quartier, repère) — ex : Étoile Rouge"),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: toDetailC,
            decoration:
                const InputDecoration(hintText: "Point d'arrivée — ex : carrefour Sèyivè"),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: pickDate,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(df.format(departDate)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: pickTime,
                  icon: const Icon(Icons.schedule),
                  label: Text(departTime.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text("🔁 Trajet régulier ? Coche les jours (optionnel) :",
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: List.generate(7, (i) {
              final d = i + 1;
              final sel = days.contains(d);
              return FilterChip(
                label: Text(kWeekDays[i]),
                selected: sel,
                selectedColor: CvColors.green.withOpacity(0.2),
                onSelected: (_) =>
                    setState(() => sel ? days.remove(d) : days.add(d)),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text("Places disponibles :",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                onPressed: seats > 1 ? () => setState(() => seats--) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text("$seats", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              IconButton(
                onPressed: seats < 8 ? () => setState(() => seats++) : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text("🤝 Contribution demandée :",
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Column(
            children: [
              contribTile('free', "🤝 Gratuit / entraide",
                  "Je rends service, rien en échange."),
              contribTile('fuel', "⛽ Partage carburant",
                  "On partage le prix de l'essence entre nous."),
              contribTile('fixed', "💰 Montant fixe",
                  "Je fixe une contribution par place."),
              contribTile('discuss', "💬 À discuter",
                  "On s'entend directement : argent, service rendu…"),
            ],
          ),
          if (contrib == 'fixed')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                controller: amountC,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(hintText: "Montant par place (FCFA) — ex : 500"),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: noteC,
            maxLines: 2,
            decoration: const InputDecoration(
                hintText: "Note (optionnel) — ex : je pars de Calavi après le travail"),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: busy ? null : submit,
            child: Text(busy ? "Publication…" : "🚀 Publier le trajet"),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget contribTile(String key, String title, String sub) {
    final sel = contrib == key;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: sel ? CvColors.green : Colors.transparent, width: 2),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        trailing: sel
            ? const Icon(Icons.check_circle, color: CvColors.green)
            : const Icon(Icons.circle_outlined, color: Colors.black26),
        onTap: () => setState(() => contrib = key),
      ),
    );
  }
}
