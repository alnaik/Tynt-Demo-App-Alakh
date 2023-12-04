//
//  BlePeripheral.swift
//
//  Created by Arjun on 6/11/23.
//

import Foundation
import CoreBluetooth

class BlePeripheral {
    static var connectedPeripheral: CBPeripheral?
    static var connectedControlService: CBService?
    static var connectedSensorService: CBService?
    static var goalTintChar: CBCharacteristic?
    static var SOTChar: CBCharacteristic?
    static var DrvStChar: CBCharacteristic?
    static var autoTintChar: CBCharacteristic?
    static var motorOpenChar: CBCharacteristic?
    static var goalMotorChar: CBCharacteristic?
    static var tempChar: CBCharacteristic?
    static var humidityChar: CBCharacteristic?
    static var ambLightChar: CBCharacteristic?
    static var accelChar: CBCharacteristic?
}
