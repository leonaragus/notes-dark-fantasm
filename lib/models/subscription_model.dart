import 'package:shared_preferences/shared_preferences.dart';
import '../logic/game_rules.dart';

enum PlanType { free, premium }

class UserSubscription {
  PlanType plan;
  int notesCreatedCount;
  int adsWatchedForUnlock; // <-- CAMPO RESTAURADO
  int totalAdsWatched;

  UserSubscription({
    this.plan = PlanType.free,
    this.notesCreatedCount = 0,
    this.adsWatchedForUnlock = 0, // <-- CAMPO RESTAURADO
    this.totalAdsWatched = 0,
  });

  bool get isPremium => plan == PlanType.premium;

  // Claves para SharedPreferences
  static const String _keyPlan = 'user_plan';
  static const String _keyNotesCount = 'notes_created_count';
  static const String _keyAdsForUnlock = 'ads_watched_for_unlock'; // <-- CAMPO RESTAURADO
  static const String _keyTotalAds = 'total_ads_watched';

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlan, plan.name);
    await prefs.setInt(_keyNotesCount, notesCreatedCount);
    await prefs.setInt(_keyAdsForUnlock, adsWatchedForUnlock); // <-- CAMPO RESTAURADO
    await prefs.setInt(_keyTotalAds, totalAdsWatched);
  }

  static Future<UserSubscription> load() async {
    final prefs = await SharedPreferences.getInstance();
    final planStr = prefs.getString(_keyPlan) ?? PlanType.free.name;
    final plan = PlanType.values.byName(planStr);
    
    return UserSubscription(
      plan: plan,
      notesCreatedCount: prefs.getInt(_keyNotesCount) ?? 0,
      adsWatchedForUnlock: prefs.getInt(_keyAdsForUnlock) ?? 0, // <-- CAMPO RESTAURADO
      totalAdsWatched: prefs.getInt(_keyTotalAds) ?? 0,
    );
  }

  void recordNoteCreation() {
    if (!isPremium) {
      notesCreatedCount++;
      save();
    }
  }
  
  void recordAdWatchedForNote() {
    // Reinicia el contador de notas para que las próximas N sean gratis de nuevo.
    notesCreatedCount = 0;
    totalAdsWatched++;
    save();
  }

  // --- MÉTODO RESTAURADO Y MEJORADO ---
  /// Registra que se ha visto un anuncio para desbloquear un objeto.
  /// Devuelve `true` si se ha alcanzado el número de anuncios necesarios.
  bool watchAdForUnlock() {
    totalAdsWatched++;
    adsWatchedForUnlock++;

    if (adsWatchedForUnlock >= GameRules.adsRequiredForObjectUnlock) {
      adsWatchedForUnlock = 0; // Reiniciar para el próximo desbloqueo
      save();
      return true; // ¡Desbloqueado!
    } else {
      save();
      return false; // Aún no es suficiente
    }
  }

  void upgradeToPremium() {
    plan = PlanType.premium;
    save();
  }
}
