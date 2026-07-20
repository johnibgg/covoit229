// Configuration Covoit229.
// La clé "anon/publishable" Supabase est PUBLIQUE par conception : elle est
// embarquée dans toutes les applis clientes. La sécurité vient des règles RLS.
const String kSupabaseUrl = "https://mrocffviukrykjlcwzak.supabase.co";
const String kSupabaseAnonKey = "sb_publishable_kSyy_fuEOqJJw2djQSCZLA_3xxHK4LR";

// Villes proposées (Bénin). Le champ "détail" reste libre (quartier, repère…).
const List<String> kCities = [
  "Cotonou",
  "Abomey-Calavi",
  "Porto-Novo",
  "Sèmè-Kpodji",
  "Ouidah",
  "Allada",
  "Bohicon",
  "Abomey",
  "Lokossa",
  "Comè",
  "Grand-Popo",
  "Pobè",
  "Kétou",
  "Savè",
  "Dassa-Zoumè",
  "Parakou",
  "Djougou",
  "Natitingou",
  "Kandi",
  "Malanville",
];

const List<String> kWeekDays = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"];
