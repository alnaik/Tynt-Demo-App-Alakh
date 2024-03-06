//
//  BluetoothManager.swift
//  Tynt Demo
//
//  Created by Alakh Naik on 12/3/23.
//

import Foundation
import CoreBluetooth
import Combine

extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var discoveredDevices: [(peripheral: CBPeripheral, rssi: Int)] = [] {
            didSet {
                discoveredDevicesUpdatedCount += 1
            }
        }
    @Published var discoveredDevicesUpdatedCount = 0
    @Published var isBluetoothEnabled: Bool = false
    @Published var currentTintLevel: Int = 0 {
            didSet {
                print("currentTintLevel updated to: \(currentTintLevel)")
            }
        }
    @Published var goalTintLevel: Int = 0
    @Published var currentMotorState: Int = 0
    @Published var isConnected: Bool = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var currentTemp: Float = 0
    @Published var currentHumidity: Int = 0
    @Published var currIntLight: Float = 0
    @Published var currExtLight: Float = 0
    @Published var currExtTyntLight: Float = 0
    @Published var tempQueue: Queue<Float> = Queue()
    @Published var humidQueue: Queue<Float> = Queue()
    @Published var intLightQueue: Queue<Float> = Queue()
    @Published var extLightQueue: Queue<Float> = Queue()
    @Published var extTyntLightQueue: Queue<Float> = Queue()

    
    
    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected
        case failed
    }

    
    private var centralManager: CBCentralManager!
    private let defaults = UserDefaults.standard
    private var isScanning = false
    private var pendingCompletion: ((Bool) -> Void)?
        
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    //MARK: Central Manager Delegate Methods
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            isBluetoothEnabled = true
        case .poweredOff, .unauthorized, .unsupported, .unknown, .resetting:
            isBluetoothEnabled = false
            discoveredDevices.removeAll()
        @unknown default:
            isBluetoothEnabled = false
        }
    }

    
    
//    func startScanning() {
//            guard centralManager.state == .poweredOn, !isScanning else {
//                return
//            }
//            isScanning = true
//            discoveredDevices.removeAll()
//            centralManager.scanForPeripherals(withServices: nil, options: nil)
//            print("Scanning started")
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
//                self?.stopScanning()
//            }
//        }
    
    func startScanning() {
            guard centralManager.state == .poweredOn, !isScanning else {
                return
            }
            isScanning = true
            discoveredDevices.removeAll()
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            print("Scanning started")
            
            // Optionally, set a timeout for the scanning
//            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
//                self?.stopScanning()
//            }
        }
    
    func stopScanning() {
            if isScanning {
                centralManager.stopScan()
                isScanning = false
                print("Scanning stopped")
            }
        }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
            print("Peripheral connected: \(peripheral.name ?? "Unknown")")
            peripheral.delegate = self
            peripheral.discoverServices([CBUUIDs.cService_UUID, CBUUIDs.sService_UUID])
            DispatchQueue.main.async {
                self.isConnected = true
                self.connectionStatus = .connected
            }
        }

        func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
            print("Peripheral disconnected")
            DispatchQueue.main.async {
                self.isConnected = false
                self.connectionStatus = .disconnected
            }
        }

        func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
            print("Failed to connect to \(peripheral.name ?? "Unknown"): \(error?.localizedDescription ?? "Unknown error")")
            DispatchQueue.main.async {
                self.connectionStatus = .failed
            }
        }

    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Check if the device name includes 'tynt'
        if let name = peripheral.name, name.lowercased().contains("tynt") {
            print("Discovered Tynt device: \(name) with RSSI \(RSSI.intValue)")

            // Check if the device is already in the discoveredDevices array
            if let index = discoveredDevices.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }) {
                // Update RSSI value
                DispatchQueue.main.async {
                    self.discoveredDevices[index].rssi = RSSI.intValue
                }
            } else {
                // Add new device
                DispatchQueue.main.async {
                    self.discoveredDevices.append((peripheral: peripheral, rssi: RSSI.intValue))
                }
            }
        }
    }

    
    func connectToDevice(_ peripheral: CBPeripheral) {
        BlePeripheral.connectedPeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
        defaults.setValue(peripheral.identifier.uuidString, forKey: "LastConnectedUUID")
    }
    
    func disconnectFromDevice() {
        if let peripheral = BlePeripheral.connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
            BlePeripheral.connectedPeripheral = nil
        }
    }
    
    func reconnectToDevice() {
        if let lastConnectedUUIDString = defaults.string(forKey: "LastConnectedUUID"),
           let lastConnectedUUID = UUID(uuidString: lastConnectedUUIDString),
           let peripheral = centralManager.retrievePeripherals(withIdentifiers: [lastConnectedUUID]).first {
            connectToDevice(peripheral)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
        
        
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
            guard let characteristics = service.characteristics else { return }
            for characteristic in characteristics {
                print("Discovered characteristic: \(characteristic.uuid)")
                // Assign characteristics to BlePeripheral properties
                switch characteristic.uuid {
                case CBUUIDs.cService_Characteristic_uuid_StateOfTint:
                    BlePeripheral.SOTChar = characteristic
                case CBUUIDs.cService_Characteristic_uuid_GoalTint:
                    BlePeripheral.goalTintChar = characteristic
                case CBUUIDs.cService_Characteristic_uuid_DriveState:
                    BlePeripheral.DrvStChar = characteristic
                case CBUUIDs.cService_Characteristic_uuid_AutoMode:
                    BlePeripheral.autoTintChar = characteristic
                case CBUUIDs.cService_Characteristic_uuid_MotorOpen:
                    BlePeripheral.motorOpenChar = characteristic
                case CBUUIDs.cService_Characteristic_uuid_GoalMotorOpen:
                    BlePeripheral.goalMotorChar = characteristic
                case CBUUIDs.sService_Characteristic_uuid_Temp:
                    BlePeripheral.tempChar = characteristic
                case CBUUIDs.sService_Characteristic_uuid_Humid:
                    BlePeripheral.humidityChar = characteristic
                case CBUUIDs.sService_Characteristic_uuid_AmbLight:
                    BlePeripheral.ambLightChar = characteristic
                case CBUUIDs.sService_Characteristic_uuid_Accel:
                    BlePeripheral.accelChar = characteristic
                default: break
                }
                
                // Read and notify properties
                if characteristic.properties.contains(.read) {
                    peripheral.readValue(for: characteristic)
                }
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
        
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
                    print("Error reading characteristic: \(error.localizedDescription)")
                    return
                }

                guard let data = characteristic.value else {
                    print("No data received from characteristic \(characteristic.uuid)")
                    return
                }

//                print("Characteristic \(characteristic.uuid) updated value: \(data.hexEncodedString())")
        
        DispatchQueue.main.async {
            switch characteristic.uuid {
            case CBUUIDs.cService_Characteristic_uuid_StateOfTint:
                self.currentTintLevel = self.dataToInt(data)
                
            case CBUUIDs.cService_Characteristic_uuid_MotorOpen:
                self.currentMotorState = self.dataToInt(data)
                
            case CBUUIDs.cService_Characteristic_uuid_GoalTint:
                let goalLevel = self.dataToInt(data)
                self.goalTintLevel = goalLevel
                
            case CBUUIDs.cService_Characteristic_uuid_DriveState:
                if let data = characteristic.value {
                    // Process and handle Drive State data
                }
                
            case CBUUIDs.cService_Characteristic_uuid_AutoMode:
                if let data = characteristic.value {
                    // Process and handle Auto Mode data
                }
                
            case CBUUIDs.cService_Characteristic_uuid_GoalMotorOpen:
                if let data = characteristic.value {
                    // Process and handle Goal Motor Open data
                }
                
            case CBUUIDs.sService_Characteristic_uuid_Temp:
                if let data = characteristic.value {
                    // Process and handle Temperature data
                    let temp = self.parseTemp(data)
                    self.currentTemp = temp
                    self.logData(temp, type: "temp")
                }
                
            case CBUUIDs.sService_Characteristic_uuid_Humid:
                if let data = characteristic.value {
                    // Process and handle Humidity data
                    let temp = self.dataToInt(data)
                    self.currentHumidity = temp
                    self.logData(Float(temp), type: "humidity")
                }
                
            case CBUUIDs.sService_Characteristic_uuid_AmbLight:
                if let data = characteristic.value {
                    // Process and handle Ambient Light data
                    let temp = self.parseLight(data)
                    self.currIntLight = temp.0
                    self.currExtLight = temp.1
                    self.currExtTyntLight = temp.2
                    self.logData(temp.0, type: "intLight")
                    self.logData(temp.1, type: "extLight")
                }
                
            case CBUUIDs.sService_Characteristic_uuid_Accel:
                if let data = characteristic.value {
                    // Process and handle Accelerometer data
                }
                
            default:
                print("Unhandled Characteristic UUID: \(characteristic.uuid)")
            }
        }
    }
    
    private func logData(_ data: Float, type: String) -> Void {
        //Interval in seconds
        let interval = 5
//        if self.tempQueue.isEmpty {
//            self.tempQueue.enqueue(data)
//        }
        
        if type == "temp" {
            if let temp = self.tempQueue.peek() {
                if temp.time + Double(interval) < Date() {
                    self.tempQueue.enqueue(data)
                    //print("TIME ", temp.time, " TIME ADD ", temp.time + 60)
                }
            }
            else{
                self.tempQueue.enqueue(data)
            }
            //print(self.tempQueue.peek()?.value ?? 1234)
            //print(self.tempQueue.elements)
        }
        
        else if type == "humidity" {
            if let temp = self.humidQueue.peek() {
                if temp.time + Double(interval) < Date() {
                    self.humidQueue.enqueue(data)
                }
            }
            else{
                self.humidQueue.enqueue(data)
            }
        }
        
        else if type == "intLight" {
            if let temp = self.intLightQueue.peek() {
                if temp.time + Double(interval) < Date() {
                    self.intLightQueue.enqueue(data)
                }
            }
            else{
                self.intLightQueue.enqueue(data)
            }
        }
        
        else if type == "extLight" {
            if let temp = self.extLightQueue.peek() {
                if temp.time + Double(interval) < Date() {
                    self.extLightQueue.enqueue(data)
                }
            }
            else{
                self.extLightQueue.enqueue(data)
            }
        }
        else {
            print("Logging type error: ", type)
        }
    }
    
    private func dataToInt(_ data: Data) -> Int {
            let tintLevel = Int(data.first ?? 0)
            return tintLevel
        }
    private func parseTemp(_ data: Data) -> Float {
        //var va {lue: Float = 0.0
        let size = MemoryLayout<Float>.size
        //print("Unedited Bytes: \(data.map { String(format: "%02X", $0) }.joined())")

        guard data.count == 2 else {
            // terrible error handling
            //return nil
            return 1
        }

        let stringValue = data.map { String(format: "%02X", $0) }.joined()
        
        
        let chars = Array(stringValue)
        
        let b1 = String(chars[0]) + String(chars[1])
        let b2 = String(chars[2]) + String(chars[3])
        
        let a = Int(b1, radix: 16)!
        let b = Int(b2, radix: 16)!
        
        let v = a + (b<<8)
        
        if v > 32768 {
            let r = 65536 - v
            return (Float(r) / 10)*(-1)
        }
        else {
            return Float(v) / 10
        }

    }
    
    private func parseLight(_ data: Data) -> (Float, Float, Float) {
        let size = MemoryLayout<Float>.size
        //print("Unedited Bytes: \(data.map { String(format: "%02X", $0) }.joined())")

        guard data.count == 12 else {
            //TODO: fix error handling
            //return nil
            return (1,1,1)
        }

        let stringValue = data.map { String(format: "%02X", $0) }.joined()
        //print("Unedited Bytes: \(data.map { String(format: "%02X", $0) }.joined())")
        
        let intLightBytes = stringValue.prefix(8)
        let extLightBytes = stringValue.dropFirst(8).prefix(8)
        let extTintBytes = stringValue.suffix(8)
        
        let tempintLight = convertALCToInt(bytes: String(intLightBytes))
        let tempextLight = convertALCToInt(bytes: String(extLightBytes))
        let tempextTintedLight = convertALCToInt(bytes: String(extTintBytes))
        return (tempintLight, tempextLight, tempextTintedLight)
        
    }
    
    func convertALCToInt(bytes: String) -> Float{
    
        let s = Array(bytes)
    
        let s1 = String(s[0]) + String(s[1])
        let s2 = String(s[2]) + String(s[3])
        let s3 = String(s[4]) + String(s[5])
        let s4 = String(s[6]) + String(s[7])
    
        let a = Int(s1, radix: 16)!
        let b = Int(s2, radix: 16)!
        let c = Int(s3, radix: 16)!
        let d = Int(s4, radix: 16)!
    
        let result = Float(a + (b<<8) + (c<<16) + (d<<24))
    
        return (result/100)
    }

    
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
            if let error = error {
                print("Error reading RSSI: \(error.localizedDescription)")
                return
            }
            
            // Handle the RSSI value
        }
        
    func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType, completion: ((Bool) -> Void)? = nil) {
        guard let peripheral = BlePeripheral.connectedPeripheral else {
            print("No connected peripheral to write to")
            completion?(false)
            return
        }
        peripheral.writeValue(data, for: characteristic, type: type)
        self.pendingCompletion = completion
    }

        // CBPeripheralDelegate method to confirm that the data was written
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error writing characteristic \(characteristic.uuid): \(error.localizedDescription)")
            pendingCompletion?(false)
        } else {
            print("Successfully wrote value to characteristic \(characteristic.uuid)")
            pendingCompletion?(true)
        }
        pendingCompletion = nil
    }
        
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
            if let error = error {
                print("Error updating notification state for characteristic: \(error.localizedDescription)")
                return
            }
            
            // Handle the notification state update
        }
    func removeDevice(_ peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            if let index = self.discoveredDevices.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }),
               index < self.discoveredDevices.count {
                self.discoveredDevices.remove(at: index)
            }
        }
    }
    
    func writeTintLevel(_ level: Int, completion: ((Bool) -> Void)? = nil) {
        guard let tintChar = BlePeripheral.goalTintChar else {
            print("Goal Tint Characteristic not found")
            completion?(false)
            return
        }
        var levelByte = UInt8(level)
        let data = Data(bytes: &levelByte, count: 1)
        print("Writing tint level: \(level) to characteristic: \(tintChar.uuid)")
        writeValue(data, for: tintChar, type: .withResponse, completion: completion)
    }

    func writeMotorState(_ state: Int, completion: ((Bool) -> Void)? = nil) {
        guard let motorChar = BlePeripheral.goalMotorChar else {
            print("Motor Characteristic not found")
            completion?(false)
            return
        }
        var stateByte = UInt8(state)
        let data = Data(bytes: &stateByte, count: 1)
        writeValue(data, for: motorChar, type: .withResponse) { success in
            completion?(success)
        }
    }
    
    func retrievePeripheral(withUUID uuidString: String) -> CBPeripheral? {
            guard let uuid = UUID(uuidString: uuidString) else { return nil }
            let peripherals = centralManager.retrievePeripherals(withIdentifiers: [uuid])
            return peripherals.first
        }
    
    
}

struct ValueTimePair<T> {
    let value: T
    let time: Date
    
    init(value: T, time: Date = Date()) {
        self.value = value
        self.time = time
    }
}

struct Queue<T> {
    var elements: [ValueTimePair<T>] = []
    private let maxSize = 10
    
    
    // Enqueue adds an element at the end of the queue. If the queue is full,
    // it removes the oldest element before adding the new one.
    mutating func enqueue(_ value: T) {
        let pair = ValueTimePair(value: value)
        // Check if the queue has reached its maximum size
        if elements.count >= maxSize {
            // Remove the oldest element
            _ = dequeue()
        }
        // Add the new element
        elements.insert(pair, at: 0)
    }
    
    // Dequeue removes and returns the first element of the queue, if it exists
    mutating func dequeue() -> ValueTimePair<T>? {
        guard !elements.isEmpty else { return nil }
        return elements.removeLast()
    }
    
    // Peek returns the first element without removing it, if it exists
    func peek() -> ValueTimePair<T>? {
        elements.first
    }
    
    func peek(at index: Int) -> ValueTimePair<T>? {
        guard index >= 0 && index < elements.count else { return nil }
        return elements[index]
    }
    
    // Checks if the queue is empty
    var isEmpty: Bool {
        elements.isEmpty
    }
    
    // Returns the number of elements in the queue
    var count: Int {
        elements.count
    }
}



//    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
//        guard let services = peripheral.services else { return }
//        for service in services {
//            // Discover characteristics for each service
//            peripheral.discoverCharacteristics(nil, for: service)
//        }
//    }
//
//    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
//        guard let characteristics = service.characteristics else { return }
//        for characteristic in characteristics {
//            // Assigning characteristics to corresponding variables in BlePeripheral
//            switch characteristic.uuid {
//                case CBUUIDs.cService_Characteristic_uuid_StateOfTint:
//                    BlePeripheral.SOTChar = characteristic
//                // ... Handle other characteristics ...
//                default:
//                    break
//            }
//        }

