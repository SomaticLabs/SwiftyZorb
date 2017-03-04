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
    bluetoothManager.writeJavascript("Moment._reset_sdk();", anonymize: false) { result in completion(result) }
}

/**
 Writes a given string of Javascript to the connected Moment device.
 
 Usage Example:
 
 ```swift
 // Calling `writeContents` with optimization will require an extra HTTP request, 
 // but will result in much faster Bluetooth transfer. 
 //
 // However for short snippets of Javascript (under 40 bytes), 
 // such optimization may be unnecessary.
 let javascript = "Moment.LED.setColor(Moment.Color.ORANGE);"
 SwiftMomentSDK.writeContents(of javascript, optimize: false) { result in
    switch result {
    case .success:
        // Write succeeded
    case .failure(let error):
        // An error occurred during write
    }
 }
 ```
 
 - Parameter javascript: The Javascript code to be written
 
 - Parameter optimize: Boolean flag for whether or not the input Javascript should be optimized by the Google closure compiler. Default value is set to `true`, which is the recommended setting for best Bluetooth transfer speed, but can be set to false if alternative behavior is needed (one needs to avoid the extra HTTP request).
 */
public func writeContents(of javascript: String, optimize: Bool = true, completion: @escaping WriteRequestCallback) {
    // If optimization flag is set to true, run the Javascript through the Google closure compiler
    if optimize {
        let params: Parameters = [
            "js_code": javascript,
            "compilation_level": "SIMPLE_OPTIMIZATIONS",
            "output_format": "json",
            "output_info": "compiled_code"
        ]
        Alamofire.request(Constants.closureCompilerURL, method: .post, parameters: params, headers: Constants.closureCompilerHeaders)
            .validate()
            .responseJSON { response in
            // Handle response appropriately
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                if let errors = json["serverErrors"].array, let error = errors.first?["error"].string {
                    completion(.failure(ManagerError("Failed to load script, \(error).")))
                } else if let compiledCode = json["compiledCode"].string {
                    bluetoothManager.writeJavascript(compiledCode) { result in completion(result) }
                } else {
                    completion(.failure(ManagerError("Failed to load script, unknown error occurred.")))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    } else {
        bluetoothManager.writeJavascript(javascript) { result in completion(result) }
    }
}

/**
 Writes the Javascript code at a given URL to the connected Moment device.
 
 Usage Example:
 
 ```swift
 // Calling `writeScript` with optimization will require an extra HTTP request, 
 // but will result in much faster Bluetooth transfer. 
 //
 // For long JS scripts, optimization is strongly recommended.
 let url = URL(string: "https://gist.github.com/jakerockland/1de44467c3eaf132a2089b6c88d680b8")!
 SwiftMomentSDK.writeScript(at url) { result in
    switch result {
    case .success:
        // Write succeeded
    case .failure(let error):
        // An error occurred during write
    }
 }
 ```
 
 - Parameter script: A URL to the hosted Javascript script to be written
 
 - Parameter optimize: Boolean flag for whether or not the input Javascript should be optimized by the Google closure compiler. Default value is set to `true`, which is the recommended setting for best Bluetooth transfer speed, but can be set to false if alternative behavior is needed (one needs to avoid the extra HTTP request).
 */
public func writeScript(at url: URL, optimize: Bool = true, completion: @escaping WriteRequestCallback) {
    // Add a random query based on the current time, so that we don't have issues with source file being cached by Github
    let randomQuery = "?".appending(String(Int(NSDate().timeIntervalSince1970)))
    
    // Format the script URL to retrieve the raw text version
    let url = URL(string: url.appendingPathComponent("raw").absoluteString + randomQuery)!
    
    // If optimization flag is set to true, run the Javascript through the Google closure compiler
    if optimize {
        let params: Parameters = [
            "code_url": url.absoluteString,
            "compilation_level": "SIMPLE_OPTIMIZATIONS",
            "output_format": "json",
            "output_info": "compiled_code"
        ]
        Alamofire.request(Constants.closureCompilerURL, method: .post, parameters: params, headers: Constants.closureCompilerHeaders)
            .validate()
            .responseJSON { response in
            // Handle response appropriately
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                if let errors = json["serverErrors"].array, let error = errors.first?["error"].string {
                    completion(.failure(ManagerError("Failed to load script, \(error).")))
                } else if let compiledCode = json["compiledCode"].string {
                    bluetoothManager.writeJavascript(compiledCode) { result in completion(result) }
                } else {
                    completion(.failure(ManagerError("Failed to load script, unknown error occurred.")))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    } else {
        Alamofire.request(url)
            .validate()
            .responseJSON { response in
            // Handle response appropriately
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                if let errors = json["serverErrors"].array, let error = errors.first?["error"].string {
                    completion(.failure(ManagerError("Failed to load script, \(error).")))
                } else if let compiledCode = json["compiledCode"].string {
                    bluetoothManager.writeJavascript(compiledCode) { result in completion(result) }
                } else {
                    completion(.failure(ManagerError("Failed to load script, unknown error occurred.")))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
