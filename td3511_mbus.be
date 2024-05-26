# Berry Script for Smart-Meter Siemens TD-3511 in Upper Austria (Netz OÖ)
# Read Values via M-Bus-Protocol every Second
class TD3511MBUS : Driver
	# serial port
	var ser
	# max number for reading more data
	var reread_count
	# AES-Key
	static var key = bytes('11C5151F9CB6EFD13E411B815CD62769')
	# Values from smart meter
	var zeit
	var datum
	var r_1_7_0
	var r_2_7_0
	var r_3_7_0
	var r_4_7_0
	var r_1_8_0
	var r_2_8_0
	var r_3_8_1
	var r_4_8_1
	var r_1_128_0
	
	
	#Constructor
	def init(rx, tx)
		self.reread_count = 0
		self.zeit = ""
		self.datum = ""
		self.r_1_7_0 = 0.0
		self.r_2_7_0 = 0.0
		self.r_1_8_0 = 0.0
		self.r_2_8_0 = 0.0
		self.r_3_7_0 = 0.0
		self.r_4_7_0 = 0.0
		self.r_1_8_0 = 0.0
		self.r_2_8_0 = 0.0
		self.r_3_8_1 = 0.0
		self.r_4_8_1 = 0.0
		self.r_1_128_0 = 0.0
		# default if nil
		if !tx tx=45 end
		if !rx rx=46 end
		self.ser = serial(rx,tx,9600,serial.SERIAL_8E1)
	end
	
	def tddecode(message)
		# decode a MBus-Message with smartmeter data
		import crypto
		import string
		
		if message.size() != 101 return "wrong message size:" + str(message.size()) end
		#print(message.tohex())
		var iv = bytes(16)
		iv = message[11..12] + message[7..10] + message[13..14]
		for i: 0 .. 7
			iv.add(message[15])
		end
		var payload = message[19..98]
		#print("iv: " + iv.tohex())
		#print("key:" + self.key.tohex())
		#print("enc:" + payload.tohex())
		var aes = crypto.AES_CBC()
		aes.decrypt1(self.key, iv, payload)
		#print("dec:" + payload.tohex())
		if payload[0..1] != bytes('2F2F') return "wrong decoded message format" end
		# decode the values
		#print("1.7.0 : " + payload[44..47])
		var v_0_9_12_all = payload[4..9]
		#print("0.9.1+0.9.2 : " + v_0_9_12_all.tohex())
		var v_0_9_1_sec = v_0_9_12_all[0] & 0x3F
		var v_0_9_1_min = v_0_9_12_all[1] & 0x3F
		var v_0_9_1_hour = v_0_9_12_all[2] & 0x1F
		var v_0_9_1_day = v_0_9_12_all[3] & 0x1F
		var v_0_9_1_mon = (v_0_9_12_all[4] & 0x0F)
		var v_0_9_1_year = ((v_0_9_12_all[3] & 0xE0) >>5 ) | ((v_0_9_12_all[4] & 0xF0) >>1) + 2000
		var v_1_7_0 = payload[44..47].get(0,4)
		var v_2_7_0 = payload[51..54].get(0,4)
		var v_1_8_0 = payload[12..15].get(0,4)
		var v_2_8_0 = payload[19..22].get(0,4)
		var v_3_7_0 = payload[58..61].get(0,4)
		var v_4_7_0 = payload[66..59].get(0,4)
		var v_3_8_1 = payload[28..31].get(0,4)
		var v_4_8_1 = payload[38..41].get(0,4)
		var v_1_128_0 = payload[74..77].geti(0,4)
		self.zeit = string.format("%02d:%02d:%02d",v_0_9_1_hour, v_0_9_1_min, v_0_9_1_sec)
		self.datum = string.format("%04d-%02d-%02d",v_0_9_1_year, v_0_9_1_mon, v_0_9_1_day)
		print("Zeit:" + self.zeit)
		print("Datum:" + self.datum)
		self.r_1_7_0 = v_1_7_0
		self.r_2_7_0 = v_2_7_0
		self.r_1_8_0 = v_1_8_0/1000.0
		self.r_2_8_0 = v_2_8_0/1000.0
		self.r_3_7_0 = v_3_7_0
		self.r_4_7_0 = v_4_7_0	
		self.r_3_8_1 = v_3_8_1
		self.r_4_8_1 = v_4_8_1
		self.r_1_128_0 = v_1_128_0/1000.0
		print(string.format("1.7.0   : %9d W", self.r_1_7_0))
		print(string.format("2.7.0   : %9d W", self.r_2_7_0))
		print(string.format("1.8.0   : %9.3f kWh", self.r_1_8_0))
		print(string.format("2.8.0   : %9.3f kWh", self.r_2_8_0))
		print(string.format("3.7.0   : %9d var", self.r_3_7_0))
		print(string.format("4.7.0   : %9d var", self.r_4_7_0))
		print(string.format("3.8.1   : %9d varh", self.r_3_8_1))
		print(string.format("4.8.1   : %9d varh", self.r_4_8_1))
		print(string.format("1.128.0 : %9.3f kWh", self.r_1_128_0))
		return "OK"
	end

	def tdread()
	# read data from serial line and interpret content  
	import string 
		if self.ser.available()<5 
			return
			#return "no data(<5)" 
		end
		if self.ser.available()==5 && self.ser.read()==bytes('1040F03016') 
		  # got Slave-Query from Master for Adress 240(F0)
		  self.ser.write(bytes('E5'))
		  print("got SND_NKE, sent ACK")
		  return 
		end
		if self.ser.available()> 5 && self.ser.available() <101
			# we got not enough data
			# wait for more data max 5 times
			self.reread_count += 1
			if self.reread_count > 5
				#read and drop data
				self.ser.read()
				self.reread_count = 0
				print("droped wrong size message")
				return 
			end
			print("waiting for more data..." )
			return 
		end
		if self.ser.available()>101
			#got too much, empty buffer
			#return str(ser.available()) + ":" + ser.read().tohex() 
			self.ser.read()
			return
		end
		if self.ser.available()==101 
			# we got a SND_UD with data?
			var message = self.ser.read()
			#print(message.tohex())
			if message[0] != 0x68
				return "wrong message StartByte:" + string.hex(message[0])
			end
			if message[1] != message[2]
				return "LengthBytes differ" + string.hex(message[1..2])
			end
			if message[100] != 0x16
				return "wrong message EndByte:" + string.hex(message[100])
			end
			# Send ACK to get next message
			self.ser.write(bytes('E5'))
			# decode the message
			print(self.tddecode(message))
			return 
		end
		print("unknown state: " + str(self.ser.available()) + ":" + self.ser.read().tohex())
		return 
	end
	
	#- display  values in the web UI -#
	def web_sensor()
		if !self.ser return nil end
		import string
		var msg = string.format(
				 "{s}Z1 Time{m}%s"..
				 "{s}Z1 Date{m}%s"..
				 "{s}Z1 1.7.0{m} %.0f W{e}"..
				 "{s}Z1 2.7.0{m} %.0f W{e}"..
				 "{s}Z1 1.7.0 - 2.7.0{m} %.0f W{e}"..
				 "{s}Z1 1.8.0{m} %9.3f kWh{e}"..
				 "{s}Z1 2.8.0{m} %9.3f kWh{e}"..
				 "{s}Z1 3.7.0{m} %.0f var{e}"..
				 "{s}Z1 4.7.0{m} %.0f var{e}"..
				 "{s}Z1 3.8.1{m} %.0f varh{e}"..
				 "{s}Z1 4.8.1{m} %.0f varh{e}"..
				 "{s}Z1 1.128.0{m} %9.3f kWh{e}",
				  self.zeit,self.datum, 
				  self.r_1_7_0,
				  self.r_2_7_0,
				  self.r_1_7_0 - self.r_2_7_0,
				  self.r_1_8_0,
				  self.r_2_8_0,
				  self.r_3_7_0,
				  self.r_4_7_0,
				  self.r_3_8_1,
				  self.r_4_8_1,
				  self.r_1_128_0
				  )
		# send to gui with decimal point as locale defined
		tasmota.web_send_decimal(msg)
	end
	
	#- add smart meter value to teleperiod -#
	def json_append()
		import string
		var msg = string.format(",\"Z1\":{\"time\":\"%s\",\"date\":\"%s\",\"Total_in\":%9.3f,\"Total_out\":%9.3f,\"P_in\":%.0f,\"P_out\":%.0f,\"P_total\":%.0f}",
				  self.zeit, self.datum,
				  self.r_1_8_0,
				  self.r_2_8_0,
				  self.r_1_7_0,
				  self.r_2_7_0,
				  self.r_1_7_0 - self.r_2_7_0)
		tasmota.response_append(msg)
	end	
	
	# Called by tasmota every X ms
	def every_100ms()
		self.tdread()
	end

end