import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

class AssetDimension {
  final double width;
  final double depth;
  final double height;

  const AssetDimension({required this.width, required this.depth, required this.height});

  factory AssetDimension.fromJson(Map<String, dynamic> json) {
    return AssetDimension(
      width: (json['width'] as num).toDouble(),
      depth: (json['depth'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'width': width,
    'depth': depth,
    'height': height,
  };
}

enum RoomType { kitchen, bedroom, living, climate, bathroom }

enum NoteTheme { KIDS, YOUNG, PRO }

enum NoteMood { joy, fear }

class GhostNote {
  final String id;
  final String furnitureId;
  final String content;
  final String authorName;
  final String authorAvatar; // IconData codepoint o String key
  final NoteTheme theme;
  final NoteMood mood;
  final double fontSize;
  final Color neonColor;
  final DateTime createdAt;
  final DateTime? lastReadAt;
  final bool isRead;
  final bool isActive;

  GhostNote({
    required this.id,
    required this.furnitureId,
    required this.content,
    required this.authorName,
    required this.authorAvatar,
    required this.theme,
    this.mood = NoteMood.joy,
    required this.fontSize,
    required this.neonColor,
    required this.createdAt,
    this.lastReadAt,
    this.isRead = false,
    this.isActive = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'furniture_id': furnitureId,
    'content': content,
    'author_name': authorName,
    'author_avatar': authorAvatar,
    'theme': theme.name,
    'mood': mood.name,
    'font_size': fontSize,
    'neon_color': neonColor.value,
    'created_at': createdAt.toIso8601String(),
    'last_read_at': lastReadAt?.toIso8601String(),
    'is_read': isRead,
    'is_active': isActive,
  };

  factory GhostNote.fromJson(Map<String, dynamic> json) {
    return GhostNote(
      id: json['id'] ?? '',
      furnitureId: json['furniture_id'] ?? '',
      content: json['content'] ?? '',
      authorName: json['author_name'] ?? 'Invitado',
      authorAvatar: json['author_avatar'] ?? 'person',
      theme: _parseNoteTheme(json['theme']),
      mood: _parseNoteMood(json['mood']),
      fontSize: (json['font_size'] as num?)?.toDouble() ?? 14.0,
      neonColor: Color(json['neon_color'] as int? ?? 0xFF00FFFF),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      lastReadAt: json['last_read_at'] != null ? DateTime.parse(json['last_read_at']) : null,
      isRead: json['is_read'] ?? false,
      isActive: json['is_active'] ?? false,
    );
  }

  static NoteTheme _parseNoteTheme(String? themeStr) {
    if (themeStr == null) return NoteTheme.PRO;
    try {
      return NoteTheme.values.byName(themeStr);
    } catch (_) {
      return NoteTheme.PRO;
    }
  }

  static NoteMood _parseNoteMood(String? moodStr) {
    if (moodStr == null) return NoteMood.joy;
    try {
      return NoteMood.values.byName(moodStr);
    } catch (_) {
      return NoteMood.joy;
    }
  }

  GhostNote copyWith({
    String? content,
    String? authorName,
    String? authorAvatar,
    NoteTheme? theme,
    NoteMood? mood,
    double? fontSize,
    Color? neonColor,
    DateTime? lastReadAt,
    bool? isRead,
    bool? isActive,
  }) {
    return GhostNote(
      id: id,
      furnitureId: furnitureId,
      content: content ?? this.content,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      theme: theme ?? this.theme,
      mood: mood ?? this.mood,
      fontSize: fontSize ?? this.fontSize,
      neonColor: neonColor ?? this.neonColor,
      createdAt: createdAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      isRead: isRead ?? this.isRead,
      isActive: isActive ?? this.isActive,
    );
  }
}

class FurnitureAsset {
  final String id;
  final String name;
  final Vector3 position; // Posición 3D (X, Y, Z)
  final int zIndex;
  final int rotation; // 0, 90, 180, 270
  final AssetDimension dimensions;
  final IconData icon;
  final Color color;
  final String? videoPath; 
  bool hasUnreadNotes; 
  final String? spriteUrl; 
  final String? modelPath; // Ruta al archivo .obj
  final bool isAnchored; // Paso Cero: ¿Ya fue calibrado en la realidad?
  final String? initialPhotoPath; // Foto de referencia del primer anclaje
  final List<GhostNote> notes;

  FurnitureAsset({
    required this.id,
    required this.name,
    required this.position,
    required this.zIndex,
    this.rotation = 0,
    required this.dimensions,
    required this.icon,
    required this.color,
    this.videoPath,
    this.hasUnreadNotes = false,
    this.spriteUrl,
    this.modelPath,
    this.isAnchored = false,
    this.initialPhotoPath,
    this.notes = const [],
  });

  bool get isSynced => videoPath != null;

  FurnitureAsset copyWith({
    Vector3? position,
    int? zIndex,
    int? rotation,
    String? videoPath,
    bool? hasUnreadNotes,
    String? spriteUrl,
    String? modelPath,
    bool? isAnchored,
    String? initialPhotoPath,
    List<GhostNote>? notes,
  }) {
    return FurnitureAsset(
      id: id,
      name: name,
      position: position ?? this.position,
      zIndex: zIndex ?? this.zIndex,
      rotation: rotation ?? this.rotation,
      dimensions: dimensions,
      icon: icon,
      color: color,
      videoPath: videoPath ?? this.videoPath,
      hasUnreadNotes: hasUnreadNotes ?? this.hasUnreadNotes,
      spriteUrl: spriteUrl ?? this.spriteUrl,
      modelPath: modelPath ?? this.modelPath,
      isAnchored: isAnchored ?? this.isAnchored,
      initialPhotoPath: initialPhotoPath ?? this.initialPhotoPath,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'pos_x': position.x,
    'pos_y': position.y,
    'pos_z': position.z,
    'z_index': zIndex,
    'rotation': rotation,
    'dimensions': dimensions.toJson(),
    'color': color.value,
    'video_path': videoPath,
    'has_unread_notes': hasUnreadNotes,
    'sprite_url': spriteUrl,
    'model_path': modelPath,
    'is_anchored': isAnchored,
    'initial_photo_path': initialPhotoPath,
    'notes': notes.map((n) => n.toJson()).toList(),
  };

  factory FurnitureAsset.fromJson(Map<String, dynamic> json) {
    return FurnitureAsset(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      position: Vector3(
        (json['pos_x'] as num?)?.toDouble() ?? 0.0,
        (json['pos_y'] as num?)?.toDouble() ?? 0.0,
        (json['pos_z'] as num?)?.toDouble() ?? 0.0,
      ),
      zIndex: json['z_index'] ?? 0,
      rotation: json['rotation'] ?? 0,
      dimensions: json['dimensions'] != null 
          ? AssetDimension.fromJson(json['dimensions'])
          : const AssetDimension(width: 1, depth: 1, height: 1),
      icon: Icons.help_outline, // Valor por defecto ya que IconData no se serializa fácil
      color: Color(json['color'] as int? ?? 0xFFFFFFFF),
      videoPath: json['video_path'],
      hasUnreadNotes: json['has_unread_notes'] ?? false,
      spriteUrl: json['sprite_url'],
      modelPath: json['model_path'],
      isAnchored: json['is_anchored'] ?? false,
      initialPhotoPath: json['initial_photo_path'],
      notes: (json['notes'] as List? ?? []).map((n) => GhostNote.fromJson(n)).toList(),
    );
  }
}

class Room {
  final String id;
  final String floorLevel;
  final RoomType type;
  final List<FurnitureAsset> assets;
  final String? targetSSID;
  final int? targetRSSI;
  final String? ownerName;
  final String? ownerAvatar;
  final bool isShared;

  Room({
    required this.id,
    required this.floorLevel,
    required this.type,
    required this.assets,
    this.targetSSID,
    this.targetRSSI,
    this.ownerName,
    this.ownerAvatar,
    this.isShared = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'floor_level': floorLevel,
    'type': type.index,
    'assets': assets.map((a) => a.toJson()).toList(),
    'ssid': targetSSID,
    'rssi': targetRSSI,
    'owner_name': ownerName,
    'owner_avatar': ownerAvatar,
    'is_shared': isShared,
  };

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] ?? (json['room_id'] ?? ''),
      floorLevel: json['floor_level'] ?? 'PB',
      type: _parseRoomType(json),
      assets: (json['assets'] as List? ?? []).map((a) => FurnitureAsset.fromJson(a)).toList(),
      targetSSID: json['ssid'] ?? json['target_ssid'],
      targetRSSI: json['rssi'] ?? json['target_rssi'],
      ownerName: json['owner_name'],
      ownerAvatar: json['owner_avatar'],
      isShared: json['is_shared'] ?? false,
    );
  }

  static RoomType _parseRoomType(Map<String, dynamic> json) {
    if (json['type'] != null) {
      int index = json['type'] as int;
      if (index >= 0 && index < RoomType.values.length) {
        return RoomType.values[index];
      }
    }
    
    if (json['room_type'] != null) {
      String typeStr = json['room_type'];
      try {
        return RoomType.values.firstWhere((e) => e.toString().split('.').last == typeStr);
      } catch (_) {
        return RoomType.bedroom;
      }
    }
    
    return RoomType.bedroom;
  }

  Room copyWith({
    String? floorLevel,
    RoomType? type,
    List<FurnitureAsset>? assets,
    String? targetSSID,
    int? targetRSSI,
    String? ownerName,
    String? ownerAvatar,
    bool? isShared,
  }) {
    return Room(
      id: id,
      floorLevel: floorLevel ?? this.floorLevel,
      type: type ?? this.type,
      assets: assets ?? this.assets,
      targetSSID: targetSSID ?? this.targetSSID,
      targetRSSI: targetRSSI ?? this.targetRSSI,
      ownerName: ownerName ?? this.ownerName,
      ownerAvatar: ownerAvatar ?? this.ownerAvatar,
      isShared: isShared ?? this.isShared,
    );
  }
}
