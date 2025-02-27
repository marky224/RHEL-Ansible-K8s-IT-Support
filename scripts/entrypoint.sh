#!/bin/bash
# entrypoint.sh
# Runs either checkin_listener.py or ssh_key_server.py based on SERVICE env var

SERVICE="${SERVICE:-checkin_listener}"  # Default to checkin_listener
CERT="${CERT:-/certs/control_node_ca.crt}"
KEY="${KEY:-/certs/control_node_ca.key}"
PORT="${PORT:-8080}"

case "$SERVICE" in
    "checkin_listener")
        exec python3 /app/checkin_listener.py --port "$PORT" --cert "$CERT" --key "$KEY"
        ;;
    "ssh_key_server")
        exec python3 /app/ssh_key_server.py --port "$PORT" --cert "$CERT" --key "$KEY"
        ;;
    *)
        echo "Error: Unknown SERVICE value '$SERVICE'. Use 'checkin_listener' or 'ssh_key_server'."
        exit 1
        ;;
esac
