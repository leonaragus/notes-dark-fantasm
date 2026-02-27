import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart' as cube;
import 'package:vector_math/vector_math_64.dart' as v;
import '../models/room_models.dart';

class Scene3DView extends StatefulWidget {
  final List<FurnitureAsset> assets;
  final Function(FurnitureAsset) onAssetSelected;
  final bool isInspectionMode;

  const Scene3DView({
    Key? key,
    required this.assets,
    required this.onAssetSelected,
    this.isInspectionMode = false,
  }) : super(key: key);

  @override
  _Scene3DViewState createState() => _Scene3DViewState();
}

class _Scene3DViewState extends State<Scene3DView> with SingleTickerProviderStateMixin {
  late cube.Scene _scene;
  final Map<String, cube.Object> _loadedModels = {};
  final List<cube.Object> _walls = [];
  late Timer _orbitTimer;
  double _orbitAngle = 0.0;
  
  // Configuración de Snap
  static const double _gridSize = 0.5;

  @override
  void initState() {
    super.initState();
    if (widget.isInspectionMode) {
      _startOrbit();
    }
  }

  @override
  void dispose() {
    if (widget.isInspectionMode) {
      _orbitTimer.cancel();
    }
    super.dispose();
  }

  void _startOrbit() {
    _orbitTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) return;
      setState(() {
        _orbitAngle += 0.01;
        _updateCameraOrbit();
        _handleWallVisibility();
        _updateNeonPulse();
      });
    });
  }

  void _updateCameraOrbit() {
    final double radius = 8.0;
    final double x = radius * math.cos(_orbitAngle);
    final double z = radius * math.sin(_orbitAngle);
    _scene.camera.position.setValues(x, 5.0, z);
    _scene.camera.target.setFrom(v.Vector3(0, 0, 0));
    _scene.update();
  }

  FurnitureAsset? _selectedAsset;

  void _onSceneCreated(cube.Scene scene) {
    _scene = scene;
    _scene.camera.position.setFrom(v.Vector3(5, 5, 5));
    _scene.camera.target.setFrom(v.Vector3(0, 0, 0));
    
    _scene.light.position.setFrom(v.Vector3(0, 10, 10));
    _scene.light.setColor(Colors.white, 0.8, 0.8, 0.8);

    // Luz ambiental extra para mejor calidad
    _scene.light.setColor(Colors.white, 1.0, 1.0, 1.0);

    _addTestScene();
    _syncAssets();
  }

  void _addTestScene() {
    // Pared 1 (Eje X)
    final wall1 = cube.Object(
      fileName: 'assets/models/wall.obj',
      position: v.Vector3(-2.5, 0, 0),
      scale: v.Vector3(1.0, 1.0, 1.0),
    );
    _scene.world.add(wall1);
    _walls.add(wall1);

    // Pared 2 (Eje Z, en ángulo)
    final wall2 = cube.Object(
      fileName: 'assets/models/wall.obj',
      position: v.Vector3(0, 0, -2.5),
      rotation: v.Vector3(0, 90, 0),
      scale: v.Vector3(1.0, 1.0, 1.0),
    );
    _scene.world.add(wall2);
    _walls.add(wall2);

    // Heladera de prueba (simulamos que tiene una Ghost Note)
    final fridge = cube.Object(
      fileName: 'assets/models/kitchenFridge.obj',
      position: v.Vector3(0, 0, 0),
      scale: v.Vector3(1.0, 1.0, 1.0),
    );
    _scene.world.add(fridge);
    _loadedModels['test_fridge'] = fridge;
  }

  void _handleWallVisibility() {
    // Lógica Sims Style: Si la pared está entre la cámara y el centro, bajar altura
    for (var wall in _walls) {
      final cameraPos = _scene.camera.position;
      final wallPos = wall.position;
      
      // Producto escalar simple para determinar si la pared está "enfrente"
      final dot = cameraPos.x * wallPos.x + cameraPos.z * wallPos.z;
      
      if (dot > 0) {
        // La pared está en el lado de la cámara, reducir altura
        wall.scale.y = 0.3;
      } else {
        wall.scale.y = 1.0;
      }
    }
  }

  void _updateNeonPulse() {
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final pulse = (math.sin(time * 5) + 1.0) / 2.0; // 0.0 a 1.0
    
    // Aplicar pulso a objetos con notas (en el test usamos la heladera)
    if (_loadedModels.containsKey('test_fridge')) {
      final fridge = _loadedModels['test_fridge']!;
      // Simular brillo neón escalando ligeramente o cambiando color si el motor lo permite
      final scale = 1.0 + (pulse * 0.05);
      fridge.scale.setValues(scale, scale, scale);
    }
    
    // También aplicar a assets reales que tengan notas
    for (var asset in widget.assets) {
      if (asset.hasUnreadNotes && _loadedModels.containsKey(asset.id)) {
        final model = _loadedModels[asset.id]!;
        final scale = 1.0 + (pulse * 0.05);
        model.scale.setValues(scale, scale, scale);
      }
    }
  }

  v.Vector3 _snapToGrid(v.Vector3 position) {
    return v.Vector3(
      (position.x / _gridSize).round() * _gridSize,
      position.y, // Mantener altura original (suelo)
      (position.z / _gridSize).round() * _gridSize,
    );
  }

  void _syncAssets() {
    // Limpiar modelos previos si existen
    _loadedModels.clear();
    _scene.world.children.where((child) => !_walls.contains(child) && (child is! cube.Object || (child as cube.Object).fileName != 'assets/models/kitchenFridge.obj')).forEach((child) {
       _scene.world.remove(child);
    });

    for (var asset in widget.assets) {
      if (asset.modelPath != null) {
        final snappedPos = _snapToGrid(asset.position);
        final model = cube.Object(
          fileName: asset.modelPath!,
          position: snappedPos,
          scale: v.Vector3(1.0, 1.0, 1.0),
          rotation: v.Vector3(0, asset.rotation.toDouble(), 0),
          name: asset.id, // Usamos el ID único del asset como nombre del objeto 3D
        );
        _scene.world.add(model);
        _loadedModels[asset.id] = model;
      }
    }
    _scene.update();
  }

  @override
  void didUpdateWidget(Scene3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isInspectionMode != oldWidget.isInspectionMode) {
      if (widget.isInspectionMode) {
        _startOrbit();
      } else {
        _orbitTimer.cancel();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        cube.Cube(
          onSceneCreated: _onSceneCreated,
          onObjectFocused: (cube.Object? object) {
            setState(() {
              if (object != null) {
                final assetId = _loadedModels.entries
                    .firstWhere((e) => e.value == object, orElse: () => MapEntry('', cube.Object()))
                    .key;
                if (assetId.isNotEmpty) {
                  if (assetId != 'test_fridge') {
                    _selectedAsset = widget.assets.firstWhere((a) => a.id == assetId);
                    widget.onAssetSelected(_selectedAsset!);
                  } else {
                    // Seleccionar heladera de prueba (mock)
                    _selectedAsset = FurnitureAsset(
                      id: 'test_fridge',
                      name: 'Heladera (Test)',
                      position: v.Vector3(0, 0, 0),
                      dimensions: const AssetDimension(width: 0.7, depth: 0.7, height: 1.8),
                      icon: Icons.kitchen,
                      color: Colors.white,
                      zIndex: 0,
                    );
                  }
                }
              } else {
                _selectedAsset = null;
              }
            });
          },
        ),
        // HUD - Solo el botón de añadir nota si hay un objeto seleccionado
        if (_selectedAsset != null)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton.extended(
                onPressed: () {
                  // Lógica para añadir nota
                },
                icon: const Icon(Icons.note_add, color: Colors.black),
                label: Text('Añadir Nota a ${_selectedAsset!.name}', 
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.cyanAccent.withOpacity(0.9),
              ),
            ),
          ),
      ],
    );
  }
}
