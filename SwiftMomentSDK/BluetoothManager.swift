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
        super.init(domain: "com.SomaticLabs.Moment", code: 404, userInfo: [NSLocalizedDescriptionKey: localizedDescription])
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

    // MARK: - Singleton Properties
    
    /// Creates only instance of this class, enforcing singleton model
    static let sharedInstance = BluetoothManager()
    
    /// `SwiftyBluetooth` central manager
    var central: Central
    
    /// `SwiftyBluetooth` peripheral for Moment
    var peripheral: Peripheral?

    // MARK: - Initialization
    
    /**
     Private initialization, prevents others from using the default '()' initializer for this class
     */
    override private init() {
        central = Central.sharedInstance
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
                        completion(.success(.noValue))
                    case .failure(let error):
                        // Treat as error and handle in completion
                        completion(.failure(error))
                    }
                }
                return // Exit
            } else {
                let connectedPeripherals = central.retrieveConnectedPeripherals(withServiceUUIDs: services)
                for peripheral in connectedPeripherals {
                    if peripheral.identifier == uuid {
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
                                completion(.success(.noValue))
                            case .failure(let error):
                                // Treat as error and handle in completion
                                completion(.failure(error))
                            }
                        }
                        return // Exit
                    }
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
                            completion(.success(.noValue))
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
     Writes a given `String` of Javascript data to the SDK UART service
     
     - Parameter javascript: The Javascript code to be written
     */
    func writeJavascript(_ javascript: String, completion: @escaping WriteRequestCallback) {
        // Ensure that we already have a reference to Moment peripheral
        guard let peripheral = peripheral else {
            // Treat as error and handle in completion
            let error = ManagerError("Not connected to Moment peripheral!")
            completion(.failure(error))
            
            return // Exit
        }
        
        // Wrap given Javascript string in an anonymous function and add a null terminating character
        let javascript = "(function(Moment){\(javascript)})(Moment);\0"
        
        // Create byte array from Javascript `String`
        let bytes = Array(javascript.utf8)
        
        // Create packet list
        var packetList = [ArraySlice<UInt8>]()
        
        // Split data in 20-byte packets and fill packet list
        for i in 0...(bytes.count / 20) {
            let min = i * 20
            let max = (((i + 1) * 20) < bytes.count) ? ((i + 1) * 20) : bytes.count
            let packet = bytes[min..<max]
            packetList.append(packet)
        }
        
        // Create recursive writing function
        func recursiveWrite(_ packetList: [ArraySlice<UInt8>], completion: @escaping WriteRequestCallback) {
            if packetList.isEmpty {
                // Handle base case
                completion(.success(.noValue))
            } else {
                // Handle recursive case
                var packetList = packetList
                let packet = packetList.removeFirst()
                let data = Data(bytes: packet)
                peripheral.writeValue(ofCharacWithUUID: Identifiers.NordicUARTRXCharacteristicUUID, fromServiceWithUUID: Identifiers.NordicUARTServiceUUID, value: data) { result in
                    switch result {
                    case .success:
                        recursiveWrite(packetList, completion: completion)
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
        
        // Write data to our characteristic
        recursiveWrite(packetList) { result in completion(result) }    }
}
