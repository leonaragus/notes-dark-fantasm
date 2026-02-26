class AppAssets {
  static const String _base = 'assets/images/furniture';

  static List<String> cocina = [
    '$_base/cocina/fridge.png',
    '$_base/cocina/cooker.png',
    '$_base/cocina/cabinet.png',
    '$_base/cocina/sink.png',
    '$_base/cocina/counter.png',
  ];

  static List<String> living = [
    '$_base/living/sofa.png',
    '$_base/living/chair.png',
    '$_base/living/television.png',
    '$_base/living/table.png',
    '$_base/living/bookcase.png',
    '$_base/living/lamp.png',
  ];

  static List<String> dormitorio = [
    '$_base/dormitorio/bed.png',
    '$_base/dormitorio/wardrobe.png',
    '$_base/dormitorio/desk.png',
    '$_base/dormitorio/computer.png',
  ];

  static List<String> baño = [
    '$_base/baño/toilet.png',
    '$_base/baño/shower.png',
    '$_base/baño/bathtub.png',
  ];

  static List<String> patio = [
    '$_base/patio/tree.png',
    '$_base/patio/bush.png',
    '$_base/patio/grass.png',
    '$_base/patio/fence.png',
    '$_base/patio/bench.png',
  ];

  static List<String> pisos = [
    '$_base/pisos/tile.png',
    '$_base/pisos/wood.png',
    '$_base/pisos/carpet.png',
  ];

  /// Helper para obtener la ruta de un asset por categoría y nombre
  static String getAsset(String category, String name) {
    return '$_base/$category/$name.png';
  }
}
