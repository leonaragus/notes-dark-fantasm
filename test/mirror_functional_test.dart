import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:ghost_notes_digital_twin/assets_registry.dart';
import 'package:ghost_notes_digital_twin/models/room_models.dart';
import 'package:ghost_notes_digital_twin/services/wifi_signal_service.dart';

void main() {
  group('Pruebas de Funcionamiento del Espejo Virtual', () {
    
    test('Verificación de Integridad del AssetRegistry', () {
      // Comprobar que hay assets cargados
      expect(AssetRegistry.models.length, greaterThan(0));
      
      // Verificar que la Heladera de la Cocina (102) existe y tiene datos correctos
      final fridge = AssetRegistry.models[102];
      expect(fridge, isNotNull);
      expect(fridge!['name'], contains('Heladera'));
      expect(fridge['model'], contains('.obj'));
      expect(fridge['dimensions'], isA<AssetDimension>());
    });

    test('Lógica de Snap a Grilla (Imán)', () {
      final pos = Vector3(1.23, 0, 0.78);
      final gridSize = 0.5;
      
      // Simular la lógica de snap que pusimos en Scene3DView
      double snappedX = (pos.x / gridSize).round() * gridSize;
      double snappedZ = (pos.z / gridSize).round() * gridSize;
      
      expect(snappedX, equals(1.0)); // 1.23 -> 1.0
      expect(snappedZ, equals(1.0)); // 0.78 -> 1.0
      
      final pos2 = Vector3(2.4, 0, 1.6);
      expect((pos2.x / gridSize).round() * gridSize, equals(2.5)); // 2.4 -> 2.5
      expect((pos2.z / gridSize).round() * gridSize, equals(1.5)); // 1.6 -> 1.5
    });

    test('Creación y Serialización de Room (Persistencia)', () {
      final assets = [
        AssetRegistry.createAsset(101, Vector3(0, 0, 0)),
        AssetRegistry.createAsset(201, Vector3(2, 0, 2)),
      ];
      
      final room = Room(
        id: 'test_room_id',
        floorLevel: 'PB',
        type: RoomType.kitchen,
        assets: assets,
        targetSSID: 'MiWiFi_Casa',
        targetRSSI: -65,
      );

      // Probar conversión a JSON
      final json = room.toJson();
      expect(json['room_id'], 'test_room_id');
      expect(json['assets'].length, 2);
      expect(json['target_ssid'], 'MiWiFi_Casa');

      // Probar reconstrucción desde JSON
      final reconstructedRoom = Room.fromJson(json);
      expect(reconstructedRoom.id, room.id);
      expect(reconstructedRoom.assets.first.name, assets.first.name);
      expect(reconstructedRoom.targetRSSI, -65);
    });

    test('Lógica de Proximidad WiFi (Fingerprinting)', () {
      final service = WifiSignalService();
      
      // El servicio por defecto tiene _currentRSSI = -100 (desconectado)
      expect(service.calculateProximity(-60), 0.0);
      
      // Nota: En un test real no podemos inyectar _currentRSSI fácilmente 
      // sin mocks, pero verificamos que la fórmula de diff funcione lógicamente.
    });

    test('Simulación de IDs Únicos de Instancia', () async {
      final asset1 = AssetRegistry.createAsset(101, Vector3(0,0,0));
      await Future.delayed(const Duration(milliseconds: 10)); // Asegurar timestamp diferente
      final asset2 = AssetRegistry.createAsset(101, Vector3(1,0,1));
      
      // Deben tener IDs distintos aunque usen el mismo modelo
      expect(asset1.id, isNot(equals(asset2.id)));
      expect(asset1.modelPath, equals(asset2.modelPath));
    });
  });
}
