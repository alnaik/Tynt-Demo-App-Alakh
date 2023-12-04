//
//  CBUUIDs.swift
//
//  Created by Arjun on 6/11/23.
//

import Foundation
import CoreBluetooth

struct CBUUIDs{
    
    static let MaxCharacters = 20

    // Tynt Control Service
    static let controlService_UUID = "00001523-1212-EFDE-1523-785FEABCD123" //6e400001-b5a3-f393-e0a9-e50e24dcca9e"
    static let cService_Characteristic_uuid_SOT_Perc = "00001524-1212-EFDE-1523-785FEABCD123" //SOT percent Char
    static let cService_Characteristic_uuid_Goal_Perc = "00001525-1212-EFDE-1523-785FEABCD123" //Goal Percent Char
    static let cService_Characteristic_uuid_Drv_State = "00001526-1212-EFDE-1523-785FEABCD123" //Drive State Char
    static let cService_Characteristic_uuid_Auto_Mode = "00001527-1212-EFDE-1523-785FEABCD123" //Auto Mode Char
    static let cService_Characteristic_uuid_MO_Perc = "00001528-1212-EFDE-1523-785FEABCD123" //Motor Open Percent Char
    static let cService_Characteristic_uuid_GMO_Perc = "00001529-1212-EFDE-1523-785FEABCD123" //Goal Motor Open Percent Char

    static let cService_UUID = CBUUID(string: controlService_UUID)
    static let cService_Characteristic_uuid_StateOfTint = CBUUID(string: cService_Characteristic_uuid_SOT_Perc) // (Property = Read/Notify)
    static let cService_Characteristic_uuid_GoalTint = CBUUID(string: cService_Characteristic_uuid_Goal_Perc) //(Property = Write without response)
    static let cService_Characteristic_uuid_DriveState = CBUUID(string: cService_Characteristic_uuid_Drv_State) // (Property = Read/Notify)
    static let cService_Characteristic_uuid_AutoMode = CBUUID(string: cService_Characteristic_uuid_Auto_Mode) //(Property = Write without response)
    static let cService_Characteristic_uuid_MotorOpen = CBUUID(string:
        cService_Characteristic_uuid_MO_Perc) //(Property = Read/Notify)
    static let cService_Characteristic_uuid_GoalMotorOpen = CBUUID(string:
        cService_Characteristic_uuid_GMO_Perc) //(Property = Write without response)
    
    //Tynt Sensor Service
    static let sensorService_UUID = "00001623-1212-EFDE-1523-785FEABCD123"
    static let sService_Characteristic_uuid_Temperature = "00001624-1212-EFDE-1523-785FEABCD123" //Temperature Char
    static let sService_Characteristic_uuid_Humidity = "00001625-1212-EFDE-1523-785FEABCD123" //Humidity Char
    static let sService_Characteristic_uuid_Ambient_Light = "00001626-1212-EFDE-1523-785FEABCD123" //Ambient Light Char
    static let sService_Characteristic_uuid_Accelerometer = "00001627-1212-EFDE-1523-785FEABCD123" //Accelerometer Char
    
    static let sService_UUID = CBUUID(string: sensorService_UUID)
    static let sService_Characteristic_uuid_Temp = CBUUID(string: sService_Characteristic_uuid_Temperature) // (Property = Read/Notify)
    static let sService_Characteristic_uuid_Humid = CBUUID(string: sService_Characteristic_uuid_Humidity) // (Property = Read/Notify)
    static let sService_Characteristic_uuid_AmbLight = CBUUID(string: sService_Characteristic_uuid_Ambient_Light) // (Property = Read/Notify)
    static let sService_Characteristic_uuid_Accel = CBUUID(string: sService_Characteristic_uuid_Accelerometer) // (Property = Read/Notify)
}
