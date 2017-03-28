//
//  Constants.swift
//  SwiftMomentSDK
//
//  Created by Jacob Rockland on 2/22/17.
//  Copyright © 2017 Somatic Technologies, Inc. All rights reserved.
//

import CoreBluetooth
import Alamofire

// MARK: - Application Constants

/**
 Important constants for the Moment application
 */
internal struct Constants {
    
    // MARK: - Device Name Constants
    
    /// `String`s representing name used to recognize the Moment device
    static let deviceName = "Moment"
    
    // MARK: - Bluetooth Constants
    
    /// Maximum amount of time, in seconds, to allow the phone to scan for Moment
    static let scanTimeout = 5.0
    
    /// Maximum amount of time, in seconds, to allow phone to attempt connection to Moment
    static let connectTimeout = 1.5
    
    // MARK: - Web Constants
    
    /// Web address for the Somatic Labs Javascript compiler API
    static let javascriptCompilerURL = URL(string: "https://firmware-staging.wearmoment.com/compile")!
    
    // MARK: - Misc. Constants
    
    /// Web address for learning more about Moment
    static let aboutMomentURL = URL(string: "https://wearmoment.com/")!
    
}
