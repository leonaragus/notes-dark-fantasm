import 'package:sensors_plus/sensors_plus.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'room_models.dart';

class SensorPreCheckService {
  static Future<Map<String, dynamic>> runFullCheck() async {
    final results = <String, dynamic>{
      'gyroscope': false,
      'storage': false,
      'light': 0.0,
      'ready': false,
      'errors': <String>[],
    };

    // 1. Giroscopio check
    try {
      final gyroEvent = await gyroscopeEventStream().first.timeout(const Duration(seconds: 1));
      results['gyroscope'] = true;
    } catch (e) {
      results['errors'].add('Giroscopio no detectado o desactivado.');
    }

    // 2. Almacenamiento check (Mínimo 100MB libres para video)
    try {
      final directory = await getTemporaryDirectory();
      // En Flutter no hay forma nativa directa sin plugins pesados de ver el espacio libre exacto,
      // pero verificamos permisos de escritura básicos.
      final testFile = File('${directory.path}/test_write.tmp');
      await testFile.writeAsString('test');
      await testFile.delete();
      results['storage'] = true;
    } catch (e) {
      results['errors'].add('Error de acceso al almacenamiento.');
    }

    // 3. Luz Ambiental (Simulado vía CameraController si está disponible)
    // Nota: El sensor de luz nativo requiere plugins adicionales (light), 
    // usaremos un placeholder de detección básica de exposición.
    results['light'] = 1.0; // Placeholder OK

    results['ready'] = results['gyroscope'] && results['storage'];
    
    return results;
  }
}

class RoomPackage {
  final String roomId;
  final String roomName;
  final String videoPath;
  final List<GyroData> rotationData;
  final List<WifiFingerprint> wifiMap;
  final List<Map<String, dynamic>> furnitureLayout;
  final List<GhostNote> notes;
  final double offsetDegrees;
  final String? targetSSID; // SSID principal de la red familiar
  final int? targetRSSI;    // Intensidad de referencia para detección de sala
  final List<String> collaboratorIds; // IDs de usuarios que han reforzado la calibración

  RoomPackage({
    required this.roomId,
    required this.roomName,
    required this.videoPath,
    required this.rotationData,
    required this.wifiMap,
    required this.furnitureLayout,
    this.notes = const [],
    this.offsetDegrees = 0.0,
    this.targetSSID,
    this.targetRSSI,
    this.collaboratorIds = const [],
  });

  Map<String, dynamic> toJson() => {
    'room_id': roomId,
    'room_name': roomName,
    'video_path': videoPath,
    'rotation_data': rotationData.map((e) => e.toJson()).toList(),
    'wifi_map': wifiMap.map((e) => e.toJson()).toList(),
    'furniture_layout': furnitureLayout,
    'notes': notes.map((e) => e.toJson()).toList(),
    'offset_degrees': offsetDegrees,
    'target_ssid': targetSSID,
    'target_rssi': targetRSSI,
    'collaborator_ids': collaboratorIds,
    'timestamp': DateTime.now().toIso8601String(),
  };

  factory RoomPackage.fromJson(Map<String, dynamic> json) {
    return RoomPackage(
      roomId: json['room_id'] ?? '',
      roomName: json['room_name'] ?? 'Sin nombre',
      videoPath: json['video_path'] ?? '',
      rotationData: (json['rotation_data'] as List?)
          ?.map((e) => GyroData.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      wifiMap: (json['wifi_map'] as List?)
          ?.map((e) => WifiFingerprint.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      furnitureLayout: List<Map<String, dynamic>>.from(json['furniture_layout'] ?? []),
      notes: (json['notes'] as List? ?? [])
          .map((e) => GhostNote.fromJson(e as Map<String, dynamic>))
          .toList(),
      offsetDegrees: (json['offset_degrees'] as num?)?.toDouble() ?? 0.0,
      targetSSID: json['target_ssid'],
      targetRSSI: json['target_rssi'],
      collaboratorIds: List<String>.from(json['collaborator_ids'] ?? []),
    );
  }

  RoomPackage copyWith({
    String? roomId,
    String? roomName,
    String? videoPath,
    List<GyroData>? rotationData,
    List<WifiFingerprint>? wifiMap,
    List<Map<String, dynamic>>? furnitureLayout,
    List<GhostNote>? notes,
    double? offsetDegrees,
    String? targetSSID,
    int? targetRSSI,
    List<String>? collaboratorIds,
  }) {
    return RoomPackage(
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      videoPath: videoPath ?? this.videoPath,
      rotationData: rotationData ?? this.rotationData,
      wifiMap: wifiMap ?? this.wifiMap,
      furnitureLayout: furnitureLayout ?? this.furnitureLayout,
      notes: notes ?? this.notes,
      offsetDegrees: offsetDegrees ?? this.offsetDegrees,
      targetSSID: targetSSID ?? this.targetSSID,
      targetRSSI: targetRSSI ?? this.targetRSSI,
      collaboratorIds: collaboratorIds ?? this.collaboratorIds,
    );
  }
}

class GyroData {
  final double x;
  final double y;
  final double z;
  final int timestamp;

  GyroData(this.x, this.y, this.z, this.timestamp);

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'z': z, 'ts': timestamp};

  factory GyroData.fromJson(Map<String, dynamic> json) {
    return GyroData(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
      (json['z'] as num).toDouble(),
      json['ts'] as int,
    );
  }
}

class WifiFingerprint {
  final String ssid;
  final int level;
  final int timestamp;

  WifiFingerprint(this.ssid, this.level, this.timestamp);

  Map<String, dynamic> toJson() => {'ssid': ssid, 'level': level, 'ts': timestamp};

  factory WifiFingerprint.fromJson(Map<String, dynamic> json) {
    return WifiFingerprint(
      json['ssid'] as String,
      json['level'] as int,
      json['ts'] as int,
    );
  }
}
