//
//  LandingPage Interface.swift
//  Tynt Demo
//
//  Created by Alakh Naik on 10/31/23.
//

import SwiftUI
import CoreBluetooth
//MARK: Landing Page View
struct LandingPageView: View {
    @State private var selectedRoomIndex: Int? = 0
    @State private var showingAddRoomView = false
    @ObservedObject var roomsData = RoomsData()
    @State private var showingEditRoomView = false
    @State private var editingRoomIndex: Int?
    @State private var showingPairingSheet = false
    @StateObject var bluetoothManager = BluetoothManager()
    @State private var isNavigationActive = false
    @State private var selectedWindowName: String?

    var body: some View {
        NavigationView{
            ScrollView(.vertical, showsIndicators: false){
                HStack {
                    Spacer()
                    Image("Logo_Full")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 50)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(roomsData.rooms.indices, id: \.self) { index in
                            RoomButtonView(index: index)
                        }
                        AddRoomButtonView()
                    }
                    .padding(.horizontal)
                }
                
                RoomWindowsView()
                
                if let selectedWindow = selectedWindowName, isNavigationActive {
                                NavigationLink(destination: HomeInterfaceView(windowName: selectedWindow, bluetoothManager: bluetoothManager), isActive: $isNavigationActive) {
                                    EmptyView()
                                }.hidden()
                            }
            }
            .onAppear {
                bluetoothManager.reconnectToDevice()
            }
        }
    }

    private func RoomButtonView(index: Int) -> some View {
        Button(action: {
            selectedRoomIndex = index
        }) {
            Text(roomsData.rooms[index].name)
                .padding()
                .background(selectedRoomIndex == index ? Color("Color_Transparent") : Color.white)
                .foregroundColor(.black)
                .cornerRadius(10)
                .font(.system(size: 25, weight: .semibold))
        }
        .contextMenu {
            Button("Edit") {
                editingRoomIndex = index
                showingEditRoomView = true
            }
            Button("Delete", role: .destructive) {
                roomsData.deleteRoom(at: index)
                if selectedRoomIndex == index {
                    selectedRoomIndex = nil
                }
            }
        }
        .sheet(isPresented: $showingEditRoomView) {
            if let editingIndex = editingRoomIndex {
                AddRoomView(rooms: $roomsData.rooms, roomName: roomsData.rooms[editingIndex].name, roomIndex: editingIndex)
            }
        }
    }

    private func AddRoomButtonView() -> some View {
        Button("add room") {
            showingAddRoomView = true
        }
        .padding()
        .background(Color("Color"))
        .foregroundColor(.white)
        .cornerRadius(10)
        .font(.system(size: 25, weight: .semibold))
        .sheet(isPresented: $showingAddRoomView) {
            AddRoomView(rooms: $roomsData.rooms)
        }
    }

    private func RoomWindowsView() -> some View {
        VStack {
            if roomsData.rooms.isEmpty {
                Spacer()
                Text("No rooms available. Add a room to start.")
                    .padding()
                Spacer()
            } else if let selectedIndex = selectedRoomIndex, roomsData.rooms.indices.contains(selectedIndex) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(roomsData.rooms[selectedIndex].windows, id: \.self) { window in
                            WindowButtonView(window: window)
                                .contextMenu {
                                Button("Delete", role: .destructive) {
                                    deleteWindow(named: window.name, inRoomAtIndex: selectedIndex)
                                }
                            }
                        }
                        
                        AddWindowButtonView()
                    }
                    .padding(.horizontal)
                }
            } else {
                Spacer()
                Text("Select a room to see its windows")
                    .padding()
                Spacer()
            }
        }
    }
    
    private func deleteWindow(named windowName: String, inRoomAtIndex roomIndex: Int) {
        guard roomsData.rooms.indices.contains(roomIndex) else { return }
        if let windowIndex = roomsData.rooms[roomIndex].windows.firstIndex(where: { $0.name == windowName }) {
            roomsData.rooms[roomIndex].windows.remove(at: windowIndex)
            refreshDeviceList()
        }
    }
    
    private func refreshDeviceList() {
        bluetoothManager.stopScanning()
        bluetoothManager.startScanning()
    }

    private func WindowButtonView(window: Room.Window) -> some View {
            Button(action: {
                connectToDeviceWithUUID(window.deviceUUID)
                selectedWindowName = window.name
                isNavigationActive = true
            }) {
                WindowView(bluetoothManager: bluetoothManager, windowName: window.name)
            }
        }


    private func AddWindowButtonView() -> some View {
        Button(action: {
            showingPairingSheet = bluetoothManager.isBluetoothEnabled
        }) {
            Tynt_Demo.WindowButtonView()
        }
        .disabled(!bluetoothManager.isBluetoothEnabled)
        .padding(.horizontal, 2)
        .padding(.bottom, 25)
        .background(Color.white)
        .foregroundColor(.white)
        .cornerRadius(10)
        .sheet(isPresented: $showingPairingSheet) {
            if let selectedIndex = selectedRoomIndex {
                PairingInterfaceView(selectedRoom: $roomsData.rooms[selectedIndex],
                                     roomsData: roomsData,
                                     bluetoothManager: bluetoothManager) { selectedDevice, newName, deviceUUID, shouldRemove in
                    let windowName = newName.isEmpty ? (selectedDevice.name ?? "Unknown") : newName
                    let window = Room.Window(name: windowName, deviceUUID: deviceUUID)
                    roomsData.rooms[selectedIndex].windows.append(window)
                    showingPairingSheet = false
                    if shouldRemove {
                        bluetoothManager.removeDevice(selectedDevice)
                    }
                }
            }
        }
    }


    private func connectToDeviceWithUUID(_ uuidString: String) {
            if let peripheral = bluetoothManager.retrievePeripheral(withUUID: uuidString) {
                bluetoothManager.connectToDevice(peripheral)
            } else {
                print("Device with UUID \(uuidString) not found")
            }
        }
}
    
struct Room: Codable {
    var name: String
    var windows: [Window]

    struct Window: Codable {
        var name: String
        var deviceUUID: String // Unique identifier for the Bluetooth device
    }
    
    init(name: String, windows: [Window] = []) {
        self.name = name
        self.windows = windows
    }
}

extension Room.Window: Hashable {
    static func == (lhs: Room.Window, rhs: Room.Window) -> Bool {
        return lhs.deviceUUID == rhs.deviceUUID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(deviceUUID)
    }
}

class RoomsData: ObservableObject {
    @Published var rooms: [Room] {
        didSet {
            if let encoded = try? JSONEncoder().encode(rooms) {
                UserDefaults.standard.set(encoded, forKey: "rooms")
            }
        }
    }
    
    init() {
        if let rooms = UserDefaults.standard.data(forKey: "rooms"),
           let decoded = try? JSONDecoder().decode([Room].self, from: rooms) {
            self.rooms = decoded
            return
        }
        self.rooms = []
    }
    
    func deleteRoom(at index: Int) {
            rooms.remove(at: index)
        }

        func editRoom(name: String, at index: Int) {
            rooms[index].name = name
        }
}

struct AddRoomView: View {
    @Binding var rooms: [Room]
    @State var roomName: String
    var roomIndex: Int?
    @Environment(\.presentationMode) var presentationMode

    init(rooms: Binding<[Room]>, roomName: String = "", roomIndex: Int? = nil) {
        self._rooms = rooms
        self._roomName = State(initialValue: roomName)
        self.roomIndex = roomIndex
    }


    var body: some View {
        NavigationView {
            VStack {
                TextField("room name", text: $roomName)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 30, weight: .semibold))

                Button(action: {
                    if !roomName.isEmpty {
                        if let index = roomIndex {
                            rooms[index].name = roomName
                        } else {
                            rooms.append(Room(name: roomName))
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text(roomIndex == nil ? "add room" : "update room")
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .background(Color("Color"))
                        .foregroundColor(Color.white)
                        .font(.system(size: 20, weight: .bold))
                        .cornerRadius(10)
                }
                .padding()
            }
            .padding()
        }
    }
}

struct WindowView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    var windowName: String

    var body: some View {
        VStack {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray, lineWidth: 3)
                    .frame(width: 200, height: 400)

                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(bluetoothManager.currentTintLevel <= 50 ? 0.25 : 0.75))
                    .frame(width: 200, height: 400)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Tint Level")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("\(bluetoothManager.currentTintLevel)")
                        .font(.system(size: 75, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding([.top, .leading], 10)
            }

            Text(windowName)
                .foregroundColor(.gray)
        }
        .frame(width: 200, height: 450)
    }
}





struct WindowButtonView: View {
    var body: some View {
        // Window shape with plus sign
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .stroke(lineWidth: 3)
                .frame(width: 200, height: 400)
                .foregroundColor(.gray)

            // Plus sign
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.gray)
        }
        .frame(width: 200, height: 450)
    }
}


//Preview provider for SwiftUI canvas
struct LandingPageView_Previews: PreviewProvider {
    static var previews: some View {
        LandingPageView()
    }
}

