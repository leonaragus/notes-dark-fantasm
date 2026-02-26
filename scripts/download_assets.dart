import 'dart:io';
import 'dart:async';

const String furnitureBaseUrl = 'https://raw.githubusercontent.com/KenneyNL/Isometric-Assets/master/Sprites/Furniture/';
const String vegetationBaseUrl = 'https://raw.githubusercontent.com/KenneyNL/Isometric-Assets/master/Sprites/Vegetation/';
const String floorBaseUrl = 'https://raw.githubusercontent.com/KenneyNL/Isometric-Assets/master/Sprites/Floor/';

final Map<String, List<String>> categories = {
  'cocina': ['fridge', 'cooker', 'cabinet', 'sink', 'counter', 'kitchen_cabinet', 'kitchen_sink'],
  'living': ['sofa', 'chair', 'television', 'table', 'bookcase', 'lamp', 'rug', 'painting'],
  'dormitorio': ['bed', 'wardrobe', 'desk', 'computer', 'pillow'],
  'baño': ['toilet', 'shower', 'bathtub', 'sink_bathroom'],
  'patio': ['tree', 'bush', 'grass', 'fence', 'bench', 'flower'],
  'pisos': ['tile', 'wood', 'carpet', 'grass_floor'],
};

Future<void> main() async {
  final client = HttpClient();
  
  for (var category in categories.entries) {
    print('Procesando categoría: ${category.key}');
    final dir = Directory('assets/images/furniture/${category.key}');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    int downloadedCount = 0;
    for (var itemName in category.value) {
      if (downloadedCount >= 30) break;
      
      String baseUrl = furnitureBaseUrl;
      if (category.key == 'patio') baseUrl = vegetationBaseUrl;
      if (category.key == 'pisos') baseUrl = floorBaseUrl;
      
      // Intentar varios nombres comunes (con guiones, guiones bajos, etc.)
      final namesToTry = [
        '${itemName}.png',
        '${itemName}_small.png',
        '${itemName}_large.png',
        '${itemName}_double.png',
      ];
      
      for (var name in namesToTry) {
        if (downloadedCount >= 30) break;
        
        final url = Uri.parse('$baseUrl$name');
        final file = File('${dir.path}/$name');
        
        try {
          final request = await client.getUrl(url);
          final response = await request.close();
          
          if (response.statusCode == 200) {
            final bytes = await response.expand((i) => i).toList();
            await file.writeAsBytes(bytes);
            print('Descargado: $name en ${category.key}');
            downloadedCount++;
          }
        } catch (e) {
          // Ignorar errores de descarga (por ejemplo, si el archivo no existe)
        }
      }
    }
  }
  
  client.close();
  print('Finalizado.');
}
