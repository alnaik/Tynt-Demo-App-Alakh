import SwiftUI
import CoreBluetooth
import Combine

//MARK: Circular Slider View Model
//Commented out changes are to dynamically get ETA
class CircularSliderViewModel: ObservableObject {
    @Published var currentTintLevel: Float = 0.0
    @Published var eta: String = ""
    private var timer: Timer?
    private var countdownTimer: Timer?
    private var lastTintLevel: Float = 0.0
    var bluetoothManager: BluetoothManager
    private var cancellable: AnyCancellable?
    private var lastUpdateTime: Date?
    
    init(currentTintLevel: Float, bluetoothManager: BluetoothManager) {
        self.currentTintLevel = currentTintLevel
        self.lastTintLevel = currentTintLevel
        self.bluetoothManager = bluetoothManager
        
        cancellable = bluetoothManager.$currentTintLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newLevel in
                print("Received new tint level from BluetoothManager: \(newLevel)")
                self?.currentTintLevel = Float(newLevel)
//                self?.calculateETA(newLevel: Float(newLevel))
            }
    }
    
//    private func calculateETA(newLevel: Float) {
//            let now = Date()
//            if let lastUpdate = self.lastUpdateTime {
//                let timeInterval = now.timeIntervalSince(lastUpdate)
//                let levelChange = abs(newLevel - self.lastTintLevel)
//                if levelChange > 0 {
//                    let rateOfChange = timeInterval / Double(levelChange)
//                    let remainingLevels = abs(Float(self.bluetoothManager.goalTintLevel) - newLevel)
//                    let remainingTime = rateOfChange * Double(remainingLevels)
//                    self.eta = "ETA: \(Int(remainingTime)) secs"
//                }
//            }
//            self.lastUpdateTime = now
//            self.lastTintLevel = newLevel
//            self.currentTintLevel = newLevel
//        }
//    
    func change(location: CGPoint, radius: CGFloat) {
        let vector = CGVector(dx: location.x, dy: location.y)
        let angle = atan2(vector.dy - radius, vector.dx - radius) + .pi / 2.0
        let fixedAngle = angle < 0.0 ? angle + 2.0 * .pi : angle
        let newValue = Float(fixedAngle / (2.0 * .pi) * 100)
        
        if newValue >= 0 && newValue <= 100 {
            self.currentTintLevel = newValue
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
                self?.registerTintLevel()
            }
        }
        
    }
    
    private func registerTintLevel() {
        let goalTintLevel = self.currentTintLevel
        if goalTintLevel != self.lastTintLevel {
            let timeToChangeOnePercent: Float = 1.5
            let etaInSeconds = abs(goalTintLevel - self.lastTintLevel) * timeToChangeOnePercent
            var remainingSeconds = Int(etaInSeconds)
            
            countdownTimer?.invalidate()
            countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                if remainingSeconds > 0 {
                    self?.eta = "ETA: \(remainingSeconds) secs"
                    remainingSeconds -= 1
                } else {
                    self?.eta = "ETA: Tynted"
                    timer.invalidate()
                        // Refresh tint level from the device to confirm the update
                        self?.refreshTintLevel()
                    }
                }
            self.lastTintLevel = goalTintLevel
            bluetoothManager.writeTintLevel(Int(goalTintLevel)) { [weak self] success in
                if !success {
                    DispatchQueue.main.async {
                        self?.eta = "ETA: Error updating"
                        self?.countdownTimer?.invalidate()
                    }
                }
            }
            
        }
    }

    
    func refreshTintLevel() {
        self.currentTintLevel = Float(bluetoothManager.currentTintLevel)
    }
}


//MARK: Circular Slider
struct CircularSlider: View {
    @ObservedObject var viewModel: CircularSliderViewModel
    let radius: CGFloat = 100
    @State private var firstInteraction: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black)

            Circle()
                .stroke(Color("Color_Transparent"), lineWidth: 20)

            Circle()
                .trim(from: 0.0, to: max(CGFloat(viewModel.currentTintLevel / 100), 0.01))
                .stroke(Color("Color"), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(Angle(degrees: 270))
                .gesture(
                    DragGesture(minimumDistance: 0.0)
                        .onChanged { value in
                            viewModel.change(location: value.location, radius: radius)
                        }
                )
            

            VStack {
                            Text("\(Int(viewModel.currentTintLevel))%")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                                .bold()

                            Text(viewModel.eta) // Display the ETA
                                .foregroundColor(.white)
                                .font(.caption)
                        }
        }
        .frame(width: radius * 2, height: radius * 2)
        .padding()
        .contentShape(Circle())
    }
}


//MARK: HomeInterfaceView
struct HomeInterfaceView: View {
    var windowName: String
    @ObservedObject var bluetoothManager: BluetoothManager
    @StateObject private var sliderViewModel: CircularSliderViewModel
    @State private var selectedMotorPosition: Int?
    
    init(windowName: String, bluetoothManager: BluetoothManager) {
        self.windowName = windowName
        self._bluetoothManager = ObservedObject(wrappedValue: bluetoothManager)
        self._sliderViewModel = StateObject(wrappedValue: CircularSliderViewModel(currentTintLevel: Float(bluetoothManager.currentTintLevel), bluetoothManager: bluetoothManager))
        

        if let savedPosition = UserDefaults.standard.object(forKey: "SelectedMotorPosition") as? Int {
            self._selectedMotorPosition = State(initialValue: savedPosition)
        }
    }

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack {

                    ZStack {
                        Image("TintImage")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 300, height: 500)
                            .cornerRadius(20)
                        
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(Double(sliderViewModel.currentTintLevel / 100)))
                            .frame(width: 300, height: 500)
                        
                        CircularSlider(viewModel: sliderViewModel)
                            .disabled(!bluetoothManager.isConnected)
                            .frame(width: 200, height: 200)
                            .position(x: 195, y: 250)
                    }
                    .padding(.top, 50)

                    Spacer()

                    HStack {
                        MotorControlButton(title: "0% Open", motorPosition: 0)
                        MotorControlButton(title: "50% Open", motorPosition: 50)
                        MotorControlButton(title: "100% Open", motorPosition: 100)
                    }
                    .offset(y: -20)
                    .disabled(!bluetoothManager.isConnected)
                }
                
                if !bluetoothManager.isConnected {
                    Text(bluetoothManager.connectionStatus == .failed ? "Connection Failed. Try again." : "Disconnected. Trying to reconnect...")
                        .foregroundColor(bluetoothManager.connectionStatus == .failed ? .red : .gray)
                        .padding()

                    Button("Reconnect") {
                        bluetoothManager.reconnectToDevice()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(bluetoothManager.connectionStatus != .disconnected)
                }
                
                ScrollView(.horizontal, showsIndicators: false)  {
                    HStack(spacing: 10) {
                        SensorTileView(title: "Temperature", value: "72°F", color: Color.pastelPink)
                        SensorTileView(title: "Humidity", value: "45%", color: Color.pastelBlue)
                        SensorTileView(title: "Ambient Light", value: "300 Lux", color: Color.pastelGreen)
                        // Adding more SensorTileViews
                    }
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text(windowName)
                        .font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image("Logo_Full")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 50)
                }
            }
            .onAppear {
                print("HomeInterfaceView appeared, starting scanning for Bluetooth devices.")
                bluetoothManager.startScanning()
                if bluetoothManager.isConnected == false {
                    print("BluetoothManager is not connected, attempting to reconnect.")
                            bluetoothManager.reconnectToDevice()
                        }
            }
            .onDisappear {
                bluetoothManager.stopScanning()
            }
        }
    }

    private func connectionStatusText() -> String {
        switch bluetoothManager.connectionStatus {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .failed:
            return "Connection Failed"
        }
    }

    private func writeMotorPosition(_ position: Int) {
        bluetoothManager.writeMotorState(position) { success in
            if success {
                print("Successfully wrote motor position: \(position)")
                // Save to UserDefaults
                UserDefaults.standard.set(position, forKey: "SelectedMotorPosition")
                selectedMotorPosition = position
            } else {
                print("Failed to write motor position")
            }
        }
    }
    
    private func MotorControlButton(title: String, motorPosition: Int) -> some View {
        Button(title) {
            writeMotorPosition(motorPosition)
        }
        .buttonStyle(MotorButtonStyle(isSelected: selectedMotorPosition == motorPosition))
        .disabled(bluetoothManager.currentMotorState == motorPosition)
    }
}

struct MotorButtonStyle: ButtonStyle {
    var isSelected: Bool

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding()
            .background(isSelected ? Color.blue : Color("Color"))
            .foregroundColor(.white)
            .cornerRadius(10)
            .font(.system(size: 10, weight: .semibold))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.black : Color.clear, lineWidth: 2)
            )
    }
}

extension Color {
    static let pastelPink = Color(red: 1.0, green: 0.8, blue: 0.8)
    static let pastelBlue = Color(red: 0.8, green: 0.8, blue: 1.0)
    static let pastelGreen = Color(red: 0.8, green: 1.0, blue: 0.8)
}

struct SensorTileView: View {
    var title: String
    var value: String
    var color: Color

    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding()
        .frame(width: 150, height: 100)
        .background(color)
        .cornerRadius(15)
    }
}


//
//  Home Interface.swift
//  Tynt Demo
//
//  Created by Arjun on 6/11/23.
//
//import UIKit
//import SwiftUI
//import CoreBluetooth
//
//class Home_Interface: UIViewController {
//    
//    
//    //MARK: Outlets/Variables
//    
//    @IBOutlet weak var slider: UISlider!
//    @IBOutlet weak var statusText: UILabel!
//    @IBOutlet weak var sensorData: UIButton!
//    @IBOutlet weak var pairing: UIButton!
//    @IBOutlet weak var tintValue: UILabel!
//    @IBOutlet weak var tintProgress: UIProgressView!
//    
//    var goalTintLevel: Int!
//    var tintProgressLength: Int!
//    var currentTintLevel = -1
//    
//    var driveState: String! = ""
//    var autoTintChar: String! = ""
//    var temp: Float!
//    var humidity: Float!
//    var intLight: Float!
//    var extLight: Float!
//    var extTintedLight: Float!
//    var opticTrans: Float!
//    var accelChar: String! = ""
//    
//    var deviceDisconnected: Bool! = false //only for use for adequate handling of disconnection in Sensor Data Interface
//    
//    var timer = Timer()
//    
//    
//    //MARK: - ViewDidLoad
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        slider.transform = CGAffineTransform(rotationAngle: CGFloat.pi / -2)
//        
//        slider.isEnabled = false
//        
//        sensorData.isEnabled = false
//        
//        tintValue.text = "\u{2014}% Tint"
//        statusText.text = "\u{2014}"
//        
//        sensorData.setTitle("", for: .normal)
//        pairing.setTitle("", for: .normal)
//        
//        tintProgress.progress = 0
//        tintProgress.isHidden = true
//        
//        update()
//        
//        if deviceDisconnected {
//            disconnected()
//        }
//        
//    }
//    
//    override func viewDidAppear(_ animated: Bool) {
//        self.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { _ in
//            switch BlePeripheral.connectedPeripheral!.state {
//            case .disconnected:
//                self.disconnected()
//            case .disconnecting:
//                self.disconnected()
//            case .connecting:
//                print("Still connecting")
//            case.connected:
//                self.update()
//            @unknown default:
//                print("Unknown error")
//            }
//        })
//    }
//    
//    override func viewWillAppear(_ animated: Bool) {
//        addObservers()
//    }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        removeObservers()
//        timer.invalidate()
//    }
//    
//    
//    // MARK: - Functions
//    
//    func writeOutgoingValue(value: inout Int) {
//        let data = Data(bytes: &value, count: 1)
//        //change the "data" to valueString
//        if let blePeripheral = BlePeripheral.connectedPeripheral {
//            if let goalTintChar = BlePeripheral.goalTintChar {
//                blePeripheral.writeValue(data, for: goalTintChar, type: CBCharacteristicWriteType.withResponse)
//            }
//        }
//    }
//    
//    func update() {
//        
//        if currentTintLevel != -1 {
//            
//            slider.isEnabled = true
//        }
//        
//        if goalTintLevel != nil {
//            tintProgress.progress = ( 1 - ((Float(abs(goalTintLevel - currentTintLevel)) / Float(tintProgressLength!))))
//        }
//        else if goalTintLevel == nil {
//            tintProgress.progress = 0
//            slider.value = Float(currentTintLevel)
//            tintValue.text = String(Int(round(slider.value))) + "%"
//        }
//        
//        if driveState == "02" {
//            statusText.text = "Bleaching: At " + String(currentTintLevel) + "%"
//            tintProgress.isHidden = false
//        }
//        else if driveState == "01" {
//            statusText.text = "Tinting: At " + String(currentTintLevel) + "%"
//            tintProgress.isHidden = false
//        }
//        else if driveState == "00" {
//            statusText.text = "Idle At "
//            slider.value = Float(currentTintLevel)
//            tintValue.text = String(currentTintLevel) + "%"
//            tintProgress.progress = 0
//            tintProgress.isHidden = true
//        }
//        else if driveState == "03" {
//            statusText.text = "Working..."
//            tintProgress.isHidden = true
//        }
//        
//        print("updated (home interface)")
//        
//    }
//    
//    @IBAction func writeValueToInterface(_ sender: UISlider) {
//        tintValue.text = "Goal: " + String(Int(round(slider.value))) + "%"
//    }
//    
//    @IBAction func valueOut(_ sender: Any) {
//        
//        switch BlePeripheral.connectedPeripheral!.state {
//        case .disconnected:
//            self.disconnected()
//        case .disconnecting:
//            self.disconnected()
//        case .connecting:
//            print("Still connecting")
//        case.connected:
//            self.slider.isEnabled = true
//            self.sensorData.isEnabled = true
//            self.pairing.isEnabled = true
//            
//            var val = Int(round(self.slider.value))
//            let cur = Int(self.currentTintLevel)
//                    
//            if val != self.currentTintLevel {
//                        
//                self.tintProgress.progress = 0
////                self.driveState = "03"
//                self.goalTintLevel = val
//                self.tintProgressLength = abs(self.goalTintLevel - cur)
//                        
//                self.writeOutgoingValue(value: &val)
//            }
//        @unknown default:
//            print("Unknown error")
//        }
//    
//    }
//    
//    @IBAction func sensorDataPressed(_ sender: Any) {
//        
//        switch BlePeripheral.connectedPeripheral!.state {
//        case .disconnected:
//            disconnected()
//        case .disconnecting:
//            disconnected()
//        case .connecting:
//            print("Still connecting")
//        case.connected:
//            performSegue(withIdentifier: "homeToData", sender: nil)
//        @unknown default:
//            print("Unknown error")
//        }
//        
//    }
//    
//    
//    func separateAmbLightChar(rawChar: String) {
//        
//        let bytes = rawChar.components(separatedBy: " ")
//        
//        let intLightBytes = bytes[0]
//        let extLightBytes = bytes[1]
//        let extTintBytes = bytes[2]
//        
//        intLight = convertALCToInt(bytes: intLightBytes)
//        extLight = convertALCToInt(bytes: extLightBytes)
//        extTintedLight = convertALCToInt(bytes: extTintBytes)
//        
//        let x = (extTintedLight/extLight) * 1000
//        opticTrans = (roundf(x) / 10.0)
//        
//    }
//    
//    func convertALCToInt(bytes: String) -> Float{
//        
//        let s = Array(bytes)
//        
//        let s1 = String(s[0]) + String(s[1])
//        let s2 = String(s[2]) + String(s[3])
//        let s3 = String(s[4]) + String(s[5])
//        let s4 = String(s[6]) + String(s[7])
//        
//        let a = Int(s1, radix: 16)!
//        let b = Int(s2, radix: 16)!
//        let c = Int(s3, radix: 16)!
//        let d = Int(s4, radix: 16)!
//        
//        let result = Float(a + (b<<8) + (c<<16) + (d<<24))
//        
//        return (result/100)
//    }
//    
//    func disconnected() {
//        slider.isEnabled = false
//        sensorData.isEnabled = false
//        pairing.isEnabled = true
//        tintProgress.isHidden = true
//        tintValue.text = "\u{2014}% Tint"
//        slider.value = 0
//        statusText.text = "Device disconnected. Please reconnect."
//        timer.invalidate()
//    }
//    
//    func addObservers() {
//        //order of observers must be maintained to keep from unwrapping nil optional when navigating to Sensor Data Interface
//        NotificationCenter.default.addObserver(self, selector: #selector(self.parseSOTPerc(notification:)), name: NSNotification.Name(rawValue: "NotifySOTP"), object: nil)
//        
//        NotificationCenter.default.addObserver(self, selector: #selector(self.parseDrvSt(notification:)), name: NSNotification.Name(rawValue: "NotifyDrvSt"), object: nil)
//        
//        NotificationCenter.default.addObserver(self, selector: #selector(self.parseATSChar(notification:)), name: NSNotification.Name(rawValue: "NotifyATS"), object: nil)
//
//        NotificationCenter.default.addObserver(self, selector: #selector(self.parseTempChar(notification:)), name: NSNotification.Name(rawValue: "NotifyTemp"), object: nil)
//
//        NotificationCenter.default.addObserver(self, selector: #selector(self.parseHumidityChar(notification:)), name: NSNotification.Name(rawValue: "NotifyHumidity"), object: nil)
//
//        NotificationCenter.default.addObserver(self, selector: #selector(self.parseAmbLightChar(notification:)), name: NSNotification.Name(rawValue: "NotifyAL"), object: nil)
//
//        NotificationCenter.default.addObserver(self, selector: #selector(self.parseAccelChar(notification:)), name: NSNotification.Name(rawValue: "NotifyAccel"), object: nil)
//        
////        NotificationCenter.default.addObserver(self, selector: #selector(self.parseGT(notification:)), name: NSNotification.Name(rawValue: "NotifyGT"), object: nil)
//    }
//    
//    func removeObservers() {
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NotifyATS"), object: nil)
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NotifyTemp"), object: nil)
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NotifyHumidity"), object: nil)
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NotifyAL"), object: nil)
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NotifySOTP"), object: nil)
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NotifyAccel"), object: nil)
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NotifyDrvSt"), object: nil)
////        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NotifyGT"), object: nil)
//    }
//    
//    //MARK: - Parse Functions
//    
//    @objc func parseSOTPerc(notification: Notification) -> Void{
//        
//        var text = String(describing: notification.object)
//        text = text.replacingOccurrences(of: "Optional(<", with: "")
//        text = text.replacingOccurrences(of: ">)", with: "")
//        
//        let cur = Int(text, radix: 16)!
//        currentTintLevel = cur
//        
//        slider.isEnabled = true
//        
//        print(text + " : SOT from home")
//        
//    }
//    
//    @objc func parseDrvSt(notification: Notification) -> Void {
//        
//        var text = String(describing: notification.object)
//        text = text.replacingOccurrences(of: "Optional(<", with: "")
//        text = text.replacingOccurrences(of: ">)", with: "")
//        
//        driveState = text
//        
//        print(text + " : drvStChar from home")
//        
//    }
//    
//    @objc func parseATSChar(notification: Notification) -> Void {
//        var text = String(describing: notification.object)
//        text = text.replacingOccurrences(of: "Optional(<", with: "")
//        text = text.replacingOccurrences(of: ">)", with: "")
//        
//        autoTintChar = text
//        
//        print(text + ": ATSChar from home")
//    }
//    
//    @objc func parseTempChar(notification: Notification) -> Void {
//        var text = String(describing: notification.object)
//        text = text.replacingOccurrences(of: "Optional(<", with: "")
//        text = text.replacingOccurrences(of: ">)", with: "")
//        
//        print(text + " : raw temp char from home")
//        
//        let chars = Array(text)
//        
//        let b1 = String(chars[0]) + String(chars[1])
//        let b2 = String(chars[2]) + String(chars[3])
//        
//        let a = Int(b1, radix: 16)!
//        let b = Int(b2, radix: 16)!
//        
//        let v = a + (b<<8)
//        
//        if v > 32768 {
//            let r = 65536 - v
//            temp = (Float(r) / 10)*(-1)
//        }
//        else {
//            temp = Float(v) / 10
//        }
//        
//        print(String(temp) + " : tempChar from home")
//        
//        //MARK: - Handle Signed Bits
//        
//    }
//    
//    @objc func parseHumidityChar(notification: Notification) -> Void {
//        var text = String(describing: notification.object)
//        text = text.replacingOccurrences(of: "Optional(<", with: "")
//        text = text.replacingOccurrences(of: ">)", with: "")
//        
//        let t = Int(text, radix: 16)!
//        let value = Float(t)
//        humidity = value
//        
//        print(text + " : humidityChar from home")
//        
//    }
//    
//    @objc func parseAmbLightChar(notification: Notification) -> Void {
//        var text = String(describing: notification.object)
//        text = text.replacingOccurrences(of: "Optional(<", with: "")
//        text = text.replacingOccurrences(of: ">)", with: "")
//        
//        separateAmbLightChar(rawChar: text)
//        
//        print(text + " : ambLightChar from home")
//    }
//    
//    @objc func parseAccelChar(notification: Notification) -> Void {
//        var text = String(describing: notification.object)
//        text = text.replacingOccurrences(of: "Optional(<", with: "")
//        text = text.replacingOccurrences(of: ">)", with: "")
//        
//        accelChar = text
//        
//        sensorData.isEnabled = true
//        
//        print(text + " : accelChar from home")
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
////        goalTintLevel = GT
////
////        print(GT)
////    }
//    
//        
//    
//    
//    // MARK: - Navigation
//     
//    @IBAction func returnToHome(segue: UIStoryboardSegue) {}
//    
//    @IBAction func goToPairing(_ sender: Any) {
//        performSegue(withIdentifier: "unwindToPairing", sender: nil)
//    }
//    
//    
//    @IBAction func goToData(_ sender: Any) {
//        performSegue(withIdentifier: "homeToData", sender: nil)
//    }
//    
//    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//
//        if segue.identifier == "homeToData" {
//            let destVC = segue.destination as? Data_Interface
//            
//            destVC?.autoTintChar = autoTintChar
//            destVC?.temp = temp
//            destVC?.humidity = humidity
//            destVC?.intLight = intLight
//            destVC?.extLight = extLight
//            destVC?.extTintedLight = extTintedLight
//            destVC?.opticTrans = opticTrans
//            destVC?.accelChar = accelChar
//            destVC?.coulombCt = currentTintLevel
//            destVC?.driveState = driveState
//            
//        }
//        else if segue.identifier == "unwindToPairing" {
//            
//            let destVC = segue.destination as? ViewController
//            
//            destVC?.startUp = false
//            destVC?.removeArrayData()
//            destVC?.tableView.reloadData()
//            destVC?.peripheralFoundLabel.text = "Tynt Devices Found: 0"
//            destVC?.startScanning()
//
//        }
//        
//    }
//}
