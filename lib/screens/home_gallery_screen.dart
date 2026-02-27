import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/room_models.dart';
import '../theme/cyber_theme.dart';
import 'editor_screen.dart';
import 'splash_screen.dart';
import 'profile_registration_screen.dart';
import '../widgets/scene_3d_view.dart';

import '../services/wifi_signal_service.dart';
import 'package:flutter_cube/flutter_cube.dart' as cube;
import '../zapp_demo.dart';
import '../models/subscription_model.dart';
import 'subscription_screen.dart';

class HomeGalleryScreen extends StatefulWidget {
  const HomeGalleryScreen({Key? key}) : super(key: key);

  @override
  _HomeGalleryScreenState createState() => _HomeGalleryScreenState();
}

class _HomeGalleryScreenState extends State<HomeGalleryScreen> {
  List<Room> _rooms = [];
  List<Room> _sharedRooms = [];
  bool _isLoading = true;
  String _userName = 'Invitado';
  String _userAvatar = 'person';
  int _totalNotesCount = 0;
  String? _currentSSID;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupWifiSync();
  }

  void _setupWifiSync() async {
    final wifiService = WifiSignalService();
    await wifiService.startScanning();
    if (mounted) {
      setState(() {
        _currentSSID = wifiService.currentSSID;
      });
    }
    _loadSharedRooms();
  }

  Future<void> _loadSharedRooms() async {
    if (_currentSSID == null) return;
    
    // Simulación de fetch de red familiar
    final sharedData = await ZappDemo.getSharedRooms(_currentSSID!);
    if (mounted) {
      setState(() {
        _sharedRooms = sharedData.map((data) {
          return Room(
            id: data['room_id'],
            floorLevel: data['floor'],
            type: RoomType.values[data['type']],
            assets: (data['assets'] as List).map((a) {
              return FurnitureAsset(
                id: a['id'],
                name: a['name'],
                position: cube.Vector3(0,0,0), // Placeholder para vista de galería
                zIndex: 0,
                dimensions: const AssetDimension(width: 1, depth: 1, height: 1),
                icon: Icons.chair,
                color: Colors.white,
                isAnchored: a['is_anchored'],
                notes: (a['notes'] as List).map((n) => GhostNote(
                  id: 'n_${DateTime.now().millisecondsSinceEpoch}_${a['id']}',
                  furnitureId: a['id'],
                  content: 'CONTENIDO BLOQUEADO',
                  authorName: n['author'],
                  authorAvatar: n['owner_avatar'] ?? 'person',
                  theme: NoteTheme.PRO,
                  mood: n['mood'] == 'joy' ? NoteMood.joy : NoteMood.fear,
                  fontSize: 14,
                  neonColor: n['mood'] == 'joy' ? CyberTheme.neonGreen : Colors.redAccent,
                  createdAt: DateTime.now(),
                )).toList(),
              );
            }).toList(),
            ownerName: data['owner_name'],
            ownerAvatar: data['owner_avatar'],
            isShared: true,
            targetSSID: _currentSSID,
          );
        }).toList();
      });
    }
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    
    // Cargar Perfil
    final userName = prefs.getString('user_name') ?? 'Invitado';
    final userAvatar = prefs.getString('user_avatar') ?? 'person';

    // Cargar Habitaciones
    final roomsJson = prefs.getString('saved_rooms_list');
    List<Room> loadedRooms = [];
    if (roomsJson != null) {
      final List<dynamic> decoded = jsonDecode(roomsJson);
      loadedRooms = decoded.map((item) => Room.fromJson(item)).toList();
    } else {
      // Migración: Si existe la sala vieja 'saved_room_3d', convertirla
      final oldRoom = prefs.getString('saved_room_3d');
      if (oldRoom != null) {
        final data = jsonDecode(oldRoom);
        final migratedRoom = Room(
          id: 'room_${DateTime.now().millisecondsSinceEpoch}',
          floorLevel: data['floor'] ?? 'PB',
          type: RoomType.values[data['type'] ?? 0],
          assets: (data['assets'] as List).map((a) => FurnitureAsset.fromJson(a)).toList(),
          targetSSID: data['ssid'],
          targetRSSI: data['rssi'],
        );
        loadedRooms = [migratedRoom];
        await _saveRoomsManually(loadedRooms);
      }
    }

    // Calcular notas totales
    int notesCount = 0;
    for (var room in loadedRooms) {
      for (var asset in room.assets) {
        notesCount += asset.notes.length;
      }
    }

    if (mounted) {
      setState(() {
        _userName = userName;
        _userAvatar = userAvatar;
        _rooms = loadedRooms;
        _totalNotesCount = notesCount;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveRoomsManually(List<Room> rooms) async {
    final prefs = await SharedPreferences.getInstance();
    final roomsJson = jsonEncode(rooms.map((r) => r.toJson()).toList());
    await prefs.setString('saved_rooms_list', roomsJson);
  }

  Future<void> _saveRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final roomsJson = jsonEncode(_rooms.map((r) => r.toJson()).toList());
    await prefs.setString('saved_rooms_list', roomsJson);
  }

  Future<void> _createNewRoom() async {
    final subscription = await UserSubscription.load();
    if (!subscription.isPremium && _rooms.length >= subscription.maxRooms) {
      _showUpgradeDialog('HAS ALCANZADO EL LÍMITE DE HABITACIONES.\nACTUALIZA A PREMIUM PARA CREAR ILIMITADAS.');
      return;
    }

    final newRoom = Room(
      id: 'room_${DateTime.now().millisecondsSinceEpoch}',
      floorLevel: 'PB',
      type: RoomType.bedroom,
      assets: [],
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditorScreen(room: newRoom)),
    ).then((_) => _loadData());
  }

  void _showUpgradeDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(side: const BorderSide(color: CyberTheme.neonPurple), borderRadius: BorderRadius.circular(20)),
        title: const Text('ACCESO RESTRINGIDO', style: TextStyle(color: CyberTheme.neonPurple, fontFamily: 'Orbitron', fontSize: 16)),
        content: Text(message, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CyberTheme.neonPurple),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionScreen())).then((_) => _loadData());
            },
            child: const Text('MEJORAR PLAN', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openRoom(Room room) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditorScreen(room: room)),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildNebulaBackground(),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildStatsSummary(),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('MIS MAQUETAS 3D', 
                    style: TextStyle(color: CyberTheme.neonCyan.withOpacity(0.7), fontSize: 12, letterSpacing: 4, fontFamily: 'Orbitron')),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: CyberTheme.neonCyan))
                    : _rooms.isEmpty 
                        ? _buildEmptyState()
                        : _buildRoomGrid(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewRoom,
        backgroundColor: CyberTheme.neonCyan,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildNebulaBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            Color(0xFF0A0015), // Púrpura muy oscuro
            Colors.black,
          ],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.2),
              duration: const Duration(seconds: 8),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Container(
                  width: 500 * value,
                  height: 500 * value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: CyberTheme.neonPurple.withOpacity(0.03 * (2 - value)),
                        blurRadius: 150,
                        spreadRadius: 80,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('HOME HUB', 
            style: TextStyle(fontFamily: 'Orbitron', fontSize: 20, fontWeight: FontWeight.bold, color: CyberTheme.neonGreen, letterSpacing: 2)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.stars, color: CyberTheme.neonPurple),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionScreen())).then((_) => _loadData()),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileRegistrationScreen(isEditing: true)),
                  ).then((_) => _loadData());
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: CyberTheme.neonCyan, width: 2),
                    boxShadow: [
                      BoxShadow(color: CyberTheme.neonCyan.withOpacity(0.3), blurRadius: 8),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.black,
                    child: Icon(_getAvatarIcon(_userAvatar), color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getAvatarIcon(String key) {
    switch (key) {
      case 'child_care': return Icons.child_care;
      case 'rocket': return Icons.rocket_launch;
      case 'account_circle': return Icons.account_circle;
      case 'volunteer_activism': return Icons.volunteer_activism;
      default: return Icons.person;
    }
  }

  Widget _buildStatsSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('GHOST NOTES', _totalNotesCount.toString(), CyberTheme.neonGreen),
            _buildStatItem('HABITACIONES', _rooms.length.toString(), CyberTheme.neonPurple),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.architecture, color: Colors.white24, size: 80),
          const SizedBox(height: 20),
          const Text('NO HAY MAQUETAS AÚN', style: TextStyle(color: Colors.white38, letterSpacing: 2)),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _createNewRoom,
            child: const Text('EMPEZAR DISEÑO', style: TextStyle(color: CyberTheme.neonCyan)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomGrid() {
    final allRooms = [..._rooms, ..._sharedRooms];
    
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.8,
      ),
      itemCount: allRooms.length,
      itemBuilder: (context, index) {
        final room = allRooms[index];
        final hasUnread = room.assets.any((a) => a.hasUnreadNotes || a.notes.isNotEmpty);
        
        return GestureDetector(
          onTap: () => _openRoom(room),
          child: Container(
            decoration: BoxDecoration(
              color: room.isShared ? CyberTheme.neonPurple.withOpacity(0.05) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: room.isShared ? CyberTheme.neonPurple.withOpacity(0.3) : (hasUnread ? CyberTheme.neonGreen.withOpacity(0.5) : Colors.white10),
                width: (hasUnread || room.isShared) ? 2 : 1,
              ),
              boxShadow: hasUnread ? [
                BoxShadow(color: (room.isShared ? CyberTheme.neonPurple : CyberTheme.neonGreen).withOpacity(0.2), blurRadius: 15, spreadRadius: 2)
              ] : [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        // Vista 3D Miniaturizada
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                            ),
                          ),
                          child: IgnorePointer(
                            child: Scene3DView(
                              assets: room.assets,
                              onAssetSelected: (_) {}, // No selección en galería
                              isInspectionMode: false,
                            ),
                          ),
                        ),
                        
                        // Overlay de cristal
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),

                        // Indicador de Dueño (Si es compartida)
                        if (room.isShared)
                          Positioned(
                            top: 10, left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: CyberTheme.neonPurple, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_getAvatarIcon(room.ownerAvatar ?? 'person'), color: CyberTheme.neonPurple, size: 12),
                                  const SizedBox(width: 4),
                                  Text(room.ownerName ?? 'Alguien', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),

                        // Pulso neón si hay mensajes sin leer
                        if (hasUnread)
                          Positioned(
                            top: 15, right: 15,
                            child: _NeonPulseIndicator(color: room.isShared ? CyberTheme.neonPurple : CyberTheme.neonGreen),
                          ),
                        
                        Positioned(
                          bottom: 10,
                          left: 12,
                          child: Icon(_getRoomIcon(room.type), color: CyberTheme.neonCyan.withOpacity(0.5), size: 16),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(room.type.name.toUpperCase(), 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Orbitron', letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(room.isShared ? 'RED: ${_currentSSID ?? 'WIFI'}' : '${room.floorLevel} • ${room.assets.length} obj', 
                              style: const TextStyle(color: Colors.white38, fontSize: 9)),
                            if (hasUnread)
                              Text('NEW', style: TextStyle(color: room.isShared ? CyberTheme.neonPurple : CyberTheme.neonGreen, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getRoomIcon(RoomType type) {
    switch (type) {
      case RoomType.bedroom: return Icons.bed;
      case RoomType.kitchen: return Icons.kitchen;
      case RoomType.living: return Icons.weekend;
      case RoomType.bathroom: return Icons.bathtub;
      default: return Icons.room;
    }
  }
}

class _NeonPulseIndicator extends StatefulWidget {
  final Color color;
  const _NeonPulseIndicator({this.color = CyberTheme.neonGreen});

  @override
  __NeonPulseIndicatorState createState() => __NeonPulseIndicatorState();
}

class __NeonPulseIndicatorState extends State<_NeonPulseIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat();
    _animation = Tween<double>(begin: 0.2, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          boxShadow: [
            BoxShadow(color: widget.color.withOpacity(0.8), blurRadius: 10, spreadRadius: 2),
          ],
        ),
      ),
    );
  }
}
