#!/usr/bin/with-contenv bashio

MQTT_HOST=$(bashio::config 'mqtt_host')
MQTT_PORT=$(bashio::config 'mqtt_port')
MQTT_USERNAME=$(bashio::config 'mqtt_username')
MQTT_PASSWORD=$(bashio::config 'mqtt_password')
SERIAL_DEVICE=$(bashio::config 'serial_device')
BAUD_RATE=$(bashio::config 'baud_rate')
FRAME_GAP=$(bashio::config 'frame_gap')
RECORDER_ENABLED=$(bashio::config 'recorder_enabled')
ASSUME_NO_EXPORT=$(bashio::config 'assume_no_export')

bashio::log.info "Startuji socat most na ${SERIAL_DEVICE} (baud ${BAUD_RATE})..."
# POZOR: záměrně BEZ 'fork'. 'fork' spouští nový podproces na každé nové
# TCP spojení, ale při reconnectu egd-dlms (viz project_egd_dlms_power_field_bug.md
# v Claude memory) se starý podproces nespolehlivě neukončoval — vznikly tak
# DVA socat procesy současně čtoucí ze stejného /dev/ttyUSB0, které si mezi
# sebe nedeterministicky trhaly bajty (=náhodně poškozená data, jindy jiné
# pole). Místo fork běží socat v restart-smyčce: obslouží JEDNO spojení,
# po odpojení klienta skončí, smyčka ho hned znovu nastartuje pro další
# spojení — v každém okamžiku existuje nejvýš jeden proces se sériovým portem.
(
    while true; do
        socat TCP-LISTEN:10001,reuseaddr "FILE:${SERIAL_DEVICE},raw,b${BAUD_RATE},cs8,parenb=0,cstopb=0"
        bashio::log.warning "socat most skončil (klient se odpojil?), restartuji za 1s..."
        sleep 1
    done
) &
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
  assume_no_export: ${ASSUME_NO_EXPORT}

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
  enabled: ${RECORDER_ENABLED}
  directory: /data/samples
  save_last: true
  save_history: ${RECORDER_ENABLED}

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

