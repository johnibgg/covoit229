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
  bool hidePass = true;
  String? error;
  final phoneC = TextEditingController();
  final passC = TextEditingController();
  final nameC = TextEditingController();

  Future<void> submit() async {
    final phone = phoneC.text.trim();
    final pass = passC.text;
    setState(() => error = null);
    if (phone.replaceAll(RegExp(r'[^0-9]'), '').length < 8) {
      setState(() => error = "Entre un numéro valide (ex : 01 97 00 00 00).");
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
      body: Container(
        decoration: const BoxDecoration(gradient: kHeroGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CvLogo(size: 64),
                  const SizedBox(height: 10),
                  const Text(
                    "Covoit229",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "On partage la route, on partage les frais 🇧🇯",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  SoftCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          signup ? "Créer un compte" : "Bon retour 👋",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 16),
                        if (signup) ...[
                          TextField(
                            controller: nameC,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: "Nom complet",
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          controller: phoneC,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: "Numéro de téléphone (WhatsApp)",
                            prefixIcon: Icon(Icons.phone_iphone),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: passC,
                          obscureText: hidePass,
                          decoration: InputDecoration(
                            hintText: "Mot de passe",
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => hidePass = !hidePass),
                              icon: Icon(
                                hidePass ? Icons.visibility_off : Icons.visibility,
                                color: Colors.black38,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFFD84315), fontSize: 13),
                            ),
                          ),
                        GradientButton(
                          label: busy
                              ? "Un instant…"
                              : signup
                                  ? "Créer mon compte"
                                  : "Se connecter",
                          icon: signup ? Icons.person_add_alt_1 : Icons.login,
                          onPressed: busy ? null : submit,
                        ),
                        TextButton(
                          onPressed: () => setState(() => signup = !signup),
                          child: Text(
                            signup
                                ? "J'ai déjà un compte — se connecter"
                                : "Nouveau ? Créer un compte",
                            style: const TextStyle(
                              color: CvColors.greenDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
