import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../models/room_models.dart';
import '../services/wifi_signal_service.dart';

class Isometric3DView extends StatefulWidget {
  final List<FurnitureAsset> assets;
  final RoomType roomType;
  final int? targetRSSI;

  const Isometric3DView({
    Key? key, 
    required this.assets, 
    required this.roomType,
    this.targetRSSI
  }) : super(key: key);

  @override
  _Isometric3DViewState createState() => _Isometric3DViewState();
}

class _Isometric3DViewState extends State<Isometric3DView> with SingleTickerProviderStateMixin {
  late AnimationController _expansionController;
  final WifiSignalService _wifiService = WifiSignalService();
  double _proximity = 0.5;
  Map<String, ui.Image> _sprites = {};

  @override
  void initState() {
    super.initState();
    _expansionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _wifiService.rssiStream.listen((rssi) {
      if (widget.targetRSSI != null && mounted) {
        setState(() {
          _proximity = _wifiService.calculateProximity(widget.targetRSSI!);
        });
      }
    });

    _loadSprites();
  }

  Future<void> _loadSprites() async {
    for (var asset in widget.assets) {
      if (asset.spriteUrl != null && !_sprites.containsKey(asset.spriteUrl)) {
        final image = await _loadImage(asset.spriteUrl!);
        if (image != null) {
          setState(() {
            _sprites[asset.spriteUrl!] = image;
          });
        }
      }
    }
  }

  Future<ui.Image?> _loadImage(String pathOrUrl) async {
    try {
      final ImageProvider provider = pathOrUrl.startsWith('http') 
          ? NetworkImage(pathOrUrl) 
          : AssetImage(pathOrUrl) as ImageProvider;
          
      final ImageStream stream = provider.resolve(ImageConfiguration.empty);
      final Completer<ui.Image> completer = Completer<ui.Image>();
      ImageStreamListener? listener;
      listener = ImageStreamListener((ImageInfo info, bool synchronousCall) {
        completer.complete(info.image);
        stream.removeListener(listener!);
      }, onError: (dynamic exception, StackTrace? stackTrace) {
        completer.completeError(exception);
        stream.removeListener(listener!);
      });
      stream.addListener(listener);
      return await completer.future;
    } catch (e) {
      debugPrint('Error loading sprite: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _expansionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF222222), // Fondo oscuro para resaltar la maqueta
      child: CustomPaint(
        painter: IsometricMaquettePainter(
          assets: widget.assets,
          roomType: widget.roomType,
          proximity: _proximity,
          expansionValue: _expansionController.value,
          sprites: _sprites,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class IsometricMaquettePainter extends CustomPainter {
  final List<FurnitureAsset> assets;
  final RoomType roomType;
  final double proximity;
  final double expansionValue;
  final Map<String, ui.Image> sprites;

  IsometricMaquettePainter({
    required this.assets,
    required this.roomType,
    required this.proximity,
    required this.expansionValue,
    required this.sprites,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 100);
    
    _drawFloor(canvas, center);
    _drawWalls(canvas, center);
    
    final sortedAssets = List<FurnitureAsset>.from(assets)
      ..sort((a, b) => (a.position.z + a.position.x).compareTo(b.position.z + b.position.x));

    for (var asset in sortedAssets) {
      _drawAsset(canvas, center, asset);
    }
  }

  void _drawFloor(Canvas canvas, Offset center) {
    // Definimos un área de suelo de 10x10 metros para la maqueta
    double sizeMeters = 5.0;
    double pixelsPerMeter = 40.0;
    double s = sizeMeters * pixelsPerMeter;

    Path floorPath = Path();
    floorPath.moveTo(center.dx, center.dy);
    floorPath.lineTo(center.dx + s * math.cos(math.pi / 6), center.dy - s * math.sin(math.pi / 6));
    floorPath.lineTo(center.dx, center.dy - 2 * s * math.sin(math.pi / 6));
    floorPath.lineTo(center.dx - s * math.cos(math.pi / 6), center.dy - s * math.sin(math.pi / 6));
    floorPath.close();

    // Color/Textura según RoomType
    Color floorColor;
    switch (roomType) {
      case RoomType.living:
        floorColor = const Color(0xFFD2B48C); // Parquet (Tan)
        break;
      case RoomType.bathroom:
        floorColor = Colors.white; // Cerámicos
        break;
      case RoomType.bedroom:
        floorColor = const Color(0xFFF5F5DC); // Alfombra Beige
        break;
      case RoomType.kitchen:
        floorColor = Colors.grey[300]!; // Cerámicos cocina
        break;
      default:
        floorColor = Colors.brown[200]!;
    }

    canvas.drawPath(floorPath, Paint()..color = floorColor);
    
    // Dibujar patrón de rejilla/textura suave
    final gridPaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    for (double i = 0; i <= sizeMeters; i += 0.5) {
      double d = i * pixelsPerMeter;
      // Líneas en una dirección
      canvas.drawLine(
        center + Offset(-d * math.cos(math.pi/6), -d * math.sin(math.pi/6)),
        center + Offset((s-d) * math.cos(math.pi/6), -(s+d) * math.sin(math.pi/6)),
        gridPaint
      );
      // Líneas en la otra dirección
      canvas.drawLine(
        center + Offset(d * math.cos(math.pi/6), -d * math.sin(math.pi/6)),
        center + Offset(-(s-d) * math.cos(math.pi/6), -(s+d) * math.sin(math.pi/6)),
        gridPaint
      );
    }
  }

  void _drawWalls(Canvas canvas, Offset center) {
    double sizeMeters = 5.0;
    double pixelsPerMeter = 40.0;
    double s = sizeMeters * pixelsPerMeter;
    double wallHeight = 40.0; // Altura "cortada"
    double wallThickness = 8.0;

    final wallPaint = Paint()..color = const Color(0xFFE0E0E0); // Beige/Gris claro
    final wallTopPaint = Paint()..color = const Color(0xFFCCCCCC);

    // Muro Izquierdo
    Path leftWall = Path();
    leftWall.moveTo(center.dx, center.dy);
    leftWall.lineTo(center.dx - s * math.cos(math.pi / 6), center.dy - s * math.sin(math.pi / 6));
    leftWall.lineTo(center.dx - s * math.cos(math.pi / 6), center.dy - s * math.sin(math.pi / 6) - wallHeight);
    leftWall.lineTo(center.dx, center.dy - wallHeight);
    leftWall.close();
    canvas.drawPath(leftWall, wallPaint);

    // Muro Derecho
    Path rightWall = Path();
    rightWall.moveTo(center.dx, center.dy);
    rightWall.lineTo(center.dx + s * math.cos(math.pi / 6), center.dy - s * math.sin(math.pi / 6));
    rightWall.lineTo(center.dx + s * math.cos(math.pi / 6), center.dy - s * math.sin(math.pi / 6) - wallHeight);
    rightWall.lineTo(center.dx, center.dy - wallHeight);
    rightWall.close();
    canvas.drawPath(rightWall, wallPaint);

    // Parte superior del muro (grosor)
    Path leftTop = Path();
    leftTop.moveTo(center.dx, center.dy - wallHeight);
    leftTop.lineTo(center.dx - s * math.cos(math.pi / 6), center.dy - s * math.sin(math.pi / 6) - wallHeight);
    leftTop.lineTo(center.dx - s * math.cos(math.pi / 6) + wallThickness, center.dy - s * math.sin(math.pi / 6) - wallHeight + 4);
    leftTop.lineTo(center.dx + wallThickness, center.dy - wallHeight + 4);
    leftTop.close();
    canvas.drawPath(leftTop, wallTopPaint);
  }

  void _drawAsset(Canvas canvas, Offset center, FurnitureAsset asset) {
    double pixelsPerMeter = 40.0;
    double isoX = (asset.position.x - asset.position.z) * math.cos(math.pi / 6) * pixelsPerMeter;
    double isoY = (asset.position.x + asset.position.z) * math.sin(math.pi / 6) * pixelsPerMeter;
    Offset basePos = center + Offset(isoX, -isoY);

    double opacity = proximity.clamp(0.3, 1.0);
    double scale = 1.0;
    if (proximity > 0.8) {
      scale = 1.0 + (expansionValue * 0.1);
    }

    if (asset.spriteUrl != null && sprites.containsKey(asset.spriteUrl)) {
      ui.Image img = sprites[asset.spriteUrl!]!;
      
      // Calcular destino del sprite manteniendo aspecto
      double destW = asset.dimensions.width * 60 * scale;
      double destH = (destW / img.width) * img.height;
      
      Rect destRect = Rect.fromLTWH(
        basePos.dx - destW / 2,
        basePos.dy - destH,
        destW,
        destH
      );

      canvas.saveLayer(destRect, Paint()..color = Colors.white.withOpacity(opacity));
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        destRect,
        Paint()
      );
      canvas.restore();

      // Glow si hay proximidad
      if (proximity > 0.7) {
        canvas.drawRect(
          destRect.inflate(4),
          Paint()
            ..color = asset.color.withOpacity(0.2 * proximity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8)
        );
      }
    } else {
      // Fallback a cubo si no hay sprite cargado
      final paint = Paint()..color = asset.color.withOpacity(opacity);
      _drawFallbackCube(canvas, basePos, asset, paint, scale);
    }
  }

  void _drawFallbackCube(Canvas canvas, Offset pos, FurnitureAsset asset, Paint paint, double scale) {
    double w = asset.dimensions.width * 40 * scale;
    double d = asset.dimensions.depth * 40 * scale;
    double h = asset.dimensions.height * 40 * scale;

    Path top = Path()
      ..moveTo(pos.dx, pos.dy - h)
      ..lineTo(pos.dx + w * math.cos(math.pi/6), pos.dy - w * math.sin(math.pi/6) - h)
      ..lineTo(pos.dx, pos.dy - (w + d) * math.sin(math.pi/6) - h)
      ..lineTo(pos.dx - d * math.cos(math.pi/6), pos.dy - d * math.sin(math.pi/6) - h)
      ..close();
    canvas.drawPath(top, paint);
  }

  @override
  bool shouldRepaint(covariant IsometricMaquettePainter oldDelegate) => 
    oldDelegate.proximity != proximity || 
    oldDelegate.expansionValue != expansionValue ||
    oldDelegate.sprites.length != sprites.length;
}

