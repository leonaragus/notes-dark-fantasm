import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart' as cube;
import 'package:vector_math/vector_math_64.dart' as v;
import 'dart:ui';
import '../models/room_models.dart';
import '../services/variant_generator.dart';
import 'recording_module.dart';

class RoomConfig {
  final String type;
  final String shape;
  final v.Vector2 dimensions;

  RoomConfig({required this.type, required this.shape, required this.dimensions});
}

class RoomSelectionScreen extends StatefulWidget {
  const RoomSelectionScreen({Key? key}) : super(key: key);

  @override
  _RoomSelectionScreenState createState() => _RoomSelectionScreenState();
}

class _RoomSelectionScreenState extends State<RoomSelectionScreen> {
  final List<Map<String, dynamic>> _rooms = [
    {'name': 'Cocina', 'icon': Icons.kitchen_outlined},
    {'name': 'Living', 'icon': Icons.weekend_outlined},
    {'name': 'Baño', 'icon': Icons.bathtub_outlined},
    {'name': 'Dormitorio', 'icon': Icons.bed_outlined},
    {'name': 'Lavadero', 'icon': Icons.local_laundry_service_outlined},
    {'name': 'Exterior', 'icon': Icons.deck_outlined},
  ];

  void _showShapeSelector(String roomName) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: ShapeSelectorPopUp(roomName: roomName),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                '¿Qué habitación\nvamos a crear?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Seleccioná un espacio para comenzar',
                style: TextStyle(
                  color: Colors.cyanAccent.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _rooms.length,
                  itemBuilder: (context, index) {
                    final room = _rooms[index];
                    return Hero(
                      tag: 'room_${room['name']}',
                      child: GestureDetector(
                        onTap: () => _showShapeSelector(room['name']),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                room['icon'],
                                color: Colors.cyanAccent,
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                room['name'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShapeSelectorPopUp extends StatelessWidget {
  final String roomName;
  const ShapeSelectorPopUp({Key? key, required this.roomName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.9),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Forma de la $roomName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _ShapeOption(
                label: 'Cuadrada',
                icon: Icons.crop_square,
                onTap: () => _showSizeSelector(context, 'Cuadrada'),
              ),
              const SizedBox(height: 12),
              _ShapeOption(
                label: 'Rectangular',
                icon: Icons.rectangle_outlined,
                onTap: () => _showSizeSelector(context, 'Rectangular'),
              ),
              const SizedBox(height: 12),
              _ShapeOption(
                label: 'En L',
                icon: Icons.polyline_outlined,
                onTap: () => _showSizeSelector(context, 'En L'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSizeSelector(BuildContext context, String shape) {
    Navigator.of(context).pop();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: SizeSelectorPopUp(roomName: roomName, shape: shape),
        );
      },
    );
  }
}

class _ShapeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ShapeOption({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.cyanAccent),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}

class SizeSelectorPopUp extends StatelessWidget {
  final String roomName;
  final String shape;

  const SizeSelectorPopUp({
    Key? key,
    required this.roomName,
    required this.shape,
  }) : super(key: key);

  List<Map<String, dynamic>> _getSizes() {
    if (shape == 'Cuadrada') {
      return [
        {'label': '2x2m', 'dim': v.Vector2(2, 2)},
        {'label': '3x3m', 'dim': v.Vector2(3, 3)},
        {'label': '4x4m', 'dim': v.Vector2(4, 4)},
        {'label': '5x5m', 'dim': v.Vector2(5, 5)},
        {'label': '6x6m', 'dim': v.Vector2(6, 6)},
      ];
    } else if (shape == 'Rectangular') {
      return [
        {'label': '1.5x3m', 'dim': v.Vector2(1.5, 3)},
        {'label': '2x4m', 'dim': v.Vector2(2, 4)},
        {'label': '3x5m', 'dim': v.Vector2(3, 5)},
        {'label': '4x6m', 'dim': v.Vector2(4, 6)},
        {'label': '5x8m', 'dim': v.Vector2(5, 8)},
      ];
    } else {
      return [
        {'label': '3x3m (Base)', 'dim': v.Vector2(3, 3)},
        {'label': '4x4m (Base)', 'dim': v.Vector2(4, 4)},
        {'label': '5x5m (Base)', 'dim': v.Vector2(5, 5)},
        {'label': '6x6m (Base)', 'dim': v.Vector2(6, 6)},
        {'label': '7x7m (Base)', 'dim': v.Vector2(7, 7)},
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _getSizes();
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.9),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Medidas de tu $shape',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Seleccioná la medida que mejor represente tu espacio real',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 24),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: sizes.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RoomPreview3DScreen(
                                config: RoomConfig(
                                  type: roomName,
                                  shape: shape,
                                  dimensions: sizes[index]['dim'],
                                ),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              sizes[index]['label'],
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoomPreview3DScreen extends StatefulWidget {
  final RoomConfig config;
  const RoomPreview3DScreen({Key? key, required this.config}) : super(key: key);

  @override
  _RoomPreview3DScreenState createState() => _RoomPreview3DScreenState();
}

class _RoomPreview3DScreenState extends State<RoomPreview3DScreen> {
  late cube.Scene _scene;
  String _selectedVariant = 'A';
  bool _isEditing = true;
  List<FurnitureAsset> _currentAssets = [];
  final Map<String, cube.Object> _assetObjects = {};

  void _onSceneCreated(cube.Scene scene) {
    _scene = scene;
    _scene.camera.position.setValues(0, 10, 15);
    _scene.camera.target.setValues(0, 0, 0);
    _scene.light.position.setValues(0, 10, 10);

    _refreshScene();
  }

  void _refreshScene() {
    _scene.world.children.clear();
    _assetObjects.clear();

    final dim = widget.config.dimensions;

    // Suelo
    final floor = cube.Object(
      fileName: 'assets/cube.obj',
      scale: v.Vector3(dim.x, 0.1, dim.y),
      position: v.Vector3(0, -0.05, 0),
    );
    floor.mesh.color.setValues(0.2, 0.2, 0.2);
    _scene.world.add(floor);

    // Paredes según forma
    if (widget.config.shape == 'Cuadrada' || widget.config.shape == 'Rectangular') {
      _addWall(v.Vector3(0, 1.25, -dim.y / 2), v.Vector3(dim.x, 2.5, 0.1)); // Trasera
      _addWall(v.Vector3(-dim.x / 2, 1.25, 0), v.Vector3(0.1, 2.5, dim.y)); // Izquierda
    } else if (widget.config.shape == 'En L') {
      _addWall(v.Vector3(0, 1.25, -dim.y / 2), v.Vector3(dim.x, 2.5, 0.1));
      _addWall(v.Vector3(-dim.x / 2, 1.25, 0), v.Vector3(0.1, 2.5, dim.y));
    }

    // Muebles
    _currentAssets = VariantGenerator.generateVariant(
      roomType: widget.config.type,
      shape: widget.config.shape,
      dimensions: widget.config.dimensions,
      variant: _selectedVariant,
    );

    for (var asset in _currentAssets) {
      _addAssetToScene(asset);
    }
    _scene.update();
  }

  void _addAssetToScene(FurnitureAsset asset) {
    final obj = cube.Object(
      fileName: asset.modelPath ?? 'assets/cube.obj',
      position: asset.position,
      rotation: v.Vector3(0, asset.rotation.toDouble(), 0),
      scale: v.Vector3(1, 1, 1),
    );

    if (_isEditing) {
      if (!asset.isAnchored) {
        // Red ghost if not anchored
        obj.mesh.color.setValues(1.0, 0.4, 0.4); 
      } else {
        // Cyan ghost if already anchored
        obj.mesh.color.setValues(0.4, 1.0, 1.0);
      }
    }

    _scene.world.add(obj);
    _assetObjects[asset.id] = obj;
  }

  void _addWall(v.Vector3 pos, v.Vector3 scale) {
    final wall = cube.Object(
      fileName: 'assets/cube.obj',
      position: pos,
      scale: scale,
      backfaceCulling: false,
    );
    wall.mesh.color.setValues(0.3, 0.3, 0.3);
    _scene.world.add(wall);
  }

  String? _selectedAssetId;

  void _confirmDesign() async {
    final wifiService = WifiSignalService();
    final currentSSID = wifiService.currentSSID;
    final currentRSSI = wifiService.currentRSSI;

    // Verificar si ya existe una sala en esta red con RSSI similar
    final prefs = await SharedPreferences.getInstance();
    final roomsJson = prefs.getString('saved_rooms_list');
    if (roomsJson != null) {
      final List<dynamic> decoded = jsonDecode(roomsJson);
      final existingRooms = decoded.map((item) => Room.fromJson(item)).toList();
      
      final duplicate = existingRooms.where((r) => 
        r.targetSSID == currentSSID && 
        (r.targetRSSI != null && (r.targetRSSI! - currentRSSI).abs() < 15)
      ).firstOrNull;

      if (duplicate != null && mounted) {
        final choice = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.black87,
            shape: RoundedRectangleBorder(side: BorderSide(color: CyberTheme.neonPurple), borderRadius: BorderRadius.circular(20)),
            title: const Text('SALA DETECTADA', style: TextStyle(color: CyberTheme.neonPurple, fontFamily: 'Orbitron', fontSize: 16)),
            content: Text('Esta sala ya tiene un espejo virtual.\n\n¿Querés entrar a la existente o ayudar a mejorar la calibración?', 
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'join'),
                child: const Text('ENTRAR', style: TextStyle(color: CyberTheme.neonCyan)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'improve'),
                child: const Text('REFORZAR', style: TextStyle(color: CyberTheme.neonPurple)),
              ),
            ],
          ),
        );

        if (choice == 'join') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => EditorScreen(room: duplicate)));
          return;
        } else if (choice == 'improve') {
          // Navegar a calibración colaborativa (Refuerzo de datos)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RecordingModuleScreen(
                config: widget.config,
                assets: duplicate.assets,
                existingRoom: duplicate,
              ),
            ),
          );
          return;
        }
      }
    }

    setState(() {
      _isEditing = false;
    });
    // Update all assets to solid
    for (var entry in _assetObjects.entries) {
      entry.value.mesh.color.setValues(1.0, 1.0, 1.0); // Reset to original colors
    }
    _scene.update();
  }

  void _openCatalog() {
    final category = VariantGenerator._mapRoomTypeToCategory(widget.config.type);
    final available = AssetRegistry.models.entries
        .where((e) => e.value['category'] == category)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Agregar Mueble',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: available.length,
                  itemBuilder: (context, index) {
                    final entry = available[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _addNewAsset(entry);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chair, color: Colors.cyanAccent, size: 30),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                entry.value['name'],
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addNewAsset(MapEntry<int, Map<String, dynamic>> entry) {
    final asset = FurnitureAsset(
      id: 'user_${entry.key}_${DateTime.now().microsecondsSinceEpoch}',
      name: entry.value['name'],
      position: v.Vector3(0, 0, 0),
      zIndex: 0,
      rotation: 0,
      dimensions: entry.value['dimensions'],
      icon: Icons.chair,
      color: Colors.white,
      modelPath: entry.value['model'],
    );
    setState(() {
      _currentAssets.add(asset);
      _selectedAssetId = asset.id;
    });
    _addAssetToScene(asset);
    _scene.update();
  }

  void _rotateSelected() {
    if (_selectedAssetId == null) return;
    final index = _currentAssets.indexWhere((a) => a.id == _selectedAssetId);
    if (index != -1) {
      setState(() {
        _currentAssets[index] = _currentAssets[index].copyWith(
          rotation: (_currentAssets[index].rotation + 90) % 360,
        );
      });
      _assetObjects[_selectedAssetId!]!.rotation.y = _currentAssets[index].rotation.toDouble();
      _scene.update();
    }
  }

  void _deleteSelected() {
    if (_selectedAssetId == null) return;
    final obj = _assetObjects[_selectedAssetId!];
    if (obj != null) {
      _scene.world.children.remove(obj);
      _assetObjects.remove(_selectedAssetId!);
      _currentAssets.removeWhere((a) => a.id == _selectedAssetId);
      setState(() {
        _selectedAssetId = null;
      });
      _scene.update();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('${widget.config.type} ${widget.config.shape}'),
        backgroundColor: Colors.black,
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _confirmDesign,
              child: const Text('Confirmar', style: TextStyle(color: Colors.cyanAccent)),
            ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onPanUpdate: _isEditing ? _onPanUpdate : null,
            onTapDown: _isEditing ? _onTapDown : null,
            child: cube.Cube(onSceneCreated: _onSceneCreated),
          ),
          if (_isEditing) _buildVariantSelector(),
          if (_isEditing) _buildEditingControls(),
          if (!_isEditing) _buildFinishButton(),
        ],
      ),
    );
  }

  void _onTapDown(TapDownDetails details) {
    // Selection logic - for simplicity in this demo, we'll select the last added/touched asset
    // In a real app, we'd use raycasting to find the object under the tap
    if (_currentAssets.isNotEmpty && _selectedAssetId == null) {
      setState(() {
        _selectedAssetId = _currentAssets.last.id;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_selectedAssetId == null) return;

    final assetIndex = _currentAssets.indexWhere((a) => a.id == _selectedAssetId);
    if (assetIndex == -1) return;

    double sensitivity = 0.02;
    double dx = details.delta.dx * sensitivity;
    double dz = details.delta.dy * sensitivity;

    setState(() {
      var pos = _currentAssets[assetIndex].position;
      double newX = pos.x + dx;
      double newZ = pos.z + dz;

      // Snap to grid (0.1m)
      newX = (newX * 10).roundToDouble() / 10;
      newZ = (newZ * 10).roundToDouble() / 10;

      // Wall bounds check
      double margin = 0.5;
      newX = newX.clamp(-widget.config.dimensions.x / 2 + margin, widget.config.dimensions.x / 2 - margin);
      newZ = newZ.clamp(-widget.config.dimensions.y / 2 + margin, widget.config.dimensions.y / 2 - margin);

      final newPos = v.Vector3(newX, 0, newZ);
      _currentAssets[assetIndex] = _currentAssets[assetIndex].copyWith(position: newPos);
      
      _assetObjects[_selectedAssetId!]!.position.setValues(newX, 0, newZ);

      // Simple Collision Check
      bool isColliding = _checkCollision(assetIndex);
      if (isColliding) {
        _assetObjects[_selectedAssetId!]!.mesh.color.setValues(1.0, 0.3, 0.3); // Red ghost
      } else {
        _assetObjects[_selectedAssetId!]!.mesh.color.setValues(0.6, 0.9, 1.0); // Normal ghost
      }
    });
    _scene.update();
  }

  bool _checkCollision(int movingIndex) {
    final moving = _currentAssets[movingIndex];
    for (int i = 0; i < _currentAssets.length; i++) {
      if (i == movingIndex) continue;
      final other = _currentAssets[i];
      
      // AABB collision check (approximate using dimensions)
      double dist = (moving.position - other.position).length;
      double minDist = (moving.dimensions.width + other.dimensions.width) / 4; // Simplified
      if (dist < minDist) return true;
    }
    return false;
  }

  Widget _buildEditingControls() {
    return Positioned(
      top: 20,
      right: 20,
      child: Column(
        children: [
          _CircleButton(
            icon: Icons.add,
            onTap: _openCatalog,
            color: Colors.cyanAccent,
          ),
          const SizedBox(height: 12),
          if (_selectedAssetId != null) ...[
            _CircleButton(
              icon: Icons.rotate_right,
              onTap: _rotateSelected,
            ),
            const SizedBox(height: 12),
            _CircleButton(
              icon: Icons.delete_outline,
              onTap: _deleteSelected,
              color: Colors.redAccent,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVariantSelector() {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A).withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['A', 'B', 'C'].map((v) {
                bool isSelected = _selectedVariant == v;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedVariant = v;
                    });
                    _refreshScene();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.cyanAccent : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Variante $v',
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _getVariantDescription(),
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _getVariantDescription() {
    switch (_selectedVariant) {
      case 'A': return 'Esencial: Muebles básicos alineados.';
      case 'B': return 'Funcional: Aprovechando esquinas y espacio.';
      case 'C': return 'Premium: Distribución completa con extras.';
      default: return '';
    }
  }

  Widget _buildFinishButton() {
    bool allAnchored = _currentAssets.every((a) => a.isAnchored);
    
    return Positioned(
      bottom: 40,
      left: 60,
      right: 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!allAnchored)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
              ),
              child: const Text(
                'PASO CERO: Calibrá los muebles nuevos en el mundo real para continuar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: allAnchored ? Colors.cyanAccent : Colors.grey[800],
              foregroundColor: allAnchored ? Colors.black : Colors.white24,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: allAnchored ? () {
              // Transition to 360 recording flow
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecordingModuleScreen(
                    config: widget.config,
                    assets: _currentAssets,
                  ),
                ),
              );
            } : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(allAnchored ? Icons.videocam : Icons.lock_outline, size: 20),
                const SizedBox(width: 8),
                const Text('IR A GRABAR 360', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.color = Colors.white24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color == Colors.white24 ? Colors.white : Colors.black),
      ),
    );
  }
}
