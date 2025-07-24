#!/usr/bin/env python3
"""
Simple HTTP server for testing Cloudflare tunnel
"""
from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import datetime

class TestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Cloudflare Tunnel Test</title>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }}
                .container {{ background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
                .success {{ color: #28a745; }}
                .info {{ color: #007bff; }}
                .timestamp {{ color: #6c757d; font-size: 0.9em; }}
            </style>
        </head>
        <body>
            <div class="container">
                <h1 class="success">🎉 Hello World from Cloudflare Tunnel!</h1>
                <p class="info">✅ Your tunnel is working correctly!</p>
                <hr>
                <p><strong>Server Info:</strong></p>
                <ul>
                    <li><strong>Local URL:</strong> http://localhost:8080</li>
                    <li><strong>Public URL:</strong> https://mcp.wlmedia.com</li>
                    <li><strong>Request Path:</strong> {self.path}</li>
                    <li><strong>Client IP:</strong> {self.client_address[0]}</li>
                    <li><strong>User Agent:</strong> {self.headers.get('User-Agent', 'Unknown')}</li>
                </ul>
                <p class="timestamp">Timestamp: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
            </div>
        </body>
        </html>
        """
        
        self.wfile.write(html_content.encode('utf-8'))
        
        # Log the request
        print(f"[{datetime.datetime.now().strftime('%H:%M:%S')}] GET {self.path} from {self.client_address[0]}")

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length)
        
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        
        response = {
            "status": "success",
            "message": "Hello from Cloudflare Tunnel!",
            "timestamp": datetime.datetime.now().isoformat(),
            "received_data": post_data.decode('utf-8') if post_data else None
        }
        
        self.wfile.write(json.dumps(response, indent=2).encode('utf-8'))
        print(f"[{datetime.datetime.now().strftime('%H:%M:%S')}] POST {self.path} from {self.client_address[0]}")

    def log_message(self, format, *args):
        # Suppress default logging to avoid duplicate messages
        pass

def run_server():
    server_address = ('localhost', 8080)
    httpd = HTTPServer(server_address, TestHandler)
    print(f"🚀 Test server starting on http://localhost:8080")
    print(f"🌐 Should be accessible via tunnel at: https://mcp.wlmedia.com")
    print(f"📝 Press Ctrl+C to stop the server")
    print("-" * 60)
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
        httpd.server_close()

if __name__ == "__main__":
    run_server()
