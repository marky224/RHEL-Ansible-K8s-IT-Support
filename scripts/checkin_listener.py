#!/usr/bin/env python3
import argparse
import ssl
from http.server import HTTPServer, BaseHTTPRequestHandler
import logging

logging.basicConfig(filename="/var/log/checkin.log", level=logging.INFO, format="%(asctime)s - %(message)s")

class CheckinHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers["Content-Length"])
        post_data = self.rfile.read(content_length).decode("utf-8")
        logging.info(f"Check-in received: {post_data}")
        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.end_headers()
        self.wfile.write(b"Check-in received")

def run(port, cert, key):
    server_address = ("", port)
    httpd = HTTPServer(server_address, CheckinHandler)
    httpd.socket = ssl.wrap_socket(httpd.socket, certfile=cert, keyfile=key, server_side=True)
    print(f"Starting check-in listener on port {port}...")
    httpd.serve_forever()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Ansible Check-in Listener")
    parser.add_argument("--port", type=int, default=8080, help="Port to listen on")
    parser.add_argument("--cert", type=str, required=True, help="Path to SSL certificate")
    parser.add_argument("--key", type=str, required=True, help="Path to SSL private key")
    args = parser.parse_args()
    run(args.port, args.cert, args.key)
