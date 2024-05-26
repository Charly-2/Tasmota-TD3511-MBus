#
load("td3511_mbus")

# Create a td3511 Instance
td3511=TD3511MBUS()
#Register as Tasmota-Driver and start
tasmota.add_driver(td3511)
