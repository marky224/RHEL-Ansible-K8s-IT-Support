#!/usr/bin/env python3
import argparse
import ssl
from http.server import HTTPServer, BaseHTTPRequestHandler

class SSHKeyHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/ssh_key":
            self.send_response(200)
            self.send_header("Content-type", "text/plain")
            self.end_headers()
            with open("/root/.ssh/id_rsa.pub", "rb") as f:
                self.wfile.write(f.read())
        else:
            self.send_response(404)
            self.end_headers()

def run(port, cert, key):
    server_address = ("", port)
    httpd = HTTPServer(server_address, SSHKeyHandler)
    httpd.socket = ssl.wrap_socket(httpd.socket, certfile=cert, keyfile=key, server_side=True)
    print(f"Starting SSH key server on port {port}...")
    httpd.serve_forever()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Ansible SSH Key Server")
    parser.add_argument("--port", type=int, default=8080, help="Port to listen on")
    parser.add_argument("--cert", type=str, required=True, help="Path to SSL certificate")
    parser.add_argument("--key", type=str, required=True, help="Path to SSL private key")
    args = parser.parse_args()
    run(args.port, args.cert, args.key)
