import 'package:flutter/material.dart';
import '../models/room_models.dart';
import '../theme/cyber_theme.dart';

class Canvas2D extends StatefulWidget {
  final List<FurnitureAsset> assets;
  final Function(FurnitureAsset, Offset) onAssetMoved;
  final Function(FurnitureAsset) onAssetSelected;
  final Function(FurnitureAsset) onAssetRotate;
  final bool isEditMode;

  const Canvas2D({
    Key? key,
    required this.assets,
    required this.onAssetMoved,
    required this.onAssetSelected,
    required this.onAssetRotate,
    required this.isEditMode,
  }) : super(key: key);

  @override
  _Canvas2DState createState() => _Canvas2DState();
}

class _Canvas2DState extends State<Canvas2D> {
  static const double gridSize = 20.0;
  static const double metersToPixels = 40.0; // 1 meter = 40 pixels (2 grid cells)

  double snapToGrid(double value) {
    // Snap to exact 0.5m increments (20px)
    return (value / gridSize).roundToDouble() * gridSize;
  }

  @override
  Widget build(BuildContext context) {
    final sortedAssets = List<FurnitureAsset>.from(widget.assets)
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return Container(
      color: CyberTheme.darkBg,
      child: Stack(
        children: [
          CustomPaint(
            painter: GridPainter(gridSize: gridSize),
            size: Size.infinite,
          ),
          ...sortedAssets.map((asset) => Positioned(
                left: asset.position.x,
                top: asset.position.z,
                child: _buildDraggableOrStatic(asset),
              )),
          // Origin indicator
          Positioned(
            left: -10,
            top: -10,
            child: Icon(Icons.door_front_door, color: CyberTheme.neonGreen.withOpacity(0.5), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableOrStatic(FurnitureAsset asset) {
    final assetWidget = GestureDetector(
      onTap: () => widget.onAssetSelected(asset),
      onDoubleTap: widget.isEditMode ? () => widget.onAssetRotate(asset) : null,
      child: _buildAssetWidget(asset),
    );

    if (!widget.isEditMode) return assetWidget;

    return Draggable(
      feedback: Opacity(
        opacity: 0.6,
        child: _buildAssetWidget(asset),
      ),
      childWhenDragging: Container(),
      onDragEnd: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localOffset = box.globalToLocal(details.offset);
        final snappedOffset = Offset(
          snapToGrid(localOffset.dx),
          snapToGrid(localOffset.dy),
        );
        widget.onAssetMoved(asset, snappedOffset);
      },
      child: assetWidget,
    );
  }

  Widget _buildAssetWidget(FurnitureAsset asset) {
    bool isRotated = asset.rotation == 90 || asset.rotation == 270;
    final w = (isRotated ? asset.dimensions.depth : asset.dimensions.width) * metersToPixels;
    final d = (isRotated ? asset.dimensions.width : asset.dimensions.depth) * metersToPixels;
    
    // Color de borde y sombra dinámico según sincronización
    final borderColor = asset.isSynced ? CyberTheme.neonCyan : asset.color.withOpacity(0.8);
    final shadowColor = asset.isSynced ? CyberTheme.neonCyan.withOpacity(0.5) : asset.color.withOpacity(0.3);

    return Container(
      width: w,
      height: d,
      decoration: BoxDecoration(
        color: asset.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: RotatedBox(
              quarterTurns: asset.rotation ~/ 90,
              child: Icon(asset.icon, color: asset.color, size: 18),
            ),
          ),
          // Icono de Check verde si está sincronizado
          if (asset.isSynced)
            Positioned(
              top: 1,
              right: 1,
              child: Icon(Icons.check_circle, color: Colors.greenAccent, size: 12),
            ),
          if (widget.isEditMode)
            Positioned(
              bottom: 1,
              right: 1,
              child: Text(
                'Z:${asset.zIndex}',
                style: TextStyle(color: asset.color, fontSize: 7, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final double gridSize;

  GridPainter({required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CyberTheme.gridColor
      ..strokeWidth = 0.5;

    for (double i = 0; i <= size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i <= size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    final axisPaint = Paint()
      ..color = CyberTheme.neonGreen.withOpacity(0.2)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, 0), Offset(size.width, 0), axisPaint);
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), axisPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
