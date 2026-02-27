import 'package:vector_math/vector_math_64.dart' hide Colors;
import '../models/room_models.dart';
import '../assets_registry.dart';
import 'package:flutter/material.dart';

class VariantGenerator {
  static List<FurnitureAsset> generateVariant({
    required String roomType,
    required String shape,
    required Vector2 dimensions,
    required String variant, // 'A', 'B', 'C'
  }) {
    List<FurnitureAsset> assets = [];
    final category = _mapRoomTypeToCategory(roomType);
    final availableAssets = AssetRegistry.models.entries
        .where((e) => e.value['category'] == category)
        .toList();

    if (availableAssets.isEmpty) return [];

    switch (variant) {
      case 'A':
        assets = _generateVariantA(category, dimensions, availableAssets);
        break;
      case 'B':
        assets = _generateVariantB(category, dimensions, availableAssets);
        break;
      case 'C':
        assets = _generateVariantC(category, dimensions, availableAssets);
        break;
    }

    return assets;
  }

  static String _mapRoomTypeToCategory(String roomType) {
    switch (roomType) {
      case 'Cocina':
        return 'Cocina';
      case 'Living':
        return 'Living';
      case 'Baño':
      case 'Lavadero':
        return 'Baño';
      case 'Dormitorio':
        return 'Dormitorio';
      default:
        return 'Living';
    }
  }

  static List<FurnitureAsset> _generateVariantA(
      String category, Vector2 dim, List<MapEntry<int, Map<String, dynamic>>> available) {
    List<FurnitureAsset> assets = [];
    double wallLength = dim.x > dim.y ? dim.x : dim.y;
    bool isXLonger = dim.x > dim.y;

    if (category == 'Cocina') {
      // Heladera, Mesada (Sink), Cocina
      final fridge = _findAsset(available, 'Heladera');
      final sink = _findAsset(available, 'Lava Platos');
      final stove = _findAsset(available, 'Cocina Gas');

      if (fridge != null) assets.add(_createAt(fridge, _getWallPos(0.5, wallLength, isXLonger, dim, 0.8), 0));
      if (sink != null) assets.add(_createAt(sink, _getWallPos(1.5, wallLength, isXLonger, dim, 0.6), 0));
      if (stove != null) assets.add(_createAt(stove, _getWallPos(2.5, wallLength, isXLonger, dim, 0.6), 0));
    } else if (category == 'Living') {
      final sofa = _findAsset(available, 'Sofá Design');
      final tv = _findAsset(available, 'TV Moderna');
      if (sofa != null) assets.add(_createAt(sofa, _getWallPos(wallLength / 2, wallLength, isXLonger, dim, 0.9), 0));
      if (tv != null) assets.add(_createAt(tv, _getWallPos(wallLength / 2, wallLength, !isXLonger, dim, 0.1, opposite: true), 180));
    } else if (category == 'Dormitorio') {
      final bed = _findAsset(available, 'Cama Doble');
      if (bed != null) assets.add(_createAt(bed, _getWallPos(wallLength / 2, wallLength, isXLonger, dim, 2.0), 0));
    } else if (category == 'Baño') {
      final toilet = _findAsset(available, 'Inodoro Moderno');
      final sink = _findAsset(available, 'Bacha Baño');
      final shower = _findAsset(available, 'Ducha Cuadrada');
      if (shower != null) assets.add(_createAt(shower, _getWallPos(0.5, wallLength, isXLonger, dim, 1.0), 0));
      if (toilet != null) assets.add(_createAt(toilet, _getWallPos(1.5, wallLength, isXLonger, dim, 0.7), 0));
      if (sink != null) assets.add(_createAt(sink, _getWallPos(2.5, wallLength, isXLonger, dim, 0.5), 0));
    }

    return assets;
  }

  static List<FurnitureAsset> _generateVariantB(
      String category, Vector2 dim, List<MapEntry<int, Map<String, dynamic>>> available) {
    List<FurnitureAsset> assets = _generateVariantA(category, dim, available);
    // Add corner elements
    if (category == 'Cocina') {
      final cabinet = _findAsset(available, 'Gabinete Cocina');
      if (cabinet != null) {
        assets.add(_createAt(cabinet, Vector3(-dim.x / 2 + 0.3, 0, -dim.y / 2 + 0.3), 0));
      }
    } else if (category == 'Living') {
      final chair = _findAsset(available, 'Sillón Relax');
      if (chair != null) {
        assets.add(_createAt(chair, Vector3(dim.x / 2 - 0.5, 0, dim.y / 2 - 0.5), 45));
      }
    } else if (category == 'Dormitorio') {
      final desk = _findAsset(available, 'Escritorio');
      if (desk != null) {
        assets.add(_createAt(desk, Vector3(-dim.x / 2 + 0.7, 0, dim.y / 2 - 0.35), 0));
      }
    }
    return assets;
  }

  static List<FurnitureAsset> _generateVariantC(
      String category, Vector2 dim, List<MapEntry<int, Map<String, dynamic>>> available) {
    List<FurnitureAsset> assets = _generateVariantB(category, dim, available);
    // Add premium elements
    if (category == 'Cocina') {
      final island = _findAsset(available, 'Barra Cocina');
      if (island != null) {
        assets.add(_createAt(island, Vector3(0, 0, 0), 0));
      }
    } else if (category == 'Living') {
      final plant = _findAsset(available, 'Planta en Maceta');
      final rug = _findAsset(available, 'Alfombra Rectangular');
      if (rug != null) assets.add(_createAt(rug, Vector3(0, 0.01, 0), 0));
      if (plant != null) assets.add(_createAt(plant, Vector3(dim.x / 2 - 0.4, 0, -dim.y / 2 + 0.4), 0));
    } else if (category == 'Dormitorio') {
      final wardrobe = _findAsset(available, 'Ropero Doble');
      if (wardrobe != null) {
        assets.add(_createAt(wardrobe, Vector3(dim.x / 2 - 0.6, 0, -dim.y / 2 + 0.3), 180));
      }
    }
    return assets;
  }

  static MapEntry<int, Map<String, dynamic>>? _findAsset(
      List<MapEntry<int, Map<String, dynamic>>> available, String name) {
    try {
      return available.firstWhere((e) => e.value['name'].toString().contains(name));
    } catch (_) {
      return null;
    }
  }

  static FurnitureAsset _createAt(MapEntry<int, Map<String, dynamic>> entry, Vector3 pos, int rot) {
    return FurnitureAsset(
      id: 'gen_${entry.key}_${DateTime.now().microsecondsSinceEpoch}',
      name: entry.value['name'],
      position: pos,
      zIndex: 0,
      rotation: rot,
      dimensions: entry.value['dimensions'],
      icon: Icons.chair, // Default icon
      color: Colors.white,
      modelPath: entry.value['model'],
    );
  }

  static Vector3 _getWallPos(double offset, double wallLength, bool isXLonger, Vector2 dim, double depth, {bool opposite = false}) {
    if (isXLonger) {
      double x = -wallLength / 2 + offset;
      double z = opposite ? dim.y / 2 - depth / 2 : -dim.y / 2 + depth / 2;
      return Vector3(x, 0, z);
    } else {
      double z = -wallLength / 2 + offset;
      double x = opposite ? dim.x / 2 - depth / 2 : -dim.x / 2 + depth / 2;
      return Vector3(x, 0, z);
    }
  }
}
