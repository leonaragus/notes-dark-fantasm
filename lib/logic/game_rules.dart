import '../models/subscription_model.dart';

// --- CENTRO DE MANDO PARA LA GAMIFICACIÓN ---
// Aquí se definen todos los límites, recompensas y reglas de negocio.

class GameRules {
  // === LÍMITES DEL PLAN GRATUITO ===
  static const int free_maxRooms = 1;
  static const int free_maxObjectsPerRoom = 4;
  static const int free_notesBeforeAd = 2;

  // === REGLAS DE RECOMPENSAS POR ANUNCIOS ===
  static const int adsRequiredForObjectUnlock = 3;

  // === LÍMITES DEL PLAN PREMIUM ===
  // Usamos números altos para representar "infinito" en la práctica.
  static const int premium_maxRooms = 999;
  static const int premium_maxObjectsPerRoom = 999;

  // === MÉTODOS DE VALIDACIÓN ===

  /// Comprueba si el usuario tiene permitido crear una nueva habitación.
  static bool canCreateMoreRooms(UserSubscription subscription, int currentRoomCount) {
    if (subscription.isPremium) {
      return true; // Premium siempre puede
    }
    return currentRoomCount < free_maxRooms;
  }

  /// Comprueba si el usuario tiene permitido añadir más objetos a una habitación.
  static bool canAddMoreObjects(UserSubscription subscription, int currentObjectCount) {
    if (subscription.isPremium) {
      return true; // Premium siempre puede
    }
    return currentObjectCount < free_maxObjectsPerRoom;
  }

  /// Comprueba si el usuario necesita ver un anuncio para crear la próxima nota.
  static bool requiresAdForNextNote(UserSubscription subscription) {
    if (subscription.isPremium) {
      return false; // Premium nunca necesita
    }
    return subscription.notesCreatedCount >= free_notesBeforeAd;
  }
}
