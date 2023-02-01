#!/bin/sh

if [ -n "$REST_ADVERTISED_HOST_NAME" ]; then
    echo "ADDING REST_ADVERTISED_HOST_NAME"
    echo rest.advertised.host.name=$REST_ADVERTISED_HOST_NAME >> /opt/kafka/config/connect-distributed.properties
fi

if [ -n "$REST_ADVERTISED_HOST_PORT" ]; then
    echo "ADDING REST_ADVERTISED_HOST_PORT"
    echo rest.advertised.host.port=$REST_ADVERTISED_HOST_PORT >> /opt/kafka/config/connect-distributed.properties
fi

exec "$@"