//
//  BluetoothManager.swift
//  SwiftyZorb
//
//  Created by Jacob Rockland on 2/22/17.
//  Copyright © 2017 Somatic Technologies, Inc. All rights reserved.
//

import SwiftyBluetooth
import CoreBluetooth

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
    
    /// `ZorbDevice` for stored peripheral device
    var device: ZorbDevice?
    
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
     Called to initiate connection with Zorb peripheral, handles reconnection process based on this logical diagram: ![Reconnection flow chart](https://developer.apple.com/library/content/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/Art/ReconnectingToAPeripheral_2x.png "Reconnection workflow")
     */
    func connect(completion: @escaping ConnectPeripheralCallback) {
        // Identifier and services for device of interest
        var uuid: UUID?
        let services: [CBUUID]
        
        // Check if we have connected to this peripheral before, and get it's UUID and associated services
        uuid = Settings.getZorbPeripheral()
        services = Identifiers.AdvertisedServices
        
        // If we do, try to connect to it
        if let uuid = uuid {
            // First try known peripherals, otherwise try other peripherals connected to system
            if let peripheral = central.retrievePeripherals(withUUIDs: [uuid]).first {
                peripheral.connect(withTimeout: Constants.connectTimeout) { result in
                    switch result {
                    case .success(let value):
                        // Validate name
                        guard Constants.deviceNames.contains(peripheral.name!) else {
                            // Treat as error and handle in completion
                            let error = ManagerError("Unexpectedly connected to \(peripheral.name ?? "Unknown").")
                            completion(.failure(error))
                            
                            return // Exit
                        }
                        
                        // Update internal `ZorbDevice` and handle in completion
                        self.device = ZorbDevice(with: peripheral)
                        completion(.success(value))
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
                if Constants.deviceNames.contains(peripheral.name!) {
                    peripheral.connect(withTimeout: Constants.connectTimeout) { result in
                        switch result {
                        case .success(let value):
                            // Validate name
                            guard Constants.deviceNames.contains(peripheral.name!) else {
                                // Treat as error and handle in completion
                                let error = ManagerError("Unexpectedly connected to \(peripheral.name ?? "Unknown").")
                                completion(.failure(error))
                                
                                return // Exit
                            }
                            
                            // Store peripheral as our known peripheral in settings
                            Settings.saveZorbPeripheral(with: peripheral.identifier)
                            
                            // Update internal `ZorbDevice` and handle in completion
                            self.device = ZorbDevice(with: peripheral)
                            completion(.success(value))
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
                if Constants.deviceNames.contains(peripheral.name!) {
                    // Stop scanning
                    SwiftyBluetooth.stopScan()
                    
                    // Store peripheral as our known peripheral in settings
                    Settings.saveZorbPeripheral(with: peripheral.identifier)
                    
                    // Initiate connection to peripheral
                    peripheral.connect(withTimeout: Constants.connectTimeout) { result in
                        switch result {
                        case .success(let value):
                            // Validate name
                            guard Constants.deviceNames.contains(peripheral.name!) else {
                                // Treat as error and handle in completion
                                let error = ManagerError("Unexpectedly connected to \(peripheral.name ?? "Unknown").")
                                completion(.failure(error))
                                
                                return // Exit
                            }
                            
                            // Update internal `ZorbDevice` and handle in completion
                            self.device = ZorbDevice(with: peripheral)
                            completion(.success(value))
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
                    completion(.failure(error ?? ManagerError("Failed to discover Zorb peripheral.")))
                    
                    return // Exit
                }
            }
        }
    }
    
    /**
     Scans for and retrieves a collection of available Zorb devices
    */
    func retrieveAvailableDevices(completion: @escaping (Result<[ZorbDevice]>) -> Void) {
        // Initialize collection of available peripherals
        var peripherals: [ZorbDevice] = []
        
        // Get associated Zorb device services
        let services = Identifiers.AdvertisedServices
        
        // First add any already connected peripherals to our collection
        let connectedPeripherals = central.retrieveConnectedPeripherals(withServiceUUIDs: services)
        for peripheral in connectedPeripherals {
            if Constants.deviceNames.contains(peripheral.name!) {
                peripherals.append(ZorbDevice(with: peripheral))
            }
        }

        // Next scan for any advertising devices and add them to our collection
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
                if Constants.deviceNames.contains(peripheral.name!) {
                    peripherals.append(ZorbDevice(with: peripheral))
                }
            case .scanStopped(let error):
                // The scan stopped, an error is passed if the scan stopped unexpectedly
                guard error == nil else {
                    // Treat as error and handle in completion
                    completion(.failure(error ?? ManagerError("Failed to discover Zorb peripheral.")))
                    
                    return // Exit
                }
                
                // Call completion handler with all available peripherals
                completion(.success(peripherals))
            }
        }
    }
    
}
