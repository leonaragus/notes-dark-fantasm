import urllib.request
import json

def get_contents(path=""):
    url = f"https://api.github.com/repos/iwenzhou/kenney/contents/{path}"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req) as response:
        return json.loads(response.read().decode())

def search_recursive(path, target_name):
    try:
        items = get_contents(path.replace(" ", "%20"))
        for item in items:
            if item['type'] == 'dir':
                res = search_recursive(item['path'], target_name)
                if res: return res
            elif target_name in item['name'].lower():
                print(f"Found: {item['path']}")
                return item['path']
    except:
        pass
    return None

print("Searching for 'Isometric' in root...")
search_recursive("", "isometric")
