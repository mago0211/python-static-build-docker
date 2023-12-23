#/bin/sh

rm -rf ./dist
mkdir -p ./dist

PYTHON_PREFIX=/opt/python

podman build --build-arg PYTHON_PREFIX=${PYTHON_PREFIX} . -t python32-static
podman run --rm -v ./dist:/dist:Z python32-static