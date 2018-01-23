//
//  Constants.swift
//  SwiftyZorb
//
//  Created by Jacob Rockland on 2/22/17.
//  Copyright © 2017 Somatic Technologies, Inc. All rights reserved.
//

import CoreBluetooth
import Alamofire

// MARK: - Application Constants

/**
 Important constants for the Zorb application
 */
internal struct Constants {
    
    // MARK: - Device Name Constants
    
    /// `String`s representing name used to recognize a Zorb device
    static let deviceName = "Moment"
    
    // MARK: - Bluetooth Constants
    
    /// Maximum amount of time, in seconds, to allow the phone to scan for Zorb device
    static let scanTimeout = 5.0
    
    /// Maximum amount of time, in seconds, to allow phone to attempt connection to Zorb device
    static let connectTimeout = 3.0
    
    // MARK: - Web Constants
    
    /// Web address for the Somatic Labs Javascript compiler API
    static let javascriptCompilerURL = URL(string: "https://firmware.wearmoment.com/compile")!
}
