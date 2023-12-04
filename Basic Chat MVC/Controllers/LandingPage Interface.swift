//
//  LandingPage Interface.swift
//  Tynt Demo
//
//  Created by Alakh Naik on 10/31/23.
//

import SwiftUI

// Define your data model
struct Room : Codable {
    var name: String
    var windows: [String]
        
        // Initialize with no windows by default
        init(name: String, windows: [String] = []) {
            self.name = name
            self.windows = windows
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
    }
}


struct LandingPageView: View {
    @State private var selectedRoomIndex: Int? = 0
    @State private var showingAddRoomView = false
    @ObservedObject var roomsData = RoomsData()
    @State private var showingEditRoomView = false
    @State private var editingRoomIndex: Int?
    @State private var showingPairingSheet = false
    @ObservedObject private var bluetoothManager = BluetoothManager()

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Image("Logo_Full")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 50)
            }
            .padding(.top)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(roomsData.rooms.indices, id: \.self) { index in
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
                            }
                        }
                        .sheet(isPresented: $showingEditRoomView) {
                            if let editingIndex = editingRoomIndex {
                                AddRoomView(rooms: $roomsData.rooms, roomName: roomsData.rooms[editingIndex].name, roomIndex: editingIndex)
                            }
                        }
                    }
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
                .padding(.horizontal)
            }

            VStack {
                
                if roomsData.rooms.isEmpty {
                    // Provide a UI element to indicate that no rooms are available
                    Button(action: {
                                            showingPairingSheet = bluetoothManager.isBluetoothEnabled
                                        }) {
                                            WindowButtonView()
                                            Spacer()
                                        }
                                        .disabled(true) // Disabled because there are no rooms
                                        .padding()
                                        .cornerRadius(10)
                                        .background(Color.white)
                                        .foregroundColor(.white)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            if let selectedIndex = selectedRoomIndex, roomsData.rooms.indices.contains(selectedIndex) {
                                ForEach(roomsData.rooms[selectedIndex].windows, id: \.self) { window in
                                    Text(window)
                                }
                                Button(action: {
                                    showingPairingSheet = bluetoothManager.isBluetoothEnabled
                                }) {
                                    WindowButtonView()
                                }
                                .disabled(!bluetoothManager.isBluetoothEnabled)
                                .disabled(roomsData.rooms.isEmpty || selectedRoomIndex == nil)
                                .padding(.horizontal, 2)
                                .padding(.vertical, 20)
                                .background(Color.white)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .sheet(isPresented: $showingPairingSheet) {
                                    PairingInterfaceView(selectedRoom: $roomsData.rooms[selectedIndex], bluetoothManager: BluetoothManager()) { selectedDevice, newName in
                                        if let selectedIndex = selectedRoomIndex {
                                            let windowName = newName.isEmpty ? (selectedDevice.name ?? "Unknown") : newName
                                            roomsData.rooms[selectedIndex].windows.append(windowName)
                                        }
                                    }
                                }
                            } else {
                                Text("Select a room to see its windows")
                                    .padding()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .transition(.slide)
            Spacer()
        }
        .onAppear {
            if !roomsData.rooms.isEmpty && (selectedRoomIndex == nil || selectedRoomIndex! >= roomsData.rooms.count) {
                            selectedRoomIndex = 0
                        }
                }
    }
}

//Preview provider for SwiftUI canvas
struct LandingPageView_Previews: PreviewProvider {
    static var previews: some View {
        LandingPageView()
    }
}

