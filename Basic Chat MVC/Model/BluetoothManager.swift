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
    private var bluetoothPeripheral: CBPeripheral?

    private var goalTintChar: CBCharacteristic?
    private var SOTChar: CBCharacteristic?
    private var DrvStChar: CBCharacteristic?
    private var autoTintChar: CBCharacteristic?
    private var tempChar: CBCharacteristic?
    private var humidityChar: CBCharacteristic?
    private var ambLightChar: CBCharacteristic?
    private var accelChar: CBCharacteristic?

    private let defaults = UserDefaults.standard

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

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
        discoveredDevices.removeAll()
        centralManager.scanForPeripherals(withServices: nil, options: nil) // Scan for all devices
        print("Scanning started")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.centralManager.stopScan()
            print("Scanning stopped")
        }
    }

    func stopScanning() {
        centralManager.stopScan()
        print("Scanning stopped")
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
            print("Peripheral connected: \(peripheral.name ?? "Unknown")")
            bluetoothPeripheral = peripheral
            peripheral.delegate = self
            peripheral.discoverServices([CBUUIDs.cService_UUID, CBUUIDs.sService_UUID])
        }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
            // Check if the device name includes 'tynt'
            if let name = peripheral.name?.lowercased(), name.contains("tynt") {
                print("Discovered Tynt device: \(peripheral.name ?? "Unknown") with RSSI \(RSSI.intValue)")
                if !discoveredDevices.contains(where: { $0.peripheral.identifier == peripheral.identifier }) {
                    DispatchQueue.main.async {
                        self.discoveredDevices.append((peripheral: peripheral, rssi: RSSI.intValue))
                    }
                }
            }
        }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
            // Handle connection errors
            print("Failed to connect to \(peripheral.name ?? "Unknown"): \(error?.localizedDescription ?? "")")
        }

    func connectToDevice(_ peripheral: CBPeripheral) {
            bluetoothPeripheral = peripheral
            centralManager.connect(peripheral, options: nil)
            defaults.setValue(peripheral.identifier.uuidString, forKey: "LastConnectedUUID")
            print("Attempting to connect to \(peripheral.name ?? "Unknown")")
        }

    func disconnectFromDevice() {
            if let peripheral = bluetoothPeripheral {
                centralManager.cancelPeripheralConnection(peripheral)
                print("Disconnected from \(peripheral.name ?? "Unknown")")
            }
        }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            switch characteristic.uuid {
                case CBUUIDs.cService_Characteristic_uuid_StateOfTint:
                    SOTChar = characteristic
                case CBUUIDs.cService_Characteristic_uuid_DriveState:
                    DrvStChar = characteristic
                // cases for other characteristics
                default: break
            }

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
            print("Error updating value for characteristic: \(error.localizedDescription)")
            return
        }
        
        // Handle the characteristic value update
        
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

