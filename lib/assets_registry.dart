import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';
import 'models/room_models.dart';

class AssetRegistry {
  static final Map<int, Map<String, dynamic>> models = {
    // COCINA (100+) - 21 Assets
    101: {'name': 'Heladera Grande', 'category': 'Cocina', 'model': 'assets/models/kitchenFridgeLarge.obj', 'dimensions': const AssetDimension(width: 0.9, depth: 0.8, height: 1.9)},
    102: {'name': 'Heladera', 'category': 'Cocina', 'model': 'assets/models/kitchenFridge.obj', 'dimensions': const AssetDimension(width: 0.7, depth: 0.7, height: 1.8)},
    103: {'name': 'Heladera Pequeña', 'category': 'Cocina', 'model': 'assets/models/kitchenFridgeSmall.obj', 'dimensions': const AssetDimension(width: 0.6, depth: 0.6, height: 0.9)},
    104: {'name': 'Cocina Gas', 'category': 'Cocina', 'model': 'assets/models/kitchenStove.obj', 'dimensions': const AssetDimension(width: 0.6, depth: 0.6, height: 0.9)},
    105: {'name': 'Cocina Eléctrica', 'category': 'Cocina', 'model': 'assets/models/kitchenStoveElectric.obj', 'dimensions': const AssetDimension(width: 0.6, depth: 0.6, height: 0.9)},
    106: {'name': 'Microondas', 'category': 'Cocina', 'model': 'assets/models/kitchenMicrowave.obj', 'dimensions': const AssetDimension(width: 0.5, depth: 0.4, height: 0.3)},
    107: {'name': 'Lava Platos', 'category': 'Cocina', 'model': 'assets/models/kitchenSink.obj', 'dimensions': const AssetDimension(width: 1.2, depth: 0.6, height: 0.9)},
    108: {'name': 'Cafetera', 'category': 'Cocina', 'model': 'assets/models/kitchenCoffeeMachine.obj', 'dimensions': const AssetDimension(width: 0.3, depth: 0.3, height: 0.4)},
    109: {'name': 'Licuadora', 'category': 'Cocina', 'model': 'assets/models/kitchenBlender.obj', 'dimensions': const AssetDimension(width: 0.2, depth: 0.2, height: 0.4)},
    110: {'name': 'Tostadora', 'category': 'Cocina', 'model': 'assets/models/toaster.obj', 'dimensions': const AssetDimension(width: 0.3, depth: 0.2, height: 0.2)},
    111: {'name': 'Gabinete Cocina', 'category': 'Cocina', 'model': 'assets/models/kitchenCabinet.obj', 'dimensions': const AssetDimension(width: 0.6, depth: 0.6, height: 0.9)},
    112: {'name': 'Gabinete Cajonera', 'category': 'Cocina', 'model': 'assets/models/kitchenCabinetDrawer.obj', 'dimensions': const AssetDimension(width: 0.6, depth: 0.6, height: 0.9)},
    113: {'name': 'Gabinete Superior', 'category': 'Cocina', 'model': 'assets/models/kitchenCabinetUpper.obj', 'dimensions': const AssetDimension(width: 0.6, depth: 0.3, height: 0.6)},
    114: {'name': 'Gabinete Sup. Doble', 'category': 'Cocina', 'model': 'assets/models/kitchenCabinetUpperDouble.obj', 'dimensions': const AssetDimension(width: 1.2, depth: 0.3, height: 0.6)},
    115: {'name': 'Barra Cocina', 'category': 'Cocina', 'model': 'assets/models/kitchenBar.obj', 'dimensions': const AssetDimension(width: 1.2, depth: 0.6, height: 1.0)},
    116: {'name': 'Esquina Barra', 'category': 'Cocina', 'model': 'assets/models/kitchenBarEnd.obj', 'dimensions': const AssetDimension(width: 0.6, depth: 0.6, height: 1.0)},
    117: {'name': 'Campana Moderna', 'category': 'Cocina', 'model': 'assets/models/hoodModern.obj', 'dimensions': const AssetDimension(width: 0.6, depth: 0.5, height: 0.7)},
    118: {'name': 'Campana Grande', 'category': 'Cocina', 'model': 'assets/models/hoodLarge.obj', 'dimensions': const AssetDimension(width: 0.9, depth: 0.6, height: 0.8)},
    119: {'name': 'Taburete Bar', 'category': 'Cocina', 'model': 'assets/models/stoolBar.obj', 'dimensions': const AssetDimension(width: 0.4, depth: 0.4, height: 0.8)},
    120: {'name': 'Taburete Cuadrado', 'category': 'Cocina', 'model': 'assets/models/stoolBarSquare.obj', 'dimensions': const AssetDimension(width: 0.4, depth: 0.4, height: 0.8)},
    121: {'name': 'Cesto Basura', 'category': 'Cocina', 'model': 'assets/models/trashcan.obj', 'dimensions': const AssetDimension(width: 0.3, depth: 0.3, height: 0.5)},

    // LIVING (200+) - 22 Assets
    201: {'name': 'Sofá Design', 'category': 'Living', 'model': 'assets/models/loungeDesignSofa.obj', 'dimensions': const AssetDimension(width: 2.0, depth: 0.9, height: 0.8)},
    202: {'name': 'Sofá Esquina', 'category': 'Living', 'model': 'assets/models/loungeDesignSofaCorner.obj', 'dimensions': const AssetDimension(width: 2.5, depth: 2.5, height: 0.8)},
    203: {'name': 'Sofá Largo', 'category': 'Living', 'model': 'assets/models/loungeSofaLong.obj', 'dimensions': const AssetDimension(width: 2.8, depth: 0.9, height: 0.8)},
    204: {'name': 'Sofá Lounge', 'category': 'Living', 'model': 'assets/models/loungeSofa.obj', 'dimensions': const AssetDimension(width: 2.0, depth: 0.9, height: 0.8)},
    205: {'name': 'Sillón Relax', 'category': 'Living', 'model': 'assets/models/loungeChairRelax.obj', 'dimensions': const AssetDimension(width: 1.0, depth: 1.0, height: 0.9)},
    206: {'name': 'Sillón Design', 'category': 'Living', 'model': 'assets/models/loungeDesignChair.obj', 'dimensions': const AssetDimension(width: 0.9, depth: 0.8, height: 0.8)},
    207: {'name': 'Puff Ottoman', 'category': 'Living', 'model': 'assets/models/loungeSofaOttoman.obj', 'dimensions': const AssetDimension(width: 0.7, depth: 0.7, height: 0.4)},
    208: {'name': 'Mesa Centro Cristal', 'category': 'Living', 'model': 'assets/models/tableCoffeeGlass.obj', 'dimensions': const AssetDimension(width: 1.2, depth: 0.7, height: 0.4)},
    209: {'name': 'Mesa Centro Madera', 'category': 'Living', 'model': 'assets/models/tableCoffee.obj', 'dimensions': const AssetDimension(width: 1.0, depth: 0.6, height: 0.4)},
    210: {'name': 'Mesa Centro Cuadrada', 'category': 'Living', 'model': 'assets/models/tableCoffeeSquare.obj', 'dimensions': const AssetDimension(width: 0.8, depth: 0.8, height: 0.4)},
    211: {'name': 'TV Moderna', 'category': 'Living', 'model': 'assets/models/televisionModern.obj', 'dimensions': const AssetDimension(width: 1.4, depth: 0.1, height: 0.8)},
    212: {'name': 'TV Vintage', 'category': 'Living', 'model': 'assets/models/televisionVintage.obj', 'dimensions': const AssetDimension(width: 0.8, depth: 0.6, height: 0.7)},
    213: {'name': 'Parlante Grande', 'category': 'Living', 'model': 'assets/models/speaker.obj', 'dimensions': const AssetDimension(width: 0.4, depth: 0.4, height: 1.0)},
    214: {'name': 'Parlante Pequeño', 'category': 'Living', 'model': 'assets/models/speakerSmall.obj', 'dimensions': const AssetDimension(width: 0.2, depth: 0.2, height: 0.3)},
    215: {'name': 'Radio Retro', 'category': 'Living', 'model': 'assets/models/radio.obj', 'dimensions': const AssetDimension(width: 0.4, depth: 0.2, height: 0.3)},
    216: {'name': 'Lámpara Pie Redonda', 'category': 'Living', 'model': 'assets/models/lampRoundFloor.obj', 'dimensions': const AssetDimension(width: 0.4, depth: 0.4, height: 1.6)},
    217: {'name': 'Lámpara Pie Cuadrada', 'category': 'Living', 'model': 'assets/models/lampSquareFloor.obj', 'dimensions': const AssetDimension(width: 0.4, depth: 0.4, height: 1.6)},
    218: {'name': 'Alfombra Redonda', 'category': 'Living', 'model': 'assets/models/rugRound.obj', 'dimensions': const AssetDimension(width: 2.0, depth: 2.0, height: 0.01)},
    219: {'name': 'Alfombra Rectangular', 'category': 'Living', 'model': 'assets/models/rugRectangle.obj', 'dimensions': const AssetDimension(width: 3.0, depth: 2.0, height: 0.01)},
    220: {'name': 'Planta en Maceta', 'category': 'Living', 'model': 'assets/models/pottedPlant.obj', 'dimensions': const AssetDimension(width: 0.5, depth: 0.5, height: 0.8)},
    221: {'name': 'Almohadón Azul', 'category': 'Living', 'model': 'assets/models/pillowBlue.obj', 'dimensions': const AssetDimension(width: 0.4, depth: 0.4, height: 0.1)},
    222: {'name': 'Cuadro Pared', 'category': 'Living', 'model': 'assets/models/paneling.obj', 'dimensions': const AssetDimension(width: 1.0, depth: 0.05, height: 0.7)},

    // DORMITORIO / OFICINA (300+) - 20 Assets
    301: {'name': 'Cama Doble', 'category': 'Dormitorio', 'model': 'assets/models/bedDouble.obj', 'dimensions': const AssetDimension(width: 1.6, depth: 2.0, height: 0.6)},
    302: {'name': 'Cama Single', 'category': 'Dormitorio', 'model': 'assets/models/bedSingle.obj', 'dimensions': const AssetDimension(width: 1.0, depth: 2.0, height: 0.6)},
    303: {'name': 'Cama Litera', 'category': 'Dormitorio', 'model': 'assets/models/bedBunk.obj', 'dimensions': const AssetDimension(width: 1.0, depth: 2.0, height: 1.7)},
    304: {'name': 'Escritorio', 'category': 'Dormitorio', 'model': 'assets/models/desk.obj', 'dimensions': const AssetDimension(width: 1.4, depth: 0.7, height: 0.75)},
    305: {'name': 'Escritorio Esquina', 'category': 'Dormitorio', 'model': 'assets/models/deskCorner.obj', 'dimensions': const AssetDimension(width: 1.6, depth: 1.2, height: 0.75)},
    306: {'name': 'Silla Oficina', 'category': 'Dormitorio', 'model': 'assets/models/chairOffice.obj', 'dimensions': const AssetDimension(width: 0.6, depth: 0.6, height: 1.0)},
    307: {'name': 'Laptop', 'category': 'Dormitorio', 'model': 'assets/models/laptop.obj', 'dimensions': const AssetDimension(width: 0.4, depth: 0.3, height: 0.02)},
    308: {'name': 'Monitor', 'category': 'Dormitorio', 'model': 'assets/models/computerScreen.obj', 'dimensions': const AssetDimension(width: 0.5, depth: 0.2, height: 0.4)},
    309: {'name': 'Teclado', 'category': 'Dormitorio', 'model': 'assets/models/computerKeyboard.obj', 'dimensions': const AssetDimension(width: 0.4, depth: 0.15, height: 0.02)},
    310: {'name': 'Mouse', 'category': 'Dormitorio', 'model': 'assets/models/computerMouse.obj', 'dimensions': const AssetDimension(width: 0.1, depth: 0.07, height: 0.03)},
    311: {'name': 'Ropero Doble', 'category': 'Dormitorio', 'model': 'assets/models/wardrobeDouble.obj', 'dimensions': const AssetDimension(width: 1.2, depth: 0.6, height: 2.0)},
    312: {'name': 'Ropero Single', 'category': 'Dormitorio', 'model': 'assets/models/wardrobeSingle.obj', 'dimensions': const AssetDimension(width: 0.6, depth: 0.6, height: 2.0)},
    313: {'name': 'Mesita Luz Cajones', 'category': 'Dormitorio', 'model': 'assets/models/sideTableDrawers.obj', 'dimensions': const AssetDimension(width: 0.5, depth: 0.4, height: 0.5)},
    314: {'name': 'Mesita Luz Simple', 'category': 'Dormitorio', 'model': 'assets/models/sideTable.obj', 'dimensions': const AssetDimension(width: 0.4, depth: 0.4, height: 0.5)},
    315: {'name': 'Perchero Pie', 'category': 'Dormitorio', 'model': 'assets/models/coatRackStanding.obj', 'dimensions': const AssetDimension(width: 0.4, depth: 0.4, height: 1.8)},
    316: {'name': 'Perchero Pared', 'category': 'Dormitorio', 'model': 'assets/models/coatRack.obj', 'dimensions': const AssetDimension(width: 0.6, depth: 0.1, height: 0.2)},
    317: {'name': 'Lámpara Mesa Redonda', 'category': 'Dormitorio', 'model': 'assets/models/lampRoundTable.obj', 'dimensions': const AssetDimension(width: 0.3, depth: 0.3, height: 0.5)},
    318: {'name': 'Lámpara Mesa Cuadrada', 'category': 'Dormitorio', 'model': 'assets/models/lampSquareTable.obj', 'dimensions': const AssetDimension(width: 0.3, depth: 0.3, height: 0.5)},
    319: {'name': 'Libro', 'category': 'Dormitorio', 'model': 'assets/models/book.obj', 'dimensions': const AssetDimension(width: 0.2, depth: 0.15, height: 0.03)},
    320: {'name': 'Almohada Larga', 'category': 'Dormitorio', 'model': 'assets/models/pillowLong.obj', 'dimensions': const AssetDimension(width: 0.8, depth: 0.4, height: 0.1)},

    // BAÑO / LAVADERO (400+) - 15 Assets
    401: {'name': 'Inodoro Moderno', 'category': 'Baño', 'model': 'assets/models/toilet.obj', 'dimensions': const AssetDimension(width: 0.4, depth: 0.7, height: 0.4)},
    402: {'name': 'Inodoro Cuadrado', 'category': 'Baño', 'model': 'assets/models/toiletSquare.obj', 'dimensions': const AssetDimension(width: 0.4, depth: 0.6, height: 0.4)},
    403: {'name': 'Ducha Cuadrada', 'category': 'Baño', 'model': 'assets/models/shower.obj', 'dimensions': const AssetDimension(width: 1.0, depth: 1.0, height: 2.1)},
    404: {'name': 'Ducha Redonda', 'category': 'Baño', 'model': 'assets/models/showerRound.obj', 'dimensions': const AssetDimension(width: 1.0, depth: 1.0, height: 2.1)},
    405: {'name': 'Bañera', 'category': 'Baño', 'model': 'assets/models/bathtub.obj', 'dimensions': const AssetDimension(width: 1.7, depth: 0.8, height: 0.6)},
    406: {'name': 'Lavarropas', 'category': 'Baño', 'model': 'assets/models/washer.obj', 'dimensions': const AssetDimension(width: 0.6, depth: 0.6, height: 0.9)},
    407: {'name': 'Secarropas', 'category': 'Baño', 'model': 'assets/models/dryer.obj', 'dimensions': const AssetDimension(width: 0.6, depth: 0.6, height: 0.9)},
    408: {'name': 'Lava-Seca Apilado', 'category': 'Baño', 'model': 'assets/models/washerDryerStacked.obj', 'dimensions': const AssetDimension(width: 0.6, depth: 0.6, height: 1.8)},
    409: {'name': 'Bacha Baño', 'category': 'Baño', 'model': 'assets/models/bathroomSink.obj', 'dimensions': const AssetDimension(width: 0.6, depth: 0.5, height: 0.8)},
    410: {'name': 'Bacha Doble', 'category': 'Baño', 'model': 'assets/models/bathroomSinkSquare.obj', 'dimensions': const AssetDimension(width: 1.2, depth: 0.5, height: 0.8)},
    411: {'name': 'Gabinete Baño', 'category': 'Baño', 'model': 'assets/models/bathroomCabinet.obj', 'dimensions': const AssetDimension(width: 0.6, depth: 0.4, height: 0.6)},
    412: {'name': 'Gabinete Baño Espejo', 'category': 'Baño', 'model': 'assets/models/bathroomMirror.obj', 'dimensions': const AssetDimension(width: 0.6, depth: 0.15, height: 0.8)},
    413: {'name': 'Mesa Baño', 'category': 'Baño', 'model': 'assets/models/bathroomTable.obj', 'dimensions': const AssetDimension(width: 0.8, depth: 0.4, height: 0.7)},
    414: {'name': 'Espejo Pared', 'category': 'Baño', 'model': 'assets/models/mirror.obj', 'dimensions': const AssetDimension(width: 0.6, depth: 0.05, height: 0.9)},
    415: {'name': 'Toallero', 'category': 'Baño', 'model': 'assets/models/towelRack.obj', 'dimensions': const AssetDimension(width: 0.6, depth: 0.2, height: 1.2)},
  };

  static FurnitureAsset createAsset(int id, Vector3 pos) {
    final data = models[id];
    if (data == null) throw Exception('Model ID $id not found');

    return FurnitureAsset(
      id: 'asset_${DateTime.now().millisecondsSinceEpoch}',
      name: data['name'],
      position: pos,
      zIndex: 0,
      dimensions: data['dimensions'],
      icon: Icons.view_in_ar,
      color: Colors.white,
      modelPath: data['model'],
    );
  }
}
