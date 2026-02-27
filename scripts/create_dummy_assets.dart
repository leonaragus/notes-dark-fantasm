import 'dart:io';

void main() {
  final Map<String, List<String>> files = {
    'cocina': ['fridge.png', 'cooker.png', 'cabinet.png', 'sink.png', 'counter.png'],
    'living': ['sofa.png', 'chair.png', 'television.png', 'table.png', 'bookcase.png', 'lamp.png'],
    'dormitorio': ['bed.png', 'wardrobe.png', 'desk.png', 'computer.png'],
    'bano': ['toilet.png', 'shower.png', 'bathtub.png'],
    'patio': ['tree.png', 'bush.png', 'grass.png', 'fence.png', 'bench.png'],
    'pisos': ['tile.png', 'wood.png', 'carpet.png'],
  };

  for (var entry in files.entries) {
    final dir = Directory('assets/images/furniture/${entry.key}');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    for (var file in entry.value) {
      final f = File('${dir.path}/$file');
      if (!f.existsSync()) {
        f.createSync();
        print('Creado: ${f.path}');
      }
    }
  }
}
