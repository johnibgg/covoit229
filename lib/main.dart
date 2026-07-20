import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'theme.dart';
import 'screens_auth.dart';
import 'screens_home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonKey);
  runApp(const CovoitApp());
}

class CovoitApp extends StatelessWidget {
  const CovoitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Covoit229',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const AuthGate(),
      // Interface et sélecteurs (date/heure) en français.
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Sur le web desktop, permet aussi de faire défiler en glissant à la souris.
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
        },
      ),
      // Sur grand écran (web desktop), l'appli s'affiche dans un cadre
      // téléphone centré — bien plus élégant que des champs étirés.
      builder: (context, child) {
        return LayoutBuilder(builder: (ctx, c) {
          if (c.maxWidth <= 560) return child ?? const SizedBox();
          final frameH = (c.maxHeight - 40).clamp(480.0, 880.0);
          return ColoredBox(
            color: const Color(0xFF060F1B),
            child: Center(
              child: Container(
                width: 420,
                height: frameH,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(38),
                  border: Border.all(color: const Color(0xFF1E3A5F), width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x5500D24B),
                      blurRadius: 80,
                      spreadRadius: -18,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: child,
                ),
              ),
            ),
          );
        });
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snap) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) return const AuthScreen();
        return const HomeShell();
      },
    );
  }
}
