//
//  SwiftMomentSDK.swift
//  SwiftMomentSDK
//
//  Created by Jacob Rockland on 2/22/17.
//  Copyright © 2017 Somatic Technologies, Inc. All rights reserved.
//

import SwiftyBluetooth
import Alamofire
import SwiftyJSON

// MARK: Bluetooth Management Methods

/**
 Initiates a connection to an advertising Moment device.
 
 Usage Example:
 
 ```swift
 // Attempts connection to an advertising device
 SwiftMomentSDK.connect { result in
    switch result {
    case .success:
        // Connected succeeded
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
 SwiftMomentSDK.disconnect()
 ```
 */
public func disconnect() {
    bluetoothManager.peripheral?.disconnect { _ in }
}

/**
 Forgets previously stored Moment connection.
 
 Usage Example:
 
 ```swift
 // After calling this method, a new Moment connection can be created
 SwiftMomentSDK.forget()
 ```
 */
public func forget() {
    Settings.resetMomentPeripheral()
}

// MARK: Bluetooth Javascript Methods


/**
 Writes the appropriate string to reset Moment's Javascript virtual machine.
 
 Usage Example:
 
 ```swift
 SwiftMomentSDK.reset { result in
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
    bluetoothManager.writeJavascript(Data()) { result in completion(result) }
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
 SwiftMomentSDK.writeJavascript(javascript) { result in
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
            bluetoothManager.writeJavascript(bytes) { result in completion(result) }
        case .failure(let error):
            completion(.failure(error))
        }
    }
}

/**
 Writes a given string of base64 encoded bytecode to the connected Moment device.
 
 Usage Example:
 
 ```swift
 let bytecode = "BgAAAFAAAAAsAAAAAQAAAAQAAQABAAUAAAEDBAYAAQACAAYAOwABKQIDxEYBAAAABAABACEAAwABAgMDAAAGAAgAOwECt8gARgAAAAAAAAAFAAAAAAAAAAIAb24JAHRpbWVydGljawABAHQABgBNb21lbnQGAHVwdGltZQ=="
 SwiftMomentSDK.writeBytecode(bytecode) { result in
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
public func writeBytecode(_ bytecode: String, completion: @escaping WriteRequestCallback) {
    // Write compiled Javascript to our device
    guard let bytes = Data(base64Encoded: bytecode) else {
        completion(.failure(ManagerError("Invalid base64 encoded bytecode string.")))
        return // Exit
    }
    bluetoothManager.writeJavascript(bytes) { result in completion(result) }
}

/**
 Writes the Javascript code at a given URL to the connected Moment device.
 
 Usage Example:
 
 ```swift
 let url = URL(string: "https://gist.github.com/jakerockland/1de44467c3eaf132a2089b6c88d680b8/raw")!
 SwiftMomentSDK.writeJavascript(at url) { result in
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
            bluetoothManager.writeJavascript(bytes) { result in completion(result) }
        case .failure(let error):
            completion(.failure(error))
        }
    }
}

/**
 Writes the Javascript bytecode at a given URL to the connected Moment device.
 
 Usage Example:
 
 ```swift
 let url = URL(string: "https://gist.github.com/jakerockland/1de44467c3eaf132a2089b6c88d680b8/raw")!
 SwiftMomentSDK.writeBytecode(at url) { result in
    switch result {
    case .success:
        // Write succeeded
    case .failure(let error):
        // An error occurred during write
    }
 }
 ```
 
 - Parameter url: A URL to the hosted Javascript bytecode script to be written
 */
public func writeBytecode(at url: URL, completion: @escaping WriteRequestCallback) {
    // Download compiled Javascript and write it to our device
    Alamofire.request(url)
        .validate()
        .responseString { response in
        // Handle response appropriately
        switch response.result {
        case .success(let bytecode):
            guard let bytes = Data(base64Encoded: bytecode) else {
                completion(.failure(ManagerError("Invalid base64 encoded bytecode string.")))
                return // Exit
            }
            bluetoothManager.writeJavascript(bytes) { result in completion(result) }
        case .failure(let error):
            completion(.failure(error))
        }
    }
}
