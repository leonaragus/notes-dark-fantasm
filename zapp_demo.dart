import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart' as cube;
import 'package:vector_math/vector_math_64.dart' as v;

void main() {
  runApp(const MaterialApp(
    home: ZappDemoScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class ZappDemoScreen extends StatefulWidget {
  const ZappDemoScreen({Key? key}) : super(key: key);

  @override
  _ZappDemoScreenState createState() => _ZappDemoScreenState();
}

class _ZappDemoScreenState extends State<ZappDemoScreen> {
  final List<DemoAsset> _demoAssets = [];

  // Simulador de Red Familiar (SSID y Rooms de otros usuarios)
  static final Map<String, List<Map<String, dynamic>>> _networkRooms = {
    'Casa_Smith_5G': [
      {
        'room_id': 'room_shared_101',
        'room_name': 'Cocina Familiar',
        'type': 0, // kitchen
        'floor': 0,
        'owner_name': 'Papá',
        'owner_avatar': 'account_circle',
        'assets': [
          {
            'id': 'fridge_1',
            'name': 'Heladera',
            'is_anchored': true,
            'notes': [
              {'author': 'Mamá', 'mood': 'joy', 'owner_avatar': 'volunteer_activism'},
              {'author': 'Hijo', 'mood': 'fear', 'owner_avatar': 'esports'}
            ]
          }
        ]
      },
      {
        'room_id': 'room_shared_102',
        'room_name': 'Living Principal',
        'type': 2, // living
        'floor': 0,
        'owner_name': 'Abuelo',
        'owner_avatar': 'volunteer_activism',
        'assets': [
          {
            'id': 'sofa_1',
            'name': 'Sofá Neón',
            'is_anchored': true,
            'notes': [
              {'author': 'Abuelo', 'mood': 'joy', 'owner_avatar': 'volunteer_activism'}
            ]
          }
        ]
      }
    ],
    'TP-Link_Guest': [
      {
        'room_id': 'room_shared_201',
        'room_name': 'Dormitorio Visitas',
        'type': 1, // bedroom
        'floor': 1,
        'owner_name': 'Admin',
        'owner_avatar': 'person',
        'assets': []
      }
    ]
  };

  static Future<List<Map<String, dynamic>>> getSharedRooms(String ssid) async {
    return _networkRooms[ssid] ?? [];
  }

  @override
  void initState() {
    super.initState();
    _setupDemoRoom();
  }

  void _setupDemoRoom() {
    // Simulamos la configuración de la cocina demo
    _demoAssets.add(DemoAsset('fridge', 'Heladera', v.Vector3(-1.5, 0, -1.5), hasNote: true));
    _demoAssets.add(DemoAsset('stove', 'Cocina', v.Vector3(-0.5, 0, -1.5)));
    _demoAssets.add(DemoAsset('cabinet', 'Gabinete', v.Vector3(0.5, 0, -1.5)));
    _demoAssets.add(DemoAsset('microwave', 'Microondas', v.Vector3(0.5, 0.9, -1.5)));
    _demoAssets.add(DemoAsset('bar', 'Barra Cocina', v.Vector3(0, 0, 1.0)));
    _demoAssets.add(DemoAsset('stool1', 'Taburete 1', v.Vector3(-0.5, 0, 1.8)));
    _demoAssets.add(DemoAsset('stool2', 'Taburete 2', v.Vector3(0.5, 0, 1.8), hasNote: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('DEMO GHOST NOTES 3D', 
          style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          Scene3DWidget(assets: _demoAssets),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('CALIDAD DEMO', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text('• Paredes Dinámicas (Sims Style)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('• Pulso Neón en objetos con notas', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('• Rotación automática de inspección', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DemoAsset {
  final String id;
  final String name;
  final v.Vector3 position;
  final bool hasNote;

  DemoAsset(this.id, this.name, this.position, {this.hasNote = false});
}

class Scene3DWidget extends StatefulWidget {
  final List<DemoAsset> assets;
  const Scene3DWidget({Key? key, required this.assets}) : super(key: key);

  @override
  _Scene3DWidgetState createState() => _Scene3DWidgetState();
}

class _Scene3DWidgetState extends State<Scene3DWidget> {
  late cube.Scene _scene;
  final List<cube.Object> _walls = [];
  final Map<String, cube.Object> _models = {};
  Timer? _timer;
  double _angle = 0.0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onSceneCreated(cube.Scene scene) {
    _scene = scene;
    _scene.camera.position.setValues(0, 5, 8);
    _scene.camera.target.setValues(0, 0, 0);
    _scene.light.position.setValues(0, 10, 10);

    // Crear paredes básicas (cubos escalados para la demo)
    final wall1 = cube.Object(
      fileName: 'assets/cube.obj',
      position: v.Vector3(-2.5, 1.25, 0),
      scale: v.Vector3(0.1, 2.5, 5.0),
      backfaceCulling: false,
    );
    _scene.world.add(wall1);
    _walls.add(wall1);

    final wall2 = cube.Object(
      fileName: 'assets/cube.obj',
      position: v.Vector3(0, 1.25, -2.5),
      scale: v.Vector3(5.0, 2.5, 0.1),
      backfaceCulling: false,
    );
    _scene.world.add(wall2);
    _walls.add(wall2);

    // Agregar los assets de la demo
    for (var asset in widget.assets) {
      // El mueble real se mantiene visible al 100%
      final obj = cube.Object(
        fileName: 'assets/cube.obj',
        position: asset.position,
        scale: v.Vector3(0.5, 0.5, 0.5),
        name: asset.id,
      );
      obj.mesh.color.setValues(1.0, 1.0, 1.0); // Opacidad completa
      _scene.world.add(obj);
      _models[asset.id] = obj;

      // Si tiene nota, agregamos el formato correspondiente por edad
      if (asset.hasNote) {
        String modelFile;
        v.Vector3 scale;
        Color neonColor;

        // Simulamos diferentes temas según el asset para la demo
        if (asset.id == 'fridge') {
          modelFile = 'assets/star.obj'; // KIDS
          scale = v.Vector3(0.12, 0.12, 0.12);
          neonColor = Colors.yellowAccent;
        } else if (asset.id == 'stool2') {
          modelFile = 'assets/diamond.obj'; // YOUNG
          scale = v.Vector3(0.15, 0.15, 0.15);
          neonColor = Colors.cyanAccent;
        } else {
          modelFile = 'assets/cube_hollow.obj'; // PRO
          scale = v.Vector3(0.18, 0.18, 0.18);
          neonColor = Colors.purpleAccent;
        }

        final noteObj = cube.Object(
          fileName: modelFile,
          position: v.Vector3(
            asset.position.x,
            asset.position.y + 0.6,
            asset.position.z,
          ),
          scale: scale,
          name: '${asset.id}_note',
        );
        noteObj.mesh.color.setValues(
          neonColor.red / 255,
          neonColor.green / 255,
          neonColor.blue / 255,
        );
        _scene.world.add(noteObj);
        _models['${asset.id}_note'] = noteObj;
      }
    }

    // Iniciar animación
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) return;
      setState(() {
        _angle += 0.01;
        
        // Orbita de cámara
        _scene.camera.position.x = 8 * math.cos(_angle);
        _scene.camera.position.z = 8 * math.sin(_angle);
        _scene.update();

        // Lógica de paredes Sims Style
        for (var wall in _walls) {
          final dot = _scene.camera.position.x * wall.position.x + _scene.camera.position.z * wall.position.z;
          wall.scale.y = dot > 0 ? 0.5 : 2.5;
          wall.position.y = dot > 0 ? 0.25 : 1.25;
        }

        // Movimiento y Pulso Neón
        final time = DateTime.now().millisecondsSinceEpoch / 1000;
        final intensity = (math.sin(time * 3) + 1.0) / 2.0;
        
        for (var asset in widget.assets) {
          if (asset.hasNote && _models.containsKey('${asset.id}_note')) {
            final noteObj = _models['${asset.id}_note']!;
            
            // Movimiento preestablecido (rebote y rotación)
            double bounce = math.sin(time * 2) * 0.05;
            double rotation = math.cos(time) * 0.1;
            
            noteObj.position.y = asset.position.y + 0.6 + bounce;
            noteObj.rotation.y += rotation;

            // Brillo pulsante neón
            final baseColor = noteObj.mesh.color;
            noteObj.mesh.color.setValues(
              baseColor.r * (0.8 + intensity * 0.2),
              baseColor.g * (0.8 + intensity * 0.2),
              baseColor.b * (0.8 + intensity * 0.2),
            );
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return cube.Cube(
      onSceneCreated: _onSceneCreated,
    );
  }
}
