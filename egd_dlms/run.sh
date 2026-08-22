#!/usr/bin/with-contenv bashio

MQTT_HOST=$(bashio::config 'mqtt_host')
MQTT_PORT=$(bashio::config 'mqtt_port')
MQTT_USERNAME=$(bashio::config 'mqtt_username')
MQTT_PASSWORD=$(bashio::config 'mqtt_password')
SERIAL_DEVICE=$(bashio::config 'serial_device')
BAUD_RATE=$(bashio::config 'baud_rate')
FRAME_GAP=$(bashio::config 'frame_gap')

bashio::log.info "Startuji socat most na ${SERIAL_DEVICE} (baud ${BAUD_RATE})..."
socat TCP-LISTEN:10001,fork,reuseaddr "FILE:${SERIAL_DEVICE},raw,b${BAUD_RATE},cs8,parenb=0,cstopb=0" &
SOCAT_PID=$!

# Dej socatu chvíli, ať otevře port, než na něj egd-dlms zkusí připojit.
sleep 2

if ! kill -0 "$SOCAT_PID" 2>/dev/null; then
    bashio::log.fatal "socat se nepodařilo spustit — zkontroluj, že ${SERIAL_DEVICE} existuje."
    exit 1
fi

mkdir -p /data/samples /data/runtime

cat > /opt/egd-dlms/config.yaml <<EOF
meter:
  host: 127.0.0.1
  port: 10001
  frame_gap: ${FRAME_GAP}
  reconnect_delay: 5

mqtt:
  host: ${MQTT_HOST}
  port: ${MQTT_PORT}
  username: ${MQTT_USERNAME}
  password: ${MQTT_PASSWORD}
  qos: 1
  retain: false

topics:
  state: home/egd_meter/state
  availability: home/egd_meter/availability
  discovery_prefix: homeassistant

device:
  identifier: egd_meter_stara_bv
  manufacturer: EG.D
  model: RS485-HAN
  name: EGD elektroměr

logging:
  level: INFO

recorder:
  enabled: false
  directory: /data/samples
  save_last: false
  save_history: false

watchdog:
  enabled: true
  warning_after_seconds: 180
  reconnect_after_seconds: 600

runtime:
  directory: /data/runtime
  status_file: status.json
EOF

bashio::log.info "Startuji egd-dlms..."
cd /opt/egd-dlms
exec egd-dlms
