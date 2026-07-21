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
  final phoneC = TextEditingController(); // n° en inscription, ou email/tél en connexion
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final nameC = TextEditingController();

  bool _validEmail(String s) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s.trim());

  Future<void> submit() async {
    final ident = phoneC.text.trim();
    final pass = passC.text;
    setState(() => error = null);

    if (signup) {
      if (ident.replaceAll(RegExp(r'[^0-9]'), '').length < 8) {
        setState(() => error = "Entre un numéro valide (ex : 01 97 00 00 00).");
        return;
      }
      if (!_validEmail(emailC.text)) {
        setState(() => error = "Entre un email valide (pour récupérer ton mot de passe).");
        return;
      }
      if (nameC.text.trim().length < 2) {
        setState(() => error = "Entre ton nom complet.");
        return;
      }
    } else {
      if (ident.isEmpty) {
        setState(() => error = "Entre ton email ou ton numéro.");
        return;
      }
    }
    if (pass.length < 6) {
      setState(() => error = "Mot de passe : 6 caractères minimum.");
      return;
    }

    setState(() => busy = true);
    try {
      if (signup) {
        await Db.signUp(
          phone: ident,
          email: emailC.text,
          password: pass,
          fullName: nameC.text,
        );
      } else {
        await Db.signIn(identifier: ident, password: pass);
      }
    } catch (e) {
      final msg = e.toString();
      setState(() {
        if (msg.contains("Invalid login")) {
          error = "Identifiant ou mot de passe incorrect.";
        } else if (msg.contains("already registered")) {
          error = "Cet email a déjà un compte. Connecte-toi.";
        } else {
          error = "Échec : vérifie ta connexion et réessaie.";
        }
      });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> forgotPassword() async {
    final c = TextEditingController(
        text: phoneC.text.contains('@') ? phoneC.text.trim() : '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Mot de passe oublié"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Entre l'email de ton compte : on t'envoie un lien pour choisir un nouveau mot de passe.",
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: "ton@email.com"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Envoyer")),
        ],
      ),
    );
    if (ok != true) return;
    if (!_validEmail(c.text)) {
      setState(() => error = "Entre un email valide pour la récupération.");
      return;
    }
    try {
      await Db.sendPasswordReset(c.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("📧 Lien envoyé ! Regarde ta boîte mail (et les spams).")));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Échec de l'envoi. Réessaie.")));
      }
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
                    "On partage la route, on partage les frais",
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
                          keyboardType:
                              signup ? TextInputType.phone : TextInputType.text,
                          decoration: InputDecoration(
                            hintText: signup
                                ? "Numéro de téléphone (WhatsApp)"
                                : "Email ou téléphone",
                            prefixIcon: Icon(
                                signup ? Icons.phone_iphone : Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (signup) ...[
                          TextField(
                            controller: emailC,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: "Email (pour récupérer ton mot de passe)",
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
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
                        if (!signup)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: busy ? null : forgotPassword,
                              style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 4)),
                              child: const Text("Mot de passe oublié ?",
                                  style: TextStyle(fontSize: 13)),
                            ),
                          ),
                        const SizedBox(height: 8),
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

// Écran affiché quand l'utilisateur ouvre le lien « mot de passe oublié ».
class ResetPasswordScreen extends StatefulWidget {
  final VoidCallback onDone;
  const ResetPasswordScreen({super.key, required this.onDone});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final passC = TextEditingController();
  bool busy = false;
  bool hide = true;
  String? error;

  Future<void> save() async {
    if (passC.text.length < 6) {
      setState(() => error = "Mot de passe : 6 caractères minimum.");
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await Db.updatePassword(passC.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Mot de passe mis à jour !")));
      widget.onDone();
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = "Échec — le lien a peut-être expiré. Redemande un lien.";
        });
      }
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
              child: SoftCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Nouveau mot de passe",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passC,
                      obscureText: hide,
                      decoration: InputDecoration(
                        hintText: "Nouveau mot de passe",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => hide = !hide),
                          icon: Icon(hide ? Icons.visibility_off : Icons.visibility,
                              color: Colors.black38, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFFD84315), fontSize: 13)),
                      ),
                    GradientButton(
                      label: busy ? "Un instant…" : "Enregistrer",
                      icon: Icons.check,
                      onPressed: busy ? null : save,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
