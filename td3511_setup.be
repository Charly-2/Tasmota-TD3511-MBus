# Create a driver instance and register as Tasmota Driver

# Parameters
# RX-Pin for Serial IR-Reader
# TX-Pin for Serial IR-Reader
# AES-KEY for Smart-meter decryption 16 Bytes from your Power-Net-Provider
# ID for this Smart-Meter in MQTT-Messages and on the Main-View

# Zähler Haushalt
td3511_HH=TD3511MBUS(46,45,bytes('11C5151F9CB6EFD13E411B815CD62769'), "Z1")
tasmota.add_driver(td3511_HH)
print("Driver td3511_HH:TD3511MBUS initialized")

# Zähler Wärmepumpe
td3511_WP=TD3511MBUS(34,33,bytes('A565E478A868A079805E54D436FE99E2'), "Z2")
tasmota.add_driver(td3511_WP)
print("Driver td3511_WP:TD3511MBUS initialized")
