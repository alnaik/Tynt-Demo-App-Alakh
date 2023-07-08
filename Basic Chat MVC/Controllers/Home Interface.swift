//
//  Home Interface.swift
//  Tynt Demo
//
//  Created by Arjun on 6/11/23.
//

import UIKit
import SwiftUI
import CoreBluetooth

class Home_Interface: UIViewController {
    
    
    //MARK: Outlets/Variables
    
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var statusText: UILabel!
    @IBOutlet weak var sensorData: UIButton!
    @IBOutlet weak var pairing: UIButton!
    @IBOutlet weak var tintValue: UILabel!
    @IBOutlet weak var tintProgress: UIProgressView!
    
    var goalTintLevel: Int!
    var tintProgressLength: Int!
    var currentTintLevel = -1
    
    var driveState: String! = ""
    var autoTintChar: String! = ""
    var temp: Float!
    var humidity: Float!
    var intLight: Float!
    var extLight: Float!
    var extTintedLight: Float!
    var opticTrans: Float!
    var accelChar: String! = ""
    
    var deviceDisconnected: Bool! = false //only for use for adequate handling of disconnection in Sensor Data Interface
    
    var timer = Timer()
    
    
    //MARK: - ViewDidLoad

    override func viewDidLoad() {
        super.viewDidLoad()
        
        slider.transform = CGAffineTransform(rotationAngle: CGFloat.pi / -2)
        
        slider.isEnabled = false
        
        sensorData.isEnabled = false
        
        tintValue.text = "\u{2014}% Tint"
        statusText.text = "\u{2014}"
        
        sensorData.setTitle("", for: .normal)
        pairing.setTitle("", for: .normal)
        
        tintProgress.progress = 0
        tintProgress.isHidden = true
        
        update()
        
        if deviceDisconnected {
            disconnected()
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { _ in
            switch BlePeripheral.connectedPeripheral!.state {
            case .disconnected:
                self.disconnected()
            case .disconnecting:
                self.disconnected()
            case .connecting:
                print("Still connecting")
            case.connected:
                self.update()
            @unknown default:
                print("Unknown error")
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        addObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        removeObservers()
        timer.invalidate()
    }
    
    
    // MARK: - Functions
    
    func writeOutgoingValue(value: inout Int) {
        let data = Data(bytes: &value, count: 1)
        //change the "data" to valueString
        if let blePeripheral = BlePeripheral.connectedPeripheral {
            if let goalTintChar = BlePeripheral.goalTintChar {
                blePeripheral.writeValue(data, for: goalTintChar, type: CBCharacteristicWriteType.withResponse)
            }
        }
    }
    
    func update() {
        
        if currentTintLevel != -1 {
            
            slider.isEnabled = true
        }
        
        if goalTintLevel != nil {
            tintProgress.progress = ( 1 - ((Float(abs(goalTintLevel - currentTintLevel)) / Float(tintProgressLength!))))
        }
        else if goalTintLevel == nil {
            tintProgress.progress = 0
            slider.value = Float(currentTintLevel)
            tintValue.text = String(Int(round(slider.value))) + "% Tint"
        }
        
        if driveState == "02" {
            statusText.text = "Bleaching: " + String(currentTintLevel) + "% Tint"
            tintProgress.isHidden = false
        }
        else if driveState == "01" {
            statusText.text = "Tinting: " + String(currentTintLevel) + "% Tint"
            tintProgress.isHidden = false
        }
        else if driveState == "00" {
            statusText.text = "Idle"
            slider.value = Float(currentTintLevel)
            tintValue.text = String(currentTintLevel) + "% Tint"
            tintProgress.progress = 0
            tintProgress.isHidden = true
        }
        else if driveState == "03" {
            statusText.text = "Working..."
            tintProgress.isHidden = true
        }
        
        print("updated (home interface)")
        
    }
    
    @IBAction func writeValueToInterface(_ sender: UISlider) {
        tintValue.text = String(Int(round(slider.value))) + "% Tint"
    }
    
    @IBAction func valueOut(_ sender: Any) {
        
        switch BlePeripheral.connectedPeripheral!.state {
        case .disconnected:
            self.disconnected()
        case .disconnecting:
            self.disconnected()
        case .connecting:
            print("Still connecting")
        case.connected:
            self.slider.isEnabled = true
            self.sensorData.isEnabled = true
            self.pairing.isEnabled = true
            
            var val = Int(round(self.slider.value))
            let cur = Int(self.currentTintLevel)
                    
            if val != self.currentTintLevel {
                        
                self.tintProgress.progress = 0
                self.driveState = "03"
                self.goalTintLevel = val
                self.tintProgressLength = abs(self.goalTintLevel - cur)
                        
                self.writeOutgoingValue(value: &val)
            }
        @unknown default:
            print("Unknown error")
        }
    
    }
    
    @IBAction func sensorDataPressed(_ sender: Any) {
        
        switch BlePeripheral.connectedPeripheral!.state {
        case .disconnected:
            disconnected()
        case .disconnecting:
            disconnected()
        case .connecting:
            print("Still connecting")
        case.connected:
            performSegue(withIdentifier: "homeToData", sender: nil)
        @unknown default:
            print("Unknown error")
        }
        
    }
    
    
    func separateAmbLightChar(rawChar: String) {
        
        let bytes = rawChar.components(separatedBy: " ")
        
        let intLightBytes = bytes[0]
        let extLightBytes = bytes[1]
        let extTintBytes = bytes[2]
        
        let i = Float(Int(intLightBytes, radix: 16)!)
        intLight = i / 100
        
        let e = Float(Int(extLightBytes, radix: 16)!)
        extLight = e / 100
        
        let et = Float(Int(extTintBytes, radix: 16)!)
        extTintedLight = et / 100
        
        let x = (et / e) * 1000
        opticTrans = (roundf(x) / 10.0)
        
    }
    
    func disconnected() {
        slider.isEnabled = false
        sensorData.isEnabled = false
        pairing.isEnabled = true
        tintProgress.isHidden = true
        tintValue.text = "\u{2014}% Tint"
        slider.value = 0
        statusText.text = "Device disconnected. Please reconnect."
        timer.invalidate()
    }
    
    func addObservers() {
        //order of observers must be maintained to keep from unwrapping nil optional when navigating to Sensor Data Interface
        NotificationCenter.default.addObserver(self, selector: #selector(self.parseSOTPerc(notification:)), name: NSNotification.Name(rawValue: "NotifySOTP"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.parseDrvSt(notification:)), name: NSNotification.Name(rawValue: "NotifyDrvSt"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.parseATSChar(notification:)), name: NSNotification.Name(rawValue: "NotifyATS"), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(self.parseTempChar(notification:)), name: NSNotification.Name(rawValue: "NotifyTemp"), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(self.parseHumidityChar(notification:)), name: NSNotification.Name(rawValue: "NotifyHumidity"), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(self.parseAmbLightChar(notification:)), name: NSNotification.Name(rawValue: "NotifyAL"), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(self.parseAccelChar(notification:)), name: NSNotification.Name(rawValue: "NotifyAccel"), object: nil)
        
//        NotificationCenter.default.addObserver(self, selector: #selector(self.parseGT(notification:)), name: NSNotification.Name(rawValue: "NotifyGT"), object: nil)
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NotifyATS"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NotifyTemp"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NotifyHumidity"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NotifyAL"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NotifySOTP"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NotifyAccel"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NotifyDrvSt"), object: nil)
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NotifyGT"), object: nil)
    }
    
    //MARK: - Parse Functions
    
    @objc func parseSOTPerc(notification: Notification) -> Void{
        
        var text = String(describing: notification.object)
        text = text.replacingOccurrences(of: "Optional(<", with: "")
        text = text.replacingOccurrences(of: ">)", with: "")
        
        let cur = Int(text, radix: 16)!
        currentTintLevel = cur
        
        slider.isEnabled = true
        
        print(text + " : SOT from home")
        
    }
    
    @objc func parseDrvSt(notification: Notification) -> Void {
        
        var text = String(describing: notification.object)
        text = text.replacingOccurrences(of: "Optional(<", with: "")
        text = text.replacingOccurrences(of: ">)", with: "")
        
        driveState = text
        
        print(text + " : drvStChar from home")
        
    }
    
    @objc func parseATSChar(notification: Notification) -> Void {
        var text = String(describing: notification.object)
        text = text.replacingOccurrences(of: "Optional(<", with: "")
        text = text.replacingOccurrences(of: ">)", with: "")
        
        autoTintChar = text
        
        print(text + ": ATSChar from home")
    }
    
    @objc func parseTempChar(notification: Notification) -> Void {
        var text = String(describing: notification.object)
        text = text.replacingOccurrences(of: "Optional(<", with: "")
        text = text.replacingOccurrences(of: ">)", with: "")
        
        let chars = Array(text)
        
        let b1 = String(chars[0]) + String(chars[1])
        let b2 = String(chars[2]) + String(chars[3])
        
        let a = Int(b1, radix: 16)!
        let b = Int(b2, radix: 16)!
        
        let v = Float(a + (256*b))
        temp = v / 10
        
        print(String(temp) + " : tempChar from home")
        
        //MARK: - Handle Signed Bits
        
    }
    
    @objc func parseHumidityChar(notification: Notification) -> Void {
        var text = String(describing: notification.object)
        text = text.replacingOccurrences(of: "Optional(<", with: "")
        text = text.replacingOccurrences(of: ">)", with: "")
        
        let t = Int(text, radix: 16)!
        let value = Float(t)
        humidity = value
        
        print(text + " : humidityChar from home")
        
    }
    
    @objc func parseAmbLightChar(notification: Notification) -> Void {
        var text = String(describing: notification.object)
        text = text.replacingOccurrences(of: "Optional(<", with: "")
        text = text.replacingOccurrences(of: ">)", with: "")
        
        separateAmbLightChar(rawChar: text)
        
        print(text + " : ambLightChar from home")
    }
    
    @objc func parseAccelChar(notification: Notification) -> Void {
        var text = String(describing: notification.object)
        text = text.replacingOccurrences(of: "Optional(<", with: "")
        text = text.replacingOccurrences(of: ">)", with: "")
        
        accelChar = text
        
        sensorData.isEnabled = true
        
        print(text + " : accelChar from home")
    }
    
//    @objc func parseGT(notification: Notification) -> Void {
//
//        var text = String(describing: notification.object)
//        text = text.replacingOccurrences(of: "Optional(<", with: "")
//        text = text.replacingOccurrences(of: ">)", with: "")
//
//        print(text)
//
//        let GT = Int(text, radix: 16)!
//        goalTintLevel = GT
//
//        print(GT)
//    }
    
        
    
    
    // MARK: - Navigation
     
    @IBAction func returnToHome(segue: UIStoryboardSegue) {}
    
    @IBAction func goToPairing(_ sender: Any) {
        performSegue(withIdentifier: "unwindToPairing", sender: nil)
    }
    
    
    @IBAction func goToData(_ sender: Any) {
        performSegue(withIdentifier: "homeToData", sender: nil)
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "homeToData" {
            let destVC = segue.destination as? Data_Interface
            
            destVC?.autoTintChar = autoTintChar
            destVC?.temp = temp
            destVC?.humidity = humidity
            destVC?.intLight = intLight
            destVC?.extLight = extLight
            destVC?.extTintedLight = extTintedLight
            destVC?.opticTrans = opticTrans
            destVC?.accelChar = accelChar
            destVC?.coulombCt = currentTintLevel
            destVC?.driveState = driveState
            
        }
        else if segue.identifier == "unwindToPairing" {
            
            let destVC = segue.destination as? ViewController
            
            destVC?.startUp = false
            destVC?.removeArrayData()
            destVC?.tableView.reloadData()
            destVC?.peripheralFoundLabel.text = "Tynt Devices Found: 0"
            destVC?.startScanning()

        }
        
    }
}
