#!/bin/bash

CMD=""

# Check if running inside a virtual environment
if [ "_$VIRTUAL_ENV" == "_" ]; then
    echo "ERROR:  Not running inside a python virtual environment. Exiting"
    exit 1
fi

# Check if storage.conf for podman exists
# and points to the /data volume
# See https://devtodevops.com/change-podman-storage-location/
if [ -f "$HOME/.config/containers/storage.conf" ]; then
    if grep -qF 'graphroot = "/data/surf/.plain/local/share/containers"' "$HOME/.config.containers/storage.conf"; then
        echo "INFO:   found 'graphroot' setting in $HOME/.config/containers/storage.conf"
    else
        echo "ERROR:  podman storage settings invalid."
        echo "ERROR:    We want podman volumes to be stored in the /data directory."
        echo "ERROR:    See https://devtodevops.com/change-podman-storage-location/ for details."
        echo "ERROR:    Exiting."
        exit 1
    fi
else
    echo "ERROR:  podman storage settings not found. Exiting."
    echo "ERROR:    See man containers-storage.conf and https://devtodevops.com/change-podman-storage-location/ for details."
    exit 1
fi

# Check if either Podman or Docker is installed
if command -v podman &>/dev/null; then
    CMD=$(command -v podman)
elif command -v docker; then
    CMD=$(command -v docker)
else
    echo "ERROR:  Could not find docker or podman. Exiting."
    exit 1
fi

# Check if the "elastic" network exists
if ${CMD} network exists elastic; then
    echo "INFO:    The 'elastic' network exists."
else
    # Create the "elastic" network
    ${CMD} network create elastic
    echo "INFO:    Created the 'elastic' network."
fi

# Disable SSL
echo "WARNING: disable SSL"
set xpack.security.enabled=false
set xpack.security.enrollment.enabled=false


# Check if /etc/systemd/system/user@.service.d exists
if [ -d "/etc/systemd/system/user@.service.d" ]; then
    # Check if the specified line exists in the systemd service configuration
    if grep -q "Delegate=cpu cpuset io memory pids" "/etc/systemd/system/user@.service.d/delegate.conf"; then
        echo "INFO:    The specified line exists in the systemd service configuration."
    else
        echo "ERROR:   The specified line is missing in the systemd service configuration. See https://rootlesscontaine.rs/getting-started/common/cgroup2/ for details."
	exit 1
    fi
else
    echo "ERROR: /etc/systemd/system/user@.service.d does not exist."
    exit 1
fi

#
# Start Elasticsearch container

if [ ! -f docker-compose.yml ]; then
	echo "INFO:    Creating docker-compse.yml"
	cat <<EOF > "docker-compose.yml"
version: '3'
services:
  es01-1:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.15.0
    container_name: es01
    networks:
      - elastic
    ports:
      - "9200:9200"
    volumes:
      - esdata1:/usr/share/elasticsearch/data:rw
    environment:
      - xpack.security.enabled=false
      - xpack.security.enrollment.enabled=false
      - discovery.type=single-node
      - indices.id_field_data.enabled=true
      - ELASTICSEARCH_USERNAME=elastic
      - ELASTICSEARCH_PASSWORD=elastic
    mem_limit: 1GB
    restart: unless-stopped

volumes:
  esdata1:
    driver: local
networks:
  elastic:
EOF
fi

echo "INFO:    Starting ES container"
podman compose up -d

