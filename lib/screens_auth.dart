import 'package:flutter/material.dart';
import 'theme.dart';
import 'services.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool signup = false;
  bool busy = false;
  String? error;
  final phoneC = TextEditingController();
  final passC = TextEditingController();
  final nameC = TextEditingController();

  Future<void> submit() async {
    final phone = phoneC.text.trim();
    final pass = passC.text;
    setState(() => error = null);
    if (phone.replaceAll(RegExp(r'[^0-9]'), '').length < 8) {
      setState(() => error = "Entre un numéro de téléphone valide (ex : 01 97 00 00 00).");
      return;
    }
    if (pass.length < 6) {
      setState(() => error = "Mot de passe : 6 caractères minimum.");
      return;
    }
    if (signup && nameC.text.trim().length < 2) {
      setState(() => error = "Entre ton nom complet.");
      return;
    }
    setState(() => busy = true);
    try {
      if (signup) {
        await Db.signUp(phone: phone, password: pass, fullName: nameC.text);
      } else {
        await Db.signIn(phone: phone, password: pass);
      }
    } catch (e) {
      final msg = e.toString();
      setState(() {
        if (msg.contains("Invalid login")) {
          error = "Numéro ou mot de passe incorrect.";
        } else if (msg.contains("already registered")) {
          error = "Ce numéro a déjà un compte. Connecte-toi.";
        } else {
          error = "Échec : vérifie ta connexion et réessaie.";
        }
      });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CvColors.navy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.directions_car_filled, size: 72, color: CvColors.green),
                const SizedBox(height: 12),
                const Text(
                  "Covoit229",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Le covoiturage solidaire du Bénin 🇧🇯\nOn partage la route, on partage les frais.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 28),
                if (signup) ...[
                  TextField(
                    controller: nameC,
                    decoration: const InputDecoration(hintText: "Nom complet"),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: phoneC,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: "Numéro de téléphone (WhatsApp)"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passC,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: "Mot de passe"),
                ),
                const SizedBox(height: 16),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.orangeAccent)),
                  ),
                ElevatedButton(
                  onPressed: busy ? null : submit,
                  child: Text(busy
                      ? "Un instant…"
                      : signup
                          ? "Créer mon compte"
                          : "Se connecter"),
                ),
                TextButton(
                  onPressed: () => setState(() => signup = !signup),
                  child: Text(
                    signup ? "J'ai déjà un compte — se connecter" : "Nouveau ? Créer un compte",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
