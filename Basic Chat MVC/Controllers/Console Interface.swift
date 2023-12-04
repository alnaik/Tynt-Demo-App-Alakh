
// associated with "Sensor Data Interface"

//import UIKit
//import CoreBluetooth
//
//class ConsoleViewController: UIViewController {
//
//  //Data
//  var peripheralManager: CBPeripheralManager?
//  var peripheral: CBPeripheral?
//  var periperalgoalTintChar: CBCharacteristic?
//
//  @IBOutlet weak var peripheralLabel: UILabel!
//  @IBOutlet weak var serviceLabel: UILabel!
//  @IBOutlet weak var consoleTextView: UITextView!
//  @IBOutlet weak var consoleTextField: UITextField!
//    @IBOutlet weak var homeButton: UIButton!
//    @IBOutlet weak var txLabel: UILabel!
//  @IBOutlet weak var rxLabel: UILabel!
//
//  override func viewDidLoad() {
//      super.viewDidLoad()
//      
//      homeButton.setTitle("", for: .normal)
//
//    keyboardNotifications()
//
////    NotificationCenter.default.addObserver(self, selector: #selector(self.appendRxDataToTextView(notification:)), name: NSNotification.Name(rawValue: "Notify"), object: nil)
//
//    consoleTextField.delegate = self
//
//    peripheralLabel.text = BlePeripheral.connectedPeripheral?.name
//
//    txLabel.text = "TX:\(String(BlePeripheral.goalTintChar!.uuid.uuidString))"
//    rxLabel.text = "RX:\(String(BlePeripheral.SOTChar!.uuid.uuidString))"
//
////    if let service = BlePeripheral.connectedService {
////      serviceLabel.text = "Number of Services: \(String((BlePeripheral.connectedPeripheral?.services!.count)!))"
////    } else{
////      print("Service was not found")
////    }
//  }
//
//    @IBAction func backToHome(_ sender: Any) {
//        performSegue(withIdentifier: "returnToHome", sender: nil)
//    }
//    
//    @objc func appendRxDataToTextView(notification: Notification) -> Void{
//      
//    consoleTextView.text.append("\n[Recv]: \(notification.object!) \n")
//  }
//
//  func appendTxDataToTextView(){
//    consoleTextView.text.append("\n[Sent]: \(String(consoleTextField.text!)) \n")
//  }
//
//  func keyboardNotifications() {
//    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
//
//    NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(notification:)), name: UIResponder.keyboardDidHideNotification, object: nil)
//
//    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
//  }
//
//  deinit {
//    NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
//    NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
//    NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
//  }
//
//  // MARK:- Keyboard
//  @objc func keyboardWillChange(notification: Notification) {
//
//    if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
//
//      let keyboardHeight = keyboardSize.height
//      print(keyboardHeight)
//      view.frame.origin.y = (-keyboardHeight + 50)
//    }
//  }
//
//  @objc func keyboardDidHide(notification: Notification) {
//    view.frame.origin.y = 0
//  }
//
//  @objc func disconnectPeripheral() {
//    print("Disconnect for peripheral.")
//  }
//
//  // Write functions
//  func writeOutgoingValue(value: inout Int){
////      let intValue = 0;
////      let valueString = (data as NSString).data(using: String.Encoding.utf8.rawValue)
////      if let utf8Data = data.data(using: .utf8),
////          let intValue = Int(String(data: utf8Data, encoding: .utf8)!) {
////              print("Converted integer value:", intValue)
////      }else {
////          return;
////      }
//      
//      let data = Data(bytes: &value, count: 1)
//      //change the "data" to valueString
//    if let blePeripheral = BlePeripheral.connectedPeripheral {
//          if let goalTintChar = BlePeripheral.goalTintChar {
//              blePeripheral.writeValue(data, for: goalTintChar, type: CBCharacteristicWriteType.withResponse)
//          }
//      }
//  }
//
//  func writeCharacteristic(incomingValue: Int8){
//    var val = incomingValue
//
//    let outgoingData = NSData(bytes: &val, length: MemoryLayout<Int8>.size)
//    peripheral?.writeValue(outgoingData as Data, for: BlePeripheral.goalTintChar!, type: CBCharacteristicWriteType.withResponse)
//  }
//}
//
//extension ConsoleViewController: CBPeripheralManagerDelegate {
//
//  func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
//    switch peripheral.state {
//    case .poweredOn:
//        print("Peripheral Is Powered On.")
//    case .unsupported:
//        print("Peripheral Is Unsupported.")
//    case .unauthorized:
//    print("Peripheral Is Unauthorized.")
//    case .unknown:
//        print("Peripheral Unknown")
//    case .resetting:
//        print("Peripheral Resetting")
//    case .poweredOff:
//      print("Peripheral Is Powered Off.")
//    @unknown default:
//      print("Error")
//    }
//  }
//
//
//  //Check when someone subscribe to our characteristic, start sending the data
//  func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
//      print("Device subscribe to characteristic")
//  }
//
//}
//
//extension ConsoleViewController: UITextViewDelegate {
//
//}
//
//extension ConsoleViewController: UITextFieldDelegate {
//
//  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//      
//      if let text = textField.text {
//          let scanner = Scanner(string: text)
//          var intValue: Int = 0
//          scanner.scanInt(&intValue)
//          
//          if scanner.isAtEnd {
//              // The first integer value was successfully extracted
//              print("First integer value:", intValue)
//              writeOutgoingValue(value: &intValue)
//          } else {
//              // No integer value found or other text follows the integer
//              print("No integer value found or invalid format.")
//          }
//      } else {
//          // TextField is empty
//          print("TextField is empty.")
//      }
//
//      
//      
//    
//    appendTxDataToTextView()
//    textField.resignFirstResponder()
//    textField.text = ""
//    return true
//
//  }
//
//  func textFieldShouldClear(_ textField: UITextField) -> Bool {
//    textField.clearsOnBeginEditing = true
//    return true
//  }
//    
//    // MARK: - Navigation
//    
//    
//    
//}
