// SwiftUI implemenatation of the pairing interface
import SwiftUI
import CoreBluetooth

struct PairingInterfaceView: View {
    @Binding var selectedRoom: Room
    @ObservedObject var roomsData: RoomsData
    @ObservedObject var bluetoothManager: BluetoothManager
    var onDeviceSelected: (CBPeripheral, String, String, Bool) -> Void
    @State private var isScanning = false
    @State private var selectedDevice: CBPeripheral?
    @State private var newDeviceName: String = ""
    @State private var showingRenameView = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack {
                Spacer(minLength: 20)
                Text("Add Window")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                
                List(bluetoothManager.discoveredDevices.filter { !isDeviceAdded($0.peripheral) }, id: \.peripheral.identifier) { device in
                    Button(action: {
                        selectedDevice = device.peripheral
                        newDeviceName = device.peripheral.name ?? ""
                        showingRenameView = true
                    }) {
                        BluetoothDeviceRow(deviceName: device.peripheral.name ?? "Unknown", rssi: device.rssi)
                    }
                }
                .onChange(of: bluetoothManager.discoveredDevicesUpdatedCount) { _ in
                }
                .sheet(isPresented: $showingRenameView) {
                    if let device = selectedDevice {
                        RenameDeviceView(device: $selectedDevice, newName: $newDeviceName, onSave: { device, name in
                            onDeviceSelected(device, name, device.identifier.uuidString, true)
                            showingRenameView = false
                        })
                    }
                }
                
                Button(isScanning ? "Stop Scanning" : "Scan for Devices") {
                    isScanning.toggle()
                    if isScanning {
                        bluetoothManager.startScanning()
                    } else {
                        bluetoothManager.stopScanning()
                    }
                }
                .padding()
                .background(Color("Color"))
                .foregroundColor(.white)
                .cornerRadius(10)
                .font(.system(size: 25, weight: .semibold))
            }
        }
    }

    func isDeviceAdded(_ device: CBPeripheral) -> Bool {
        let deviceUUID = device.identifier.uuidString
        return roomsData.rooms.contains { room in
            room.windows.contains { $0.deviceUUID == deviceUUID }
        }
    }
}


struct BluetoothDeviceRow: View {
    var deviceName: String
    var rssi: Int

    var body: some View {
        HStack {
            Text(deviceName)
                .font(.headline)
            Spacer()
            Text("RSSI: \(rssi)")
                .font(.subheadline)
        }
    }
}

struct RenameDeviceView: View {
    @Binding var device: CBPeripheral?
    @Binding var newName: String
    var onSave: (CBPeripheral, String) -> Void

    var body: some View {
        VStack {
            Text("Rename Window")
                .font(.headline)
            TextField("Enter new name", text: $newName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button("Save") {
                if let device = device {
                    onSave(device, newName)
                }
            }
            .padding()
        }
        .padding()
    }
}






////
//// associated with "Pairing Interface"
////
//import UIKit
//import CoreBluetooth
//
//class ViewController: UIViewController {
//
//    // Data
//    private var centralManager: CBCentralManager!
//    private var bluetoothPeripheral: CBPeripheral!
//    private var peripheralArray: [CBPeripheral] = []
//    private var rssiArray = [NSNumber]()
//    private var timer = Timer()
//    
//    //MARK: - Characteristic Variables
//    
//    private var goalTintChar: CBCharacteristic!
//    private var SOTChar: CBCharacteristic!
//    private var DrvStChar: CBCharacteristic!
//    private var autoTintChar: CBCharacteristic!
//    private var tempChar: CBCharacteristic!
//    private var humidityChar: CBCharacteristic!
//    private var ambLightChar: CBCharacteristic!
//    private var accelChar: CBCharacteristic!
//    
//    var currentTintLevel: Int!
//    var driveState: String!
////    var goalTint: Int!
//    
//    var startUp: Bool!
//    let defaults = UserDefaults.standard
//
//    // UI
//    @IBOutlet weak var tableView: UITableView!
//    @IBOutlet weak var peripheralFoundLabel: UILabel!
//    @IBOutlet weak var scanningButton: UIButton!
//    
//    
//    
//    @IBAction func scanningAction(_ sender: Any) {
//        startUp = false
//        startScanning()
//  }
//
//    override func viewDidLoad() {
//      super.viewDidLoad()
//
//      self.tableView.delegate = self
//      self.tableView.dataSource = self
//      self.tableView.reloadData()
//      // Manager
//      centralManager = CBCentralManager(delegate: self, queue: nil)
//        
//    }
//
//    override func viewDidAppear(_ animated: Bool) {
//      disconnectFromDevice()
//      self.tableView.reloadData()
//        
//        NotificationCenter.default.addObserver(self, selector: #selector(self.parseSOTPerc(notification:)), name: NSNotification.Name(rawValue: "NotifySOTP"), object: nil)
//        
//        NotificationCenter.default.addObserver(self, selector: #selector(self.parseDrvSt(notification:)), name: NSNotification.Name(rawValue: "NotifyDrvSt"), object: nil)
//        
////        NotificationCenter.default.addObserver(self, selector: #selector(self.parseGT(notification:)), name: NSNotification.Name(rawValue: "NotifyGT"), object: nil)
//    }
//    
//    override func viewDidDisappear(_ animated: Bool) {
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NotifySOTP"), object: nil)
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NotifyDrvSt"), object: nil)
////        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NotifyGT"), object: nil)
//    }
//    
//    func connectToDevice() -> Void {
//
//        stopScanning()
//        centralManager?.connect(bluetoothPeripheral!, options: nil)
//        scanningButton.setTitle("Connecting...", for: .normal)
//        scanningButton.isEnabled = false
//        
//        //User Defaults (for auto-connect to last peripheral)
//        let string = String(describing: bluetoothPeripheral.identifier)
//        print("string: " + string)
//        defaults.setValue(String(describing: bluetoothPeripheral.identifier), forKey: "LastConnectedUUID")
//        print(bluetoothPeripheral.identifier)
//  }
//
//    func disconnectFromDevice() -> Void {
//      if bluetoothPeripheral != nil {
//        centralManager?.cancelPeripheralConnection(bluetoothPeripheral!)
//      }
//  }
//
//    func removeArrayData() -> Void {
//      centralManager.cancelPeripheralConnection(bluetoothPeripheral)
//           rssiArray.removeAll()
//           peripheralArray.removeAll()
//       }
//
//    func startScanning() -> Void {
//        
//        // Remove prior data
//        peripheralArray.removeAll()
//        rssiArray.removeAll()
//        self.tableView.reloadData()
//        peripheralFoundLabel.text = "Tynt Devices Found: \(peripheralArray.count)"
//        
//        // Start Scanning
//        print("Started startScanning")
//        scanningButton.setTitle("Scanning...", for: .normal)
//        scanningButton.isEnabled = false
//        centralManager?.scanForPeripherals(withServices: [])
//
//        Timer.scheduledTimer(withTimeInterval: 5, repeats: false) {_ in
//            self.stopScanning()
//            self.scanningButton.setTitle("Scan", for: .normal)
//            self.scanningButton.isEnabled = true
//        }
//        
//    }
//
////    func scanForBLEDevices() -> Void {
////      // Remove prior data
////      peripheralArray.removeAll()
////      rssiArray.removeAll()
////      // Start Scanning
////        print("Started ScanForBLEDevice");
////      centralManager?.scanForPeripherals(withServices: [] , options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
////        scanningButton.setTitle("Scanning...", for: .normal)
////        scanningButton.isEnabled = false
////
////      Timer.scheduledTimer(withTimeInterval: 15, repeats: false) {_ in
////          self.stopScanning()
////      }
////  }
//
//    func stopTimer() -> Void {
//      // Stops Timer
//      self.timer.invalidate()
//    }
//
//    func stopScanning() -> Void {
//        centralManager?.stopScan()
//    }
//
//    func delayedConnection() -> Void {
//
//    BlePeripheral.connectedPeripheral = bluetoothPeripheral
//
//    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
//      //Once connected, move to new view controller to manager incoming and outgoing data
////      let storyboard = UIStoryboard(name: "Main", bundle: nil)
//
////        let detailViewController = storyboard.instantiateViewController(withIdentifier: "ConsoleViewController") as! ConsoleViewController
//        
//      self.performSegue(withIdentifier: "pairingToHome", sender: nil)
//
//    })
//  }
//    
//    //MARK: - Parse Functions
//    
//    @objc func parseSOTPerc(notification: Notification) -> Void{
//
//        var text = String(describing: notification.object)
//        text = text.replacingOccurrences(of: "Optional(<", with: "")
//        text = text.replacingOccurrences(of: ">)", with: "")
//
//        print(text)
//
//        let cur = Int(text, radix: 16)!
//        currentTintLevel = cur
//
//    }
//    
//    @objc func parseDrvSt(notification: Notification) -> Void {
//        
//        var text = String(describing: notification.object)
//        text = text.replacingOccurrences(of: "Optional(<", with: "")
//        text = text.replacingOccurrences(of: ">)", with: "")
//        driveState = text
//        
//        print("drive state was updated (pairing)")
//        
//    }
//    
////    @objc func parseGT(notification: Notification) -> Void {
////
////        var text = String(describing: notification.object)
////        text = text.replacingOccurrences(of: "Optional(<", with: "")
////        text = text.replacingOccurrences(of: ">)", with: "")
////
////        print(text)
////
////        let GT = Int(text, radix: 16)!
////        goalTint = GT
////
////        print(GT)
////    }
//}
//
//// MARK: - CBCentralManagerDelegate
//// A protocol that provides updates for the discovery and management of peripheral devices.
//extension ViewController: CBCentralManagerDelegate {
//
//    // MARK: - Check
//    func centralManagerDidUpdateState(_ central: CBCentralManager) {
//
//      switch central.state {
//        case .poweredOff:
//            print("Is Powered Off.")
//
//            let alertVC = UIAlertController(title: "Bluetooth Required", message: "Check your Bluetooth Settings", preferredStyle: UIAlertController.Style.alert)
//
//            let action = UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) -> Void in
//                self.dismiss(animated: true, completion: nil)
//            })
//
//            alertVC.addAction(action)
//
//            self.present(alertVC, animated: true, completion: nil)
//
//        case .poweredOn:
//            print("Is Powered On.")
//          startUp = true
//          startScanning()
//        case .unsupported:
//            print("Is Unsupported.")
//        case .unauthorized:
//        print("Is Unauthorized.")
//        case .unknown:
//            print("Unknown")
//        case .resetting:
//            print("Resetting")
//        @unknown default:
//          print("Error")
//        }
//    }
//
//    // MARK: - Discover
//    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//      
//        print("Function: \(#function),Line: \(#line)")
//
//      bluetoothPeripheral = peripheral
//        
//        if startUp {
//            
//            if let lastUUID = defaults.value(forKey: "LastConnectedUUID") {
//                if String(describing: lastUUID) == String(describing: bluetoothPeripheral.identifier) {
//
//                    BlePeripheral.connectedPeripheral = bluetoothPeripheral
//                    bluetoothPeripheral.delegate = self
//                    
//                    connectToDevice()
//
//                    self.performSegue(withIdentifier: "pairingToHomeAuto", sender: nil)
//
//                }
//            }
//        }
//        
//        let p_name = peripheral.name ?? ""; //get the name and cast to null if empty
//      if peripheralArray.contains(peripheral) {
//          print("Duplicate Found.")
//      } else if(p_name.contains( "Tynt_Demo")){
//        peripheralArray.append(peripheral)
//        rssiArray.append(RSSI)
//          peripheralFoundLabel.text = "Tynt Devices Found: \(peripheralArray.count)"
//
//          bluetoothPeripheral.delegate = self
//
//          print("Peripheral Discovered: \(peripheral)")
//
//          self.tableView.reloadData()
//      }
//
//      
//    }
//
//    // MARK: - Connect
//    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
//        stopScanning()
//        bluetoothPeripheral.discoverServices([CBUUIDs.cService_UUID, CBUUIDs.sService_UUID])
//    }
//}
//
//// MARK: - CBPeripheralDelegate
//// A protocol that provides updates on the use of a peripheral’s services.
//extension ViewController: CBPeripheralDelegate {
//
//    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
//        
//        
//      guard let services = peripheral.services else { return }
//      for service in services {
//        peripheral.discoverCharacteristics(nil, for: service)
//      }
//        print(services)
//      BlePeripheral.connectedControlService = services[0]
//      BlePeripheral.connectedSensorService = services[1]
//    }
//
//  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
//
//    guard let characteristics = service.characteristics else {
//        return
//    }
//
//    print("Found \(characteristics.count) characteristics.")
//
//    for characteristic in characteristics {
//
//      if characteristic.uuid.isEqual(CBUUIDs.cService_Characteristic_uuid_StateOfTint)  {
//
//        SOTChar = characteristic
//
//        BlePeripheral.SOTChar = SOTChar
//
//        peripheral.setNotifyValue(true, for: SOTChar!)
//        peripheral.readValue(for: characteristic)
//
//        print("State of Tint Characteristic: \(SOTChar.uuid)")
//      }
//        else if characteristic.uuid.isEqual(CBUUIDs.cService_Characteristic_uuid_DriveState) {
//            
//            DrvStChar = characteristic
//
//            BlePeripheral.DrvStChar = DrvStChar
//
//            peripheral.setNotifyValue(true, for: DrvStChar!)
//            peripheral.readValue(for: characteristic)
//
//            print("DrvStCharacteristic: \(DrvStChar.uuid)")
//        }
//        
//        else if characteristic.uuid.isEqual(CBUUIDs.cService_Characteristic_uuid_AutoMode){
//            autoTintChar = characteristic
//            BlePeripheral.autoTintChar = autoTintChar
//            peripheral.setNotifyValue(true, for: autoTintChar!)
//            peripheral.readValue(for: characteristic)
//            print("Auto Tint Characteristic: \(autoTintChar.uuid)")
//        }
//        
//        else if characteristic.uuid.isEqual(CBUUIDs.sService_Characteristic_uuid_Temp){
//            tempChar = characteristic
//            BlePeripheral.tempChar = tempChar
//            peripheral.setNotifyValue(true, for: tempChar!)
//            peripheral.readValue(for: characteristic)
//            print("Temperature Characteristic: \(tempChar.uuid)")
//          }
//        
//        else if characteristic.uuid.isEqual(CBUUIDs.sService_Characteristic_uuid_Humid){
//            humidityChar = characteristic
//            BlePeripheral.humidityChar = humidityChar
//            peripheral.setNotifyValue(true, for: humidityChar!)
//            peripheral.readValue(for: characteristic)
//            print("Humidity Characteristic: \(humidityChar.uuid)")
//          }
//        
//        else if characteristic.uuid.isEqual(CBUUIDs.sService_Characteristic_uuid_AmbLight){
//            ambLightChar = characteristic
//            BlePeripheral.ambLightChar = ambLightChar
//            peripheral.setNotifyValue(true, for: ambLightChar!)
//            peripheral.readValue(for: characteristic)
//            print("Ambient Light Characteristic: \(ambLightChar.uuid)")
//          }
//        
//        else if characteristic.uuid.isEqual(CBUUIDs.sService_Characteristic_uuid_Accel){
//            accelChar = characteristic
//            BlePeripheral.accelChar = accelChar
//            peripheral.setNotifyValue(true, for: accelChar!)
//            peripheral.readValue(for: characteristic)
//            print("Accelerometer Characteristic: \(accelChar.uuid)")
//          }
//
//        else if characteristic.uuid.isEqual(CBUUIDs.cService_Characteristic_uuid_GoalTint){
//            goalTintChar = characteristic
//            BlePeripheral.goalTintChar = goalTintChar
//            ////MARK: - reinclude when figured out GT Char parse needs
////            peripheral.setNotifyValue(true, for: goalTintChar!)
////            peripheral.readValue(for: characteristic)
//            print("Goal Tint Characteristic: \(goalTintChar.uuid)")
//        }
//        
//    }
//    delayedConnection()
// }
//
//
//
//  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor char: CBCharacteristic, error: Error?) {
//      
//      if char == SOTChar {
//
//          NotificationCenter.default.post(name:NSNotification.Name(rawValue: "NotifySOTP"), object: char.value! as Data)
//      }
//      else if char == DrvStChar {
//
//          NotificationCenter.default.post(name:NSNotification.Name(rawValue: "NotifyDrvSt"), object: char.value! as Data)
//      }
//      else if char == autoTintChar {
//          
//          NotificationCenter.default.post(name:NSNotification.Name(rawValue: "NotifyATS"), object: char.value! as Data)
//      }
//      else if char == tempChar {
//          
//          NotificationCenter.default.post(name:NSNotification.Name(rawValue: "NotifyTemp"), object: char.value! as Data)
//      }
//      else if char == humidityChar {
//          
//          NotificationCenter.default.post(name:NSNotification.Name(rawValue: "NotifyHumidity"), object: char.value! as Data)
//      }
//      else if char == ambLightChar {
//          
//          NotificationCenter.default.post(name:NSNotification.Name(rawValue: "NotifyAL"), object: char.value! as Data)
//      }
//      else if char == accelChar {
//          
//          NotificationCenter.default.post(name:NSNotification.Name(rawValue: "NotifyAccel"), object: char.value! as Data)
//      }
////      else if char == goalTintChar {
////
////          NotificationCenter.default.post(name:NSNotification.Name(rawValue: "NotifyGT"), object: char.value! as Data)
////      }
//
//  }
//
//  func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
//        peripheral.readRSSI()
//    }
//
//  func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
//      guard error == nil else {
//          print("Error discovering services: error")
//          return
//      }
//    print("Function: \(#function),Line: \(#line)")
//      print("Message sent")
//  }
//
//
//  func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
//      print("*******************************************************")
//    print("Function: \(#function),Line: \(#line)")
//      if (error != nil) {
//          print("Error changing notification state:\(String(describing: error?.localizedDescription))")
//
//      } else {
//          print("Characteristic's value subscribed")
//      }
//
//      if (characteristic.isNotifying) {
//          print ("Subscribed. Notification has begun for: \(characteristic.uuid)")
//      }
//  }
//
//}
//
//// MARK: - UITableViewDataSource
//// The methods adopted by the object you use to manage data and provide cells for a table view.
//extension ViewController: UITableViewDataSource {
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return self.peripheralArray.count
//    }
//
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//
//      let cell = tableView.dequeueReusableCell(withIdentifier: "BlueCell") as! TableViewCell
//
//      let peripheralFound = self.peripheralArray[indexPath.row]
//
//      let rssiFound = self.rssiArray[indexPath.row]
//
//        if peripheralFound == nil {
//            cell.peripheralLabel.text = "Unknown"
//        }else {
//            cell.peripheralLabel.text = peripheralFound.name
//            cell.rssiLabel.text = "RSSI: \(rssiFound)"
//        }
//        return cell
//    }
//
//
//}
//
//
//// MARK: - UITableViewDelegate
//// Methods for managing selections, deleting and reordering cells and performing other actions in a table view.
//extension ViewController: UITableViewDelegate {
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//
//        bluetoothPeripheral = peripheralArray[indexPath.row]
//
//        BlePeripheral.connectedPeripheral = bluetoothPeripheral
//
//        connectToDevice()
//
//    }
//    
//    // MARK: - Navigation
//    
//    @IBAction func unwindToPairing(segue: UIStoryboardSegue) {}
//    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        
//        if segue.identifier == "pairingToHome" {
//            let destVC = segue.destination as? Home_Interface
//
//            if let CTL = currentTintLevel {
//                destVC?.currentTintLevel = CTL
//            }
//            
//            if let DRVST = driveState {
//                destVC?.driveState = DRVST
//            }
//            
////            if let GT = goalTint {
////                destVC?.goalTintLevel = GT
////            }
//
//        }
//        
//    }
//    
//    
//}
