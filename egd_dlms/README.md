# EGD DLMS Elektroměr

Home Assistant add-on, který čte pasivní HAN výstup elektroměru EG.D
(protokol DLMS/COSEM přes RS485) a publikuje naměřené hodnoty do MQTT
s automatickým Discovery, takže se entity objeví v Home Assistantu samy.

Postaveno na [lhubac/egd-dlms](https://github.com/lhubac/egd-dlms) — add-on jen
přidává `socat` most (USB/RS485 sériový port → TCP), protože `egd-dlms` sám
očekává TCP připojení (typicky z RS485→TCP převodníku), a integruje ho do
Supervisor add-on frameworku (přetrvá restart/reboot, `startup: services`,
konfigurace přes standardní HA add-on Options panel).

## Instalace

1. Zapoj USB-RS485 adaptér (test proveden s FTDI FT232) mezi HAN port elektroměru
   a hostitele Home Assistanta.
2. Pokud HA běží ve VM (Proxmox apod.), nezapomeň na USB passthrough do VM.
3. Nainstaluj tenhle add-on, nastav v Options `serial_device` (výchozí
   `/dev/ttyUSB0`) a MQTT přístupové údaje.
4. Spusť add-on, zkontroluj log — měl bys vidět "MQTT Discovery odesláno" a
   pravidelné `STATE: {...}` zprávy každých ~60 sekund.
5. Entity se objeví v HA automaticky (MQTT Discovery), prefix `sensor.egd_elektromer_*`.

## Podporované elektroměry

Dle dokumentace EG.D: ZPA-AM175, Meter & Control ST402D, Sagemcom XT211
(push setup "On Schedule 2 / HAN", 9600 Bd, jednosměrná komunikace).

## Options

| Klíč | Popis | Výchozí |
|---|---|---|
| `mqtt_host` | Adresa MQTT brokeru | `core-mosquitto` |
| `mqtt_port` | Port MQTT brokeru | `1883` |
| `mqtt_username` | Uživatelské jméno MQTT | `homeassistant` |
| `mqtt_password` | Heslo MQTT | — |
| `serial_device` | Cesta k sériovému zařízení | `/dev/ttyUSB0` |
| `baud_rate` | Přenosová rychlost | `9600` |
| `frame_gap` | Mezera ticha (s) považovaná za konec rámce | `0.8` |
| `assume_no_export` | Instalace bez FVE/baterie nemůže reálně dodávat proud do sítě — zapni, aby se každé nenulové čtení "dodávka" polí zahodilo jako podezření na poškozený rámec (heuristický parser občas false-positive matchne vzor). Pokud FVE/baterii máš, nech vypnuté. | `false` |
