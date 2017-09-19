//
//  BluetoothManager.swift
//  SwiftMomentSDK
//
//  Created by Jacob Rockland on 2/22/17.
//  Copyright © 2017 Somatic Technologies, Inc. All rights reserved.
//

import SwiftyBluetooth
import CoreBluetooth

// MARK: - Manager Error Enumeration

/**
 Error type for generating custom errors
 */
final internal class ManagerError: NSError {
    
    /**
     Error initializer, sets localized description to `String` passed in
     */
    init(_ localizedDescription: String) {
        super.init(domain: "com.SomaticLabs.SwiftMomentSDK", code: 404, userInfo: [NSLocalizedDescriptionKey: localizedDescription])
    }
    
    /**
     Required coder initializer
     */
    required init?(coder aDecoder: NSCoder) {
        // Calls super
        super.init(coder: aDecoder)
    }
    
}

// MARK: - Bluetooth Manager Class

/// Global variable readily allows access to singleton manager
internal let bluetoothManager = BluetoothManager.sharedInstance

/**
 Creates a singleton-based wrapper for `CoreBluetooth` framework, to prevent issue of multiple `CBCentralManager` instances
 */
final internal class BluetoothManager: NSObject {
    
    // MARK: - Packet Queue
    
    /// A simple FIFO (first in, first out) queue for managing data to be written to the Javascript BLE characteristic (thread safe)
    final internal class PacketQueue {
        /// Internal array for managing queue
        private var array = [ArraySlice<UInt8>]()
        
        /// Internal access queue for managing packet queue
        private let accessQueue = DispatchQueue(label: "SynchronizedArrayAccess", attributes: .concurrent)
        
        /// Variable for counting the number of packet sets queued
        var numSets = 0
        
        /// Variable for getting count in queue
        var count: Int {
            var count = 0
            
            accessQueue.sync {
                count = self.array.count
            }
            
            return count
        }
        
        /// Variable for checking if the queue is empty
        var isEmpty: Bool {
            var isEmpty = true
            
            accessQueue.sync {
                isEmpty = self.array.isEmpty
            }
            
            return isEmpty
        }
        
        /// Method for adding item to the queue
        func enqueue(_ element: ArraySlice<UInt8>) {
            accessQueue.async(flags:.barrier) {
                self.array.append(element)
            }
        }
        
        /// Method for removing item from the queue
        func dequeue() -> ArraySlice<UInt8>? {
            var element: ArraySlice<UInt8>? = nil
            
            accessQueue.sync {
                element = self.array.first
            }
            
            accessQueue.async(flags:.barrier) {
                self.array.removeFirst()
            }
            
            return element
        }
    }

    // MARK: - Singleton Properties
    
    /// Creates only instance of this class, enforcing singleton model
    static let sharedInstance = BluetoothManager()
    
    /// `SwiftyBluetooth` central manager
    var central: Central
    
    /// `SwiftyBluetooth` peripheral for Moment
    var peripheral: Peripheral?
    
    /// `PacketQueue` for storing Javascript packets to be sent
    var packetQueue: PacketQueue

    // MARK: - Initialization
    
    /**
     Private initialization, prevents others from using the default '()' initializer for this class
     */
    override private init() {
        central = Central.sharedInstance
        packetQueue = PacketQueue()
        super.init()
    }
    
    // MARK: - Connection and Transmission Functions

    /**
     Called to initiate connection with Moment, handles reconnection process based on this logical diagram: ![Reconnection flow chart](https://developer.apple.com/library/content/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/Art/ReconnectingToAPeripheral_2x.png "Reconnection workflow")
     */
    func connect(completion: @escaping ConnectPeripheralCallback) {
        // Identifier and services for device of interest
        var uuid: UUID?
        let services: [CBUUID]
        
        // Check if we have connected to this peripheral before, and get it's UUID and associated services
        uuid = Settings.getMomentPeripheral()
        services = Identifiers.AdvertisedServices
        
        // If we do, try to connect to it
        if let uuid = uuid {
            // First try known peripherals, otherwise try other peripherals connected to system
            if let peripheral = central.retrievePeripherals(withUUIDs: [uuid]).first {
                peripheral.connect(withTimeout: Constants.connectTimeout) { result in
                    switch result {
                    case .success:
                        // Validate name
                        guard peripheral.name == Constants.deviceName else {
                            // Treat as error and handle in completion
                            let error = ManagerError("Unexpectedly connected to \(peripheral.name ?? "Unknown").")
                            completion(.failure(error))
                            
                            return // Exit
                        }
                        
                        // Update internal `Peripheral` and handle in completion
                        self.peripheral = peripheral
                        completion(.success())
                    case .failure(let error):
                        // Treat as error and handle in completion
                        completion(.failure(error))
                    }
                }
                return // Exit
            }
        } else {
            let connectedPeripherals = central.retrieveConnectedPeripherals(withServiceUUIDs: services)
            for peripheral in connectedPeripherals {
                if peripheral.name == Constants.deviceName {
                    peripheral.connect(withTimeout: Constants.connectTimeout) { result in
                        switch result {
                        case .success:
                            // Validate name
                            guard peripheral.name == Constants.deviceName else {
                                // Treat as error and handle in completion
                                let error = ManagerError("Unexpectedly connected to \(peripheral.name ?? "Unknown").")
                                completion(.failure(error))
                                
                                return // Exit
                            }
                            
                            // Store peripheral as our known peripheral in settings
                            Settings.saveMomentPeripheral(with: peripheral.identifier)
                            
                            // Update internal `Peripheral` and handle in completion
                            self.peripheral = peripheral
                            completion(.success())
                        case .failure(let error):
                            // Treat as error and handle in completion
                            completion(.failure(error))
                        }
                    }
                    return // Exit
                }
            }
        }
        
        // Otherwise, scan for peripheral and connect
        SwiftyBluetooth.scanForPeripherals(withServiceUUIDs: services, timeoutAfter: Constants.scanTimeout) { scanResult in
            switch scanResult {
            case .scanStarted:
                // The scan started meaning CBCentralManager scanForPeripherals(...) was called
                break
            case .scanResult(let peripheral, _, _):
                // A peripheral was found, your closure may be called multiple time with a .ScanResult enum case.
                
                // Prevent forced disconnection
                let peripheral = peripheral
                
                // Check if found peripheral is the one we're trying to connect to
                if peripheral.name == Constants.deviceName {
                    // Stop scanning
                    SwiftyBluetooth.stopScan()
                    
                    // Store peripheral as our known peripheral in settings
                    Settings.saveMomentPeripheral(with: peripheral.identifier)
                    
                    // Initiate connection to peripheral
                    peripheral.connect(withTimeout: Constants.connectTimeout) { result in
                        switch result {
                        case .success:
                            // Validate name
                            guard peripheral.name == Constants.deviceName else {
                                // Treat as error and handle in completion
                                let error = ManagerError("Unexpectedly connected to \(peripheral.name ?? "Unknown").")
                                completion(.failure(error))
                                
                                return // Exit
                            }
                            
                            // Update internal `Peripheral` and handle in completion
                            self.peripheral = peripheral
                            completion(.success())
                        case .failure(let error):
                            // Treat as error and handle in completion
                            completion(.failure(error))
                        }
                    }
                }
            case .scanStopped(let error):
                // The scan stopped, an error is passed if the scan stopped unexpectedly
                guard error == nil else {
                    // Treat as error and handle in completion
                    completion(.failure(error ?? ManagerError("Failed to discover Moment peripheral.")))
                    
                    return // Exit
                }
            }
        }
    }
    
    /**
     Obtains the current revision version of the firmware on the device
     */
    func readVersion(completion: @escaping (Result<String>) -> Void) {
        // Ensure that we already have a reference to Moment peripheral
        guard let peripheral = peripheral else {
            // Treat as error and handle in completion
            let error = ManagerError("Not connected to Moment peripheral!")
            completion(.failure(error))
            
            return // Exit
        }
        
        // Read data from the device information service
        peripheral.readValue(ofCharacWithUUID: Identifiers.FirmwareRevisionStringCharacteristicUUID, fromServiceWithUUID: Identifiers.DeviceInformationServiceUUID) { result in
            switch result {
            case .success(let data):
                // Successfully notifying on battery characteristic
                guard let string = String(bytes: data, encoding: String.Encoding.utf8) else {
                    let error = ManagerError("Unable to extract string data from firmware revision string characteristic.")
                    completion(.failure(error))
                    return // Exit
                }
                completion(.success(string))
            case .failure(let error):
                // Treat as error and handle in completion
                completion(.failure(error))
            }
        }
    }
    
    /**
     Obtains the current serial number of the paired device
     */
    func readSerial(completion: @escaping (Result<String>) -> Void) {
        // Ensure that we already have a reference to Moment peripheral
        guard let peripheral = peripheral else {
            // Treat as error and handle in completion
            let error = ManagerError("Not connected to Moment peripheral!")
            completion(.failure(error))
            
            return // Exit
        }

        // Read data from the device information service
        peripheral.readValue(ofCharacWithUUID: Identifiers.SerialNumberStringCharacteristicUUID, fromServiceWithUUID: Identifiers.DeviceInformationServiceUUID) { result in
            switch result {
            case .success(let data):
                // Successfully notifying on battery characteristic
                guard let string = String(bytes: data, encoding: String.Encoding.utf8) else {
                    let error = ManagerError("Unable to extract string data from firmware revision string characteristic.")
                    completion(.failure(error))
                    return // Exit
                }
                completion(.success(string))
            case .failure(let error):
                // Treat as error and handle in completion
                completion(.failure(error))
            }
        }
    }
    
    /**
     Writes provided data to the appropriate characteristic
     
     - Parameter bytes: The `Data` byte representation of the settings data to be written
     
     - Parameter characteristic: The `UUID` of the characteristic being written to
     */
    func writeBytes(_ bytes: Data, to characteristic: CBUUID, completion: @escaping WriteRequestCallback) {
        // Ensure that we already have a reference to Moment peripheral
        guard let peripheral = peripheral else {
            // Treat as error and handle in completion
            let error = ManagerError("Not connected to Moment peripheral!")
            completion(.failure(error))
            
            return // Exit
        }

        // Write data to settings characteristic
        peripheral.writeValue(ofCharacWithUUID: characteristic, fromServiceWithUUID: Identifiers.HapticTimelineServiceUUID, value: bytes) { result in
            completion(result)
        }
    }
    
    /**
     Writes provided Javascript bytecode data to the SDK UART service
     
     - Parameter bytes: Byte representation of the Javascript bytecode to be written
     */
    func writeJavascript(_ bytes: Data, completion: @escaping WriteRequestCallback) {
        // Ensure that we already have a reference to Moment peripheral
        guard let peripheral = peripheral else {
            // Treat as error and handle in completion
            let error = ManagerError("Not connected to Moment peripheral!")
            completion(.failure(error))
            
            return // Exit
        }
        
        // If bytes are empty, send only the integer 0
        if bytes.count == 0 {
            let bytes = Data(bytes: [UInt8(0)])
            packetQueue.enqueue(ArraySlice(bytes))
        } else {
            // Split data in 20-byte packets and fill packet list
            let packetCount = Int(ceil(Double(bytes.count + 1) / 20))
            let bytes = Data(bytes: [UInt8(packetCount)]) + bytes
            for i in 0..<packetCount {
                let min = i * 20
                let max = (((i + 1) * 20) < bytes.count) ? ((i + 1) * 20) : bytes.count
                let packet = ArraySlice(bytes[min..<max])
                packetQueue.enqueue(packet)
            }
        }
        
        // Create recursive writing function
        func recursiveWrite(completion: @escaping WriteRequestCallback) {
            DispatchQueue.main.async {
                if self.packetQueue.isEmpty {
                    // Handle base case
                    while self.packetQueue.numSets > 0 {
                        completion(.success())
                        self.packetQueue.numSets -= 1
                    }
                } else {
                    // Get data to send
                    guard let packet = self.packetQueue.dequeue() else {
                        return
                    }
                    let data = Data(bytes: packet)
                    
                    // Handle recursive case
                    peripheral.writeValue(ofCharacWithUUID: Identifiers.NordicUARTRXCharacteristicUUID, fromServiceWithUUID: Identifiers.NordicUARTServiceUUID, value: data) { result in
                        switch result {
                        case .success:
                            recursiveWrite(completion: completion)
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                }
            }
        }

        // Write data to our characteristic if write not already in process of writing
        packetQueue.numSets += 1
        recursiveWrite() { result in completion(result) }
    }
    
}
