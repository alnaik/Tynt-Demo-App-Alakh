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
    @Published var discoveredDevices: [(peripheral: CBPeripheral, rssi: Int)] = []
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

                print("Characteristic \(characteristic.uuid) updated value: \(data.hexEncodedString())")
        
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
                }
                
            case CBUUIDs.sService_Characteristic_uuid_Humid:
                if let data = characteristic.value {
                    // Process and handle Humidity data
                }
                
            case CBUUIDs.sService_Characteristic_uuid_AmbLight:
                if let data = characteristic.value {
                    // Process and handle Ambient Light data
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
    
    private func dataToInt(_ data: Data) -> Int {
            let tintLevel = Int(data.first ?? 0)
            print("Converted Tint Level from Data: \(tintLevel)")
            return tintLevel
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

