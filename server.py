import http.server
import socketserver

PORT = 8081

class MyHttpRequestHandler(http.server.SimpleHTTPRequestHandler):
    def translate_path(self, path):
        return super().translate_path('./web' + path)

with socketserver.TCPServer(("", PORT), MyHttpRequestHandler) as httpd:
    print("serving at port", PORT)
    httpd.serve_forever()