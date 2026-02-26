import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PlanType { free, premium }

class UserSubscription {
  PlanType plan;
  int adsWatchedForUnlock;
  int unlockedObjectsCount;
  int totalAdsWatched;

  UserSubscription({
    this.plan = PlanType.free,
    this.adsWatchedForUnlock = 0,
    this.unlockedObjectsCount = 0,
    this.totalAdsWatched = 0,
  });

  bool get isPremium => plan == PlanType.premium;

  // Límites del plan gratuito
  int get maxRooms => isPremium ? 999 : 1;
  int get baseObjects => 4;
  int get maxObjects => isPremium ? 999 : (baseObjects + unlockedObjectsCount);

  static const String _keyPlan = 'user_plan';
  static const String _keyAdsUnlock = 'ads_watched_unlock';
  static const String _keyUnlockedCount = 'unlocked_objects_count';
  static const String _keyTotalAds = 'total_ads_watched';

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlan, plan.name);
    await prefs.setInt(_keyAdsUnlock, adsWatchedForUnlock);
    await prefs.setInt(_keyUnlockedCount, unlockedObjectsCount);
    await prefs.setInt(_keyTotalAds, totalAdsWatched);
  }

  static Future<UserSubscription> load() async {
    final prefs = await SharedPreferences.getInstance();
    final planStr = prefs.getString(_keyPlan) ?? PlanType.free.name;
    final plan = PlanType.values.byName(planStr);
    
    return UserSubscription(
      plan: plan,
      adsWatchedForUnlock: prefs.getInt(_keyAdsUnlock) ?? 0,
      unlockedObjectsCount: prefs.getInt(_keyUnlockedCount) ?? 0,
      totalAdsWatched: prefs.getInt(_keyTotalAds) ?? 0,
    );
  }

  // Lógica de anuncios
  void watchAdForNote() {
    totalAdsWatched++;
    save();
  }

  bool watchAdForUnlock() {
    adsWatchedForUnlock++;
    totalAdsWatched++;
    if (adsWatchedForUnlock >= 3) {
      adsWatchedForUnlock = 0;
      unlockedObjectsCount++;
      save();
      return true; // Desbloqueó un nuevo objeto
    }
    save();
    return false;
  }

  void upgradeToPremium() {
    plan = PlanType.premium;
    save();
  }
}
