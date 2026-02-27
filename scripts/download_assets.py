import os
import urllib.request
import traceback

# Base URLs actualizadas a repositorios que existen y tienen sprites isométricos
# Usando el repositorio de Kenney oficial pero con la estructura correcta de ramas
furniture_base_url = 'https://raw.githubusercontent.com/KenneyNL/Isometric-Assets/master/Sprites/Furniture/'
vegetation_base_url = 'https://raw.githubusercontent.com/KenneyNL/Isometric-Assets/master/Sprites/Vegetation/'
floor_base_url = 'https://raw.githubusercontent.com/KenneyNL/Isometric-Assets/master/Sprites/Floor/'

# Intentar también con el repositorio de Furniture Kit de Kenney si el anterior falla
furniture_kit_url = 'https://raw.githubusercontent.com/KenneyNL/Furniture-Kit/master/Models/Isometric/'

categories = {
    'cocina': ['fridge', 'cooker', 'cabinet', 'sink', 'counter', 'kitchen_cabinet', 'kitchen_sink', 'refrigerator', 'oven', 'microwave'],
    'living': ['sofa', 'chair', 'television', 'table', 'bookcase', 'lamp', 'rug', 'painting', 'table_small', 'table_long', 'armchair', 'couch', 'tv'],
    'dormitorio': ['bed', 'wardrobe', 'desk', 'computer', 'pillow', 'bed_double', 'bed_single', 'nightstand', 'dresser'],
    'bano': ['toilet', 'shower', 'bathtub', 'sink_bathroom', 'mirror', 'towel_rack'],
    'patio': ['tree', 'bush', 'grass', 'fence', 'bench', 'flower', 'tree_small', 'tree_large', 'fountain', 'pool'],
    'pisos': ['tile', 'wood', 'carpet', 'grass_floor', 'floor_wood', 'floor_tile', 'floor_carpet', 'parquet', 'ceramic'],
}

def download_file(url, path):
    try:
        # Añadir un pequeño delay para no saturar la API
        import time
        time.sleep(0.1)
        
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            if response.status == 200:
                with open(path, 'wb') as f:
                    f.write(response.read())
                return True
    except Exception as e:
        # Silenciar errores 404
        pass
    return False

def main():
    print("Iniciando descarga de assets isométricos...")
    
    for category, items in categories.items():
        print(f'\nProcesando categoría: {category}')
        # Asegurar que la ruta sea absoluta para evitar problemas de contexto
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        dir_path = os.path.join(base_dir, 'assets', 'images', 'furniture', category)
        
        if not os.path.exists(dir_path):
            os.makedirs(dir_path, exist_ok=True)
        
        downloaded_count = 0
        for item_name in items:
            if downloaded_count >= 30: break
            
            # Intentar con múltiples bases de URL
            possible_bases = []
            if category == 'patio': 
                possible_bases.append(vegetation_base_url)
            elif category == 'pisos': 
                possible_bases.append(floor_base_url)
            else:
                possible_bases.append(furniture_base_url)
                possible_bases.append(furniture_kit_url)
            
            names_to_try = [
                f'{item_name}.png',
                f'{item_name}_small.png',
                f'{item_name}_large.png',
                f'{item_name}_double.png',
                f'{item_name}_long.png',
                f'{item_name}_NW.png', # Direcciones comunes en packs isométricos
                f'{item_name}_NE.png',
                f'{item_name}_SE.png',
                f'{item_name}_SW.png',
            ]
            
            if category == 'pisos' and not item_name.startswith('floor_'):
                names_to_try.append(f'floor_{item_name}.png')

            success = False
            for base in possible_bases:
                if success: break
                for name in names_to_try:
                    url = f'{base}{name}'
                    file_path = os.path.join(dir_path, name)
                    
                    if download_file(url, file_path):
                        print(f'  [OK] {name}')
                        downloaded_count += 1
                        success = True
                        break
                
    print('\nDescarga finalizada.')

if __name__ == '__main__':
    main()
