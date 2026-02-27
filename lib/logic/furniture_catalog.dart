import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v;
import '../models/room_models.dart';
import '../assets_library.dart';

class FurnitureCatalog {
  static List<FurnitureAsset> get items => [
    FurnitureAsset(
      id: 'sofa_3_cuerpos',
      name: 'Sofá 3 Cuerpos',
      position: v.Vector3(0, 0, 0),
      zIndex: 1,
      dimensions: const AssetDimension(width: 2.2, depth: 0.9, height: 0.8),
      icon: Icons.weekend,
      color: Colors.blueGrey,
      spriteUrl: AppAssets.getAsset('living', 'sofa'),
    ),
    FurnitureAsset(
      id: 'tv_rack',
      name: 'Rack TV',
      position: v.Vector3(0, 0, 0),
      zIndex: 1,
      dimensions: const AssetDimension(width: 1.8, depth: 0.4, height: 0.5),
      icon: Icons.tv,
      color: Colors.brown,
      spriteUrl: AppAssets.getAsset('living', 'television'),
    ),
    FurnitureAsset(
      id: 'fridge',
      name: 'Heladera',
      position: v.Vector3(0, 0, 0),
      zIndex: 1,
      dimensions: const AssetDimension(width: 0.7, depth: 0.7, height: 1.8),
      icon: Icons.kitchen,
      color: Colors.grey,
      spriteUrl: AppAssets.getAsset('cocina', 'fridge'),
    ),
    FurnitureAsset(
      id: 'table_kitchen',
      name: 'Mesa Cocina',
      position: v.Vector3(0, 0, 0),
      zIndex: 1,
      dimensions: const AssetDimension(width: 1.2, depth: 0.8, height: 0.75),
      icon: Icons.table_restaurant,
      color: Colors.orangeAccent,
      spriteUrl: AppAssets.getAsset('cocina', 'table'),
    ),
    FurnitureAsset(
      id: 'toilet',
      name: 'Inodoro',
      position: v.Vector3(0, 0, 0),
      zIndex: 1,
      dimensions: const AssetDimension(width: 0.4, depth: 0.6, height: 0.4),
      icon: Icons.wc,
      color: Colors.white,
      spriteUrl: AppAssets.getAsset('bano', 'toilet'),
    ),
    FurnitureAsset(
      id: 'bed_double',
      name: 'Cama 2 Plazas',
      position: v.Vector3(0, 0, 0),
      zIndex: 1,
      dimensions: const AssetDimension(width: 1.5, depth: 1.9, height: 0.5),
      icon: Icons.bed,
      color: Colors.indigo,
      spriteUrl: AppAssets.getAsset('dormitorio', 'bed'),
    ),
    FurnitureAsset(
      id: 'wardrobe',
      name: 'Ropero',
      position: v.Vector3(0, 0, 0),
      zIndex: 1,
      dimensions: const AssetDimension(width: 2.0, depth: 0.6, height: 2.1),
      icon: Icons.door_sliding,
      color: Colors.brown,
      spriteUrl: AppAssets.getAsset('dormitorio', 'wardrobe'),
    ),
    FurnitureAsset(
      id: 'nightstand',
      name: 'Mesita de Luz',
      position: v.Vector3(0, 0, 0),
      zIndex: 1,
      dimensions: const AssetDimension(width: 0.5, depth: 0.5, height: 0.45),
      icon: Icons.table_rows,
      color: Colors.blueGrey,
      spriteUrl: AppAssets.getAsset('living', 'table_small'),
    ),
  ];
}
