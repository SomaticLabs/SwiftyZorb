//
//  SwiftyZorb.swift
//  SwiftyZorb
//
//  Created by Jacob Rockland on 2/22/17.
//  Copyright © 2017 Somatic Technologies, Inc. All rights reserved.
//

import SwiftyBluetooth
import Alamofire
import SwiftyJSON

// MARK: Bluetooth Management Methods

/**
 Scans for and retrieves a collection of available Zorb devices.
 
 Usage Example:
 
 ```swift
 // Retrieves a list all available devices as an array of `ZorbDevice` objects.
 SwiftyZorb.retrieveAvailableDevices { result in
    switch result {
    case .success(let devices):
        // Retrieval succeeded
        for device in devices {
            // Do something with devices
        }
    case .failure(let error):
        // An error occurred during retrieval
    }
 }
 ```
 */
public func retrieveAvailableDevices(completion: @escaping (SwiftyBluetooth.Result<[ZorbDevice]>) -> Void) {
    bluetoothManager.retrieveAvailableDevices { result in completion(result) }
}

/**
 Initiates a connection to an advertising Moment device.
 
 Usage Example:
 
 ```swift
 // Attempts connection to an advertising device
 SwiftyZorb.connect { result in
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
    bluetoothManager.connect { result in completion(result) }
}

/**
 Ends connection to a connected Moment device.
 
 Usage Example:
 
 ```swift
 // After calling this method, Moment disconnection will be guaranteed
 SwiftyZorb.disconnect()
 ```
 */
public func disconnect() {
    bluetoothManager.device?.disconnect()
}

/**
 Forgets previously stored Moment connection.
 
 Usage Example:
 
 ```swift
 // After calling this method, a new Moment connection can be created
 SwiftyZorb.forget()
 ```
 */
public func forget() {
    Settings.resetMomentPeripheral()
}

// MARK: Bluetooth Javascript Methods

/**
 Writes the appropriate command to reset connected Moment's Javascript virtual machine.
 
 Usage Example:
 
 ```swift
 SwiftyZorb.reset { result in
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
    bluetoothManager.device?.reset { result in completion(result) }
}

/**
 Reads version `String` from Moment device.
 
 Usage Example:
 
 ```swift
 SwiftyZorb.readVersion { result in
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
    bluetoothManager.device?.readVersion { result in completion(result) }
}

/**
 Reads serial `String` from Moment device.
 
 Usage Example:
 
 ```swift
 SwiftyZorb.readSerial { result in
     switch result {
     case .success(let serial):
        // Reading serial string succeeded
     case .failure(let error):
        // An error occurred during read
     }
 }
 ```
 */
public func readSerial(completion: @escaping (SwiftyBluetooth.Result<String>) -> Void) {
    bluetoothManager.device?.readSerial { result in completion(result) }
}

/**
 Writes desired actuator data to Moment device.
 
 Usage Example:
 
 ```swift
 SwiftyZorb.writeActuators(duration: 100, topLeft: 0, topRight: 0, bottomLeft: 25, bottomRight: 25) { result in
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
    bluetoothManager.device?.writeActuators(duration: duration, topLeft: topLeft, topRight: topRight, bottomLeft: bottomLeft, bottomRight: bottomRight) { result in completion(result) }
}

/**
 Writes desired settings to Moment device
 
 Usage Example:
 
 ```swift
 SwiftyZorb.writeSettings(wristOrientation: .left, buttonOrientation: .left, intensityLevel: .high) { result in
     switch result {
     case .success:
         // Settings update succeeded
     case .failure(let error):
         // An error occurred during settings update
     }
 }
 ```
 
 - Parameter wristOrientation: The wrist that Moment is being worn on, either `.left` or `.right`
 
 - Parameter buttonOrientation: The orientation that Moment's button is on, either `.left` or `right`
 
 - Parameter intensityLevel: The intensity level that Moment's vibrations will be at, either `.low`, `.medium`, or `.high`
 */
public func writeSettings(wristOrientation: Orientation, buttonOrientation: Orientation,  intensityLevel: Intensity, completion: @escaping WriteRequestCallback) {
    bluetoothManager.device?.writeSettings(wristOrientation: wristOrientation, buttonOrientation: buttonOrientation,  intensityLevel: intensityLevel) { result in completion(result) }
}

/**
 Writes a given string of Javascript to the connected Moment device. 
 Using this method requires internet connection, which is used to compile the Javascript to bytecode before transmission.
 
 Usage Example:
 
 ```swift
 let javascript = "Moment.on('timertick', function () {" +
 "var ms = Moment.uptime();" +
 "// do something time-related here" +
 "});"
 SwiftyZorb.writeJavascript(javascript) { result in
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
    bluetoothManager.device?.writeJavascript(javascript) { result in completion(result) }
}

/**
 Writes the Javascript code at a given URL to the connected Moment device.
 
 Usage Example:
 
 ```swift
 let url = URL(string: "https://gist.github.com/shantanubala/1f7d0dfb9bbef3edca8d0bb164c56aa0/raw")!
 SwiftyZorb.writeJavascript(at url) { result in
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
    bluetoothManager.device?.writeJavascript(at: url) { result in completion(result) }
}

/**
 Writes a given string of base64 encoded bytecode to the connected Moment device.
 
 Usage Example:
 
 ```swift
 let bytecode = "BgAAAFAAAAAsAAAAAQAAAAQAAQABAAUAAAEDBAYAAQACAAYAOwABKQIDxEYBAAAABAABACEAAwABAgMDAAAGAAgAOwECt8gARgAAAAAAAAAFAAAAAAAAAAIAb24JAHRpbWVydGljawABAHQABgBNb21lbnQGAHVwdGltZQ=="
 SwiftyZorb.writeBytecode(bytecode) { result in
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
    bluetoothManager.device?.writeBytecodeString(bytecode) { result in completion(result) }
}
