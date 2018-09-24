//
//  ZorbDevice.swift
//  SwiftyZorb
//
//  Created by Jacob Rockland on 12/22/17.
//  Copyright © 2017 Somatic Technologies, Inc. All rights reserved.
//

import SwiftyBluetooth
import CoreBluetooth
import Alamofire

// MARK: - Zorb Device

/**
 Class encapsulating the all necessary functions for a given device peripheral
 */
final public class ZorbDevice {
    
    // MARK: - Class Properties
    
    /// `SwiftyBluetooth` peripheral for device
    private var peripheral: Peripheral
    
    /// `PacketQueue` for storing Javascript packets to be sent
    private var packetQueue: PacketQueue
    
    // MARK: - Initialization
    
    /**
     Public initializer, only requires peripheral associated with given device
     
     - Parameter peripheral: 
     */
    internal init(with peripheral: Peripheral) {
        self.peripheral = peripheral
        self.packetQueue = PacketQueue()
    }
    
    // MARK: - Private Connection Management Methods
    
    /**
     Writes provided data to the appropriate characteristic
     
     - Parameter bytes: The `Data` byte representation of the data to be written
     
     - Parameter characteristic: The `UUID` of the characteristic being written to
     */
    private func writeBytes(_ bytes: Data, to characteristic: CBUUID, completion: @escaping WriteRequestCallback) {
        // Write data to settings characteristic
        peripheral.writeValue(ofCharacWithUUID: characteristic, fromServiceWithUUID: Identifiers.HapticTimelineServiceUUID, value: bytes) { result in
            completion(result)
        }
    }
    
    /**
     Writes provided Javascript bytecode data to the SDK UART service
     
     - Parameter bytes: Byte representation of the Javascript bytecode to be written
     */
    private func writeBytecode(_ bytes: Data, completion: @escaping WriteRequestCallback) {
        // Fill the packet queue appropriately based on `bytes` to be written
        if bytes.count == 0 {
            // If bytes are empty, send byte-array containing only the integer 0
            
            // This indicates to the receiving firmware that an empty message has been sent
            let uZero = UInt8(0)
            
            let bytes = Data(bytes: [uZero])
            packetQueue.enqueue(ArraySlice(bytes))
        } else {
            // If bytes are not empty, split data in 20-byte packets and fill packet queue
            
            // Because we want to include the number of packets as the first byte in our message,
            // we must add 1 to the count of bytes before calculating the packet count
            let packetCount = Int(ceil(Double(bytes.count + 1) / 20))
            
            // We then append a byte containing number of packets to be sent to our byte-array
            let bytes = Data(bytes: [UInt8(packetCount)]) + bytes
            
            // For each of the packets that we plan to send, iterate through the byte array and slice off
            // a 20-byte section of bytes.
            for i in 0..<packetCount {
                // Min slice is always (i * 20)
                let sliceMin = i * 20
                
                // Max slice changes conditionally depending on if we within bounds of the end of our byte-array
                // If we are within bounds, we slice to (i + 1 * 20) otherwise to the end of our byte-array
                let sliceInBounds = (((i + 1) * 20) < bytes.count)
                let sliceMax = sliceInBounds ? ((i + 1) * 20) : bytes.count
                
                let packet = ArraySlice(bytes[sliceMin..<sliceMax])
                packetQueue.enqueue(packet)
            }
        }
        
        // Create recursive function to send Bluetooth packet on successful write of previous packet
        func recursiveWrite(completion: @escaping WriteRequestCallback) {
            DispatchQueue.main.async {
                // Check if there are still remaining packets in the queue
                if self.packetQueue.isEmpty {
                    // Handle base case
                    while self.packetQueue.numSets > 0 {
                        completion(.success(()))
                        self.packetQueue.numSets -= 1
                    }
                } else {
                    // Get data to send from packet queue
                    guard let packet = self.packetQueue.dequeue() else {
                        return
                    }
                    let data = Data(bytes: packet)
                    
                    // Handle recursive case
                    self.peripheral.writeValue(ofCharacWithUUID: Identifiers.NordicUARTRXCharacteristicUUID, fromServiceWithUUID: Identifiers.NordicUARTServiceUUID, value: data) { result in
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

    // MARK: - Public Connection Management Methods
    
    /**
     Called to initiate connection with a given zorb device
     
     Usage Example:
     
     ```swift
     // Create a `ZorbDevice` object for a given Bluetooth peripheral (or this object may have
     // already been created as in the case of using `retrieveAvailableDevices` method of SDK
     let device = ZorbDevice(with: peripheral)
     
     // Attempts connection to an advertising device
     device.connect { result in
         switch result {
         case .success:
            // Connect succeeded
         case .failure(let error):
            // An error occurred during connection
         }
     }
     ```
     */
    public func connect(completion: @escaping ConnectPeripheralCallback) {
        peripheral.connect(withTimeout: Constants.connectTimeout) { result in
            completion(result)
        }
    }
    
    /**
     Called to end connection with a given zorb device
     
     Usage Example:
     
     ```swift
     // Create a `ZorbDevice` object for a given Bluetooth peripheral (or this object may have
     // already been created as in the case of using `retrieveAvailableDevices` method of SDK
     let device = ZorbDevice(with: peripheral)
     
     // After calling this method, device disconnection will be guaranteed
     device.disconnect()
     ```
     */
    public func disconnect() {
        peripheral.disconnect { _ in }
    }
    
    
    /**
     Writes the appropriate command to reset given device's Javascript virtual machine.
     
     Usage Example:
     
     ```swift
     // Create a `ZorbDevice` object for a given Bluetooth peripheral (or this object may have
     // already been created as in the case of using `retrieveAvailableDevices` method of SDK
     let device = ZorbDevice(with: peripheral)
     
     // Reset device SDK environment
     device.reset { result in
         switch result {
         case .success:
            // Reset succeeded
         case .failure(let error):
            // An error occurred during reset
         }
     }
     ```
     */
    public func reset(completion: @escaping WriteRequestCallback) {
        self.writeBytecode(Data()) { result in
            // FIXME: Having to use this dispatch queue is strange, it seems this issue stems from the firmware where the receiver callback is sent before the reset has completed, not sure if this is fixable in firmware or if this delay is the only solution
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                completion(result)
            }
        }
    }
    
    /**
     Obtains the current revision version of the firmware on the device
     
     Usage Example:
     
     ```swift
     // Create a `ZorbDevice` object for a given Bluetooth peripheral (or this object may have
     // already been created as in the case of using `retrieveAvailableDevices` method of SDK
     let device = ZorbDevice(with: peripheral)
     
     // Read version from device
     device.readVersion { result in
         switch result {
         case .success(let version):
            // Reading version string succeeded
         case .failure(let error):
            // An error occurred during read
         }
     }
     ```
     */
    public func readVersion(completion: @escaping (SwiftyBluetooth.Result<String>) -> Void) {
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
     
     Usage Example:
     
     ```swift
     // Create a `ZorbDevice` object for a given Bluetooth peripheral (or this object may have
     // already been created as in the case of using `retrieveAvailableDevices` method of SDK
     let device = ZorbDevice(with: peripheral)
     
     // Read serial from device
     device.readSerial { result in
         switch result {
         case .success(let serial):
            // Reading version string succeeded
         case .failure(let error):
            // An error occurred during read
         }
     }
     ```
     */
    public func readSerial(completion: @escaping (SwiftyBluetooth.Result<String>) -> Void) {
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
     Writes desired actuator data to given device.
     
     Usage Example:
     
     ```swift
     // Create a `ZorbDevice` object for a given Bluetooth peripheral (or this object may have
     // already been created as in the case of using `retrieveAvailableDevices` method of SDK
     let device = ZorbDevice(with: peripheral)
     
     // Write data to device actuators
     device.writeActuators(duration: 100, topLeft: 0, topRight: 0, bottomLeft: 25, bottomRight: 25) { result in
         switch result {
         case .success:
            // Write succeeded
         case .failure(let error):
            // An error occurred during write
         }
     }
     ```
     
     - Parameter duration: The total duration, in milliseconds for the given set of vibrations to last.
     
     - Parameter topLeft: Intensity, in a range from 0 to 100, for the top left actuator to be set at.
     
     - Parameter topRight: Intensity, in a range from 0 to 100, for the top right actuator to be set at.
     
     - Parameter bottomLeft: Intensity, in a range from 0 to 100, for the bottom left actuator to be set at.
     
     - Parameter bottomRight: Intensity, in a range from 0 to 100, for the bottom right actuator to be set at.
     */
    public func writeActuators(duration: UInt16, topLeft: UInt8, topRight: UInt8, bottomLeft: UInt8, bottomRight: UInt8, completion: @escaping WriteRequestCallback) {
        // Determine data to send
        let duration0: UInt8 = UInt8(duration & 0x00FF)
        let duration1: UInt8 = UInt8(duration >> 8)
        let data = Data(bytes: [duration0, duration1, topLeft, topRight, bottomLeft, bottomRight])
        
        // Write actuator data to Zorb device
        self.writeBytes(data, to: Identifiers.ActuatorCharacteristicUUID) { result in completion(result) }
    }
    
    /**
     Writes a given string of Javascript to the given device.
     Using this method requires internet connection, which is used to compile the Javascript to bytecode before transmission.
     
     Usage Example:
     
     ```swift
     // Create a `ZorbDevice` object for a given Bluetooth peripheral (or this object may have
     // already been created as in the case of using `retrieveAvailableDevices` method of SDK
     let device = ZorbDevice(with: peripheral)
     
     // Write Javascript to device
     let javascript = "new Zorb.Vibration(" +
         "0," +
         "new Zorb.Effect(0,100,11,250)," +
         "213" +
         ").start();"
     device.writeJavascript(javascript) { result in
         switch result {
         case .success:
            // Write succeeded
         case .failure(let error):
            // An error occurred during write
         }
     }
     ```
     
     - Parameter javascript: The Javascript code to be written
     */
    public func writeJavascript(_ javascript: String, completion: @escaping WriteRequestCallback) {
        // Compile Javascript and write it to our device
        let params: Parameters = [
            "js": javascript
        ]
        Alamofire.request(Constants.javascriptCompilerURL, method: .post, parameters: params)
            .validate()
            .responseData { response in
                // Handle response appropriately
                switch response.result {
                case .success(let bytes):
                    self.writeBytecode(bytes) { result in completion(result) }
                case .failure(let error):
                    completion(.failure(error))
                }
        }
    }
    
    /**
     Writes the Javascript code at a given URL to the given device.
     
     Usage Example:
     
     ```swift
     // Create a `ZorbDevice` object for a given Bluetooth peripheral (or this object may have
     // already been created as in the case of using `retrieveAvailableDevices` method of SDK
     let device = ZorbDevice(with: peripheral)
     
     // Write Javascript from url to device
     let url = URL(string: "https://gist.githubusercontent.com/jakerockland/17cb9cbfda0e09fa8251fc7666e2c4dc/raw")!
     device.writeJavascript(at url) { result in
         switch result {
         case .success:
            // Write succeeded
         case .failure(let error):
            // An error occurred during write
         }
     }
     ```
     
     - Parameter url: A URL to the hosted Javascript script to be written
     */
    public func writeJavascript(at url: URL, completion: @escaping WriteRequestCallback) {
        // Add a random query based on the current time, so that we don't have issues with source file being cached
        let randomQuery = "?".appending(String(Int(NSDate().timeIntervalSince1970)))
        let url = URL(string: url.absoluteString + randomQuery)!
        
        // Compile Javascript and write it to our device
        let params: Parameters = [
            "src": url.absoluteString
        ]
        Alamofire.request(Constants.javascriptCompilerURL, method: .post, parameters: params)
            .validate()
            .responseData { response in
                // Handle response appropriately
                switch response.result {
                case .success(let bytes):
                    self.writeBytecode(bytes) { result in completion(result) }
                case .failure(let error):
                    completion(.failure(error))
                }
        }
    }
    
    /**
     Writes a Zorb_Timeline object (as specified by zorb.pb.swift) to the UART RX characteristic.
     
     Usage Example:
     
     ```swift
     // Create a `ZorbDevice` object for a given Bluetooth peripheral (or this object may have
     // already been created as in the case of using `retrieveAvailableDevices` method of SDK
     let device = ZorbDevice(with: peripheral)
     
     // Create Zorb_Timeline and Zorb_Vibration objects using the generated types provided by zorb.pb.swift.
     var timeline = Zorb_Timeline()
     var vibration = Zorb_Vibration()
     
     // Populate data in the Zorb_Vibration object.
     vibration.channels = 0x01
     vibration.delay = 1000
     vibration.duration = 2000
     vibration.position = 0
     vibration.start = 0
     vibration.end = 100
     vibration.easing = 2
     
     // Append the Zorb_Vibration to the Zorb_Timeline.
     timeline.vibrations.append(vibration)
     
     // Write the bytecode to the UART RX characteristic.
     device.writeTimeline(timeline) { result in
        switch result {
        case .success:
            // Write succeeded
        case .failure(let error):
            // An error occurred during write
        }
     }
     ```
     
     - Parameter timeline: A Zorb_Timeline object (from zorb-protocol)
     */
    public func writeTimeline(_ timeline: Zorb_Timeline, completion: @escaping WriteRequestCallback) {
        // Write a Zorb_Timeline protocol buffer to our device
        guard let bytes = try? timeline.serializedData() else {
            completion(.failure(ManagerError("Invalid base64 encoded bytecode string.")))
            return // Exit
        }
        self.writeBytecode(bytes) { result in completion(result) }
    }
    
    /**
     Writes a given string of base64 encoded bytecode to the given device.
     
     Usage Example:
     
     ```swift
     // Create a `ZorbDevice` object for a given Bluetooth peripheral (or this object may have
     // already been created as in the case of using `retrieveAvailableDevices` method of SDK
     let device = ZorbDevice(with: peripheral)
     
     // Write bytecode to device
     let bytecode = "BgAAAFAAAAAsAAAAAQAAAAQAAQABAAUAAAEDBAYAAQACAAYAOwABKQIDxEYBAAAABAABACEAAwABAgMDAAAGAAgAOwECt8gARgAAAAAAAAAFAAAAAAAAAAIAb24JAHRpbWVydGljawABAHQABgBNb21lbnQGAHVwdGltZQ=="
     device.writeBytecode(bytecode) { result in
         switch result {
         case .success:
            // Write succeeded
         case .failure(let error):
            // An error occurred during write
         }
     }
     ```
     
     - Parameter bytecode: The base64 encoded representation of pre-compiled Javascript bytecode to be written
     */
    public func writeBytecodeString(_ bytecode: String, completion: @escaping WriteRequestCallback) {
        // Write compiled Javascript to our device
        guard let bytes = Data(base64Encoded: bytecode) else {
            completion(.failure(ManagerError("Invalid base64 encoded bytecode string.")))
            return // Exit
        }
        self.writeBytecode(bytes) { result in completion(result) }
    }
    
    /**
    Triggers a given pre-loaded pattern on the given device

    Usage Example:

    ```swift
     device.triggerPattern(.🎊) { result in
         switch result {
         case .success:
            // Pattern triggered successfully
         case .failure(let error):
            // An error occurred in triggering pattern
         }
     }
    ```
     
     - Parameter pattern: The `Trigger` enumeration option of the given preloaded pattern to trigger
    */
    public func triggerPattern(_ pattern: Trigger, completion: @escaping WriteRequestCallback) {
        let byte = Data(pattern.rawValue.utf8.map{ UInt8($0) })
        self.writeBytes(byte, to: Identifiers.PatternTriggerCharacteristicUUID) {
            result in completion(result)
        }
    }
    
}

