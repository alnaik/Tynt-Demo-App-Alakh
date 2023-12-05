//
//  BluetoothManager.swift
//  Tynt Demo
//
//  Created by Alakh Naik on 12/3/23.
//

import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var discoveredDevices: [(peripheral: CBPeripheral, rssi: Int)] = []
    @Published var isBluetoothEnabled: Bool = false
    private var centralManager: CBCentralManager!
    private let defaults = UserDefaults.standard
    private var isScanning = false
    
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

    
    
    func startScanning() {
            guard centralManager.state == .poweredOn, !isScanning else {
                return
            }
            isScanning = true
            discoveredDevices.removeAll()
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            print("Scanning started")

            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                self?.stopScanning()
            }
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
    }

    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Check if the device name includes 'tynt'
        if let name = peripheral.name, name.lowercased().contains("tynt") {
            print("Discovered Tynt device: \(name) with RSSI \(RSSI.intValue)")

            // Check if the device is not already in the discoveredDevices array
            if !discoveredDevices.contains(where: { $0.peripheral.identifier == peripheral.identifier }) {
                DispatchQueue.main.async {
                    self.discoveredDevices.append((peripheral: peripheral, rssi: RSSI.intValue))
                }
            } else {
                print("Duplicate device found: \(name)")
            }
        }
    }

    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        // Handle connection errors
        print("Failed to connect to \(peripheral.name ?? "Unknown"): \(error?.localizedDescription ?? "")")
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
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
        
        
        func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
            guard let characteristics = service.characteristics else { return }
            for characteristic in characteristics {
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
            guard error == nil else {
                print("Error reading characteristic: \(characteristic.uuid): \(error!.localizedDescription)")
                return
            }
            
            if let value = characteristic.value {
                    print("Characteristic \(characteristic.uuid): \(value as NSData)")
                }
            
            // Handle the characteristic value update
            switch characteristic.uuid {
            case CBUUIDs.cService_Characteristic_uuid_StateOfTint:
                if let data = characteristic.value {
                    // Process and handle State of Tint data
                }
                
            case CBUUIDs.cService_Characteristic_uuid_GoalTint:
                if let data = characteristic.value {
                    // Process and handle Goal Tint data
                }
                
            case CBUUIDs.cService_Characteristic_uuid_DriveState:
                if let data = characteristic.value {
                    // Process and handle Drive State data
                }
                
            case CBUUIDs.cService_Characteristic_uuid_AutoMode:
                if let data = characteristic.value {
                    // Process and handle Auto Mode data
                }
                
            case CBUUIDs.cService_Characteristic_uuid_MotorOpen:
                if let data = characteristic.value {
                    // Process and handle Motor Open data
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
        func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
            if let error = error {
                print("Error reading RSSI: \(error.localizedDescription)")
                return
            }
            
            // Handle the RSSI value
        }
        
        func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
            if let error = error {
                print("Error writing value to characteristic: \(error.localizedDescription)")
                return
            }
            
            // Handle the confirmation of write
        }
        
        func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
            if let error = error {
                print("Error updating notification state for characteristic: \(error.localizedDescription)")
                return
            }
            
            // Handle the notification state update
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

