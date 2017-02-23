//
//  Moment.swift
//  MomentSDK
//
//  Created by Jacob Rockland on 2/22/17.
//  Copyright © 2017 Somatic Technologies, Inc. All rights reserved.
//

import SwiftyBluetooth
import Alamofire

/**
 For interacting with Moment device
 */
final public class Moment {
    
    // MARK: Public Bluetooth Methods
    
    /**
     Initiates a connection to an advertising Moment device
     */
    func connect(completion: @escaping ConnectPeripheralCallback) {
        bluetoothManager.connect { result in completion(result) }
    }
    
    /**
     Writes a given string of Javascript to the connected Moment device
     
     - Parameter javascript: The Javascript code to be written

     - Parameter optimize: Boolean flag for whether or not the input Javascript should be optimized by the Google closure compiler. Default value is set to `true`, which is the recommended setting for best Bluetooth transfer speed, but can be set to false if alternative behavior is needed (one needs to avoid the extra HTTP request).
    */
    func write(with javascript: String, optimize: Bool = true, completion: @escaping WriteRequestCallback) {
        // If optimization flag is set to true, run the Javascript through the Google closure compiler
        if optimize {
            let params: Parameters = [
                "js_code": javascript,
                "compilation_level": "SIMPLE_OPTIMIZATIONS",
                "output_format": "text",
                "output_info": "compiled_code"
            ]
            Alamofire.request(Constants.closureCompilerURL, method: .post, parameters: params, headers: Constants.closureCompilerHeaders).validate().responseString { response in
                // Handle response appropriately
                switch response.result {
                case .success(let value):
                    bluetoothManager.writeJavascript(value) { result in completion(result) }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            bluetoothManager.writeJavascript(javascript) { result in completion(result) }
        }
    }
    
    /**
     Writes the Javascript code at a given URL to the connected Moment device
     
     - Parameter script: A URL to the hosted Javascript script to be written
     
     - Parameter optimize: Boolean flag for whether or not the input Javascript should be optimized by the Google closure compiler. Default value is set to `true`, which is the recommended setting for best Bluetooth transfer speed, but can be set to false if alternative behavior is needed (one needs to avoid the extra HTTP request).
     */
    func write(with script: URL, optimize: Bool = true, completion: @escaping WriteRequestCallback) {
        // Format the script URL to retrieve the raw text version
        let url = script.appendingPathComponent("raw")
        
        // If optimization flag is set to true, run the Javascript through the Google closure compiler
        if optimize {
            let params: Parameters = [
                "code_url": url.absoluteString,
                "compilation_level": "SIMPLE_OPTIMIZATIONS",
                "output_format": "text",
                "output_info": "compiled_code"
            ]
            Alamofire.request(Constants.closureCompilerURL, method: .post, parameters: params, headers: Constants.closureCompilerHeaders).validate().responseString { response in
                // Handle response appropriately
                switch response.result {
                case .success(let value):
                    bluetoothManager.writeJavascript(value) { result in completion(result) }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            Alamofire.request(url).validate().responseString { response in
                // Handle response appropriately
                switch response.result {
                case .success(let value):
                    bluetoothManager.writeJavascript(value) { result in completion(result) }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
}

