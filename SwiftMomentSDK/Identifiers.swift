//
//  Identifiers.swift
//  SwiftMomentSDK
//
//  Created by Jacob Rockland on 2/22/17.
//  Copyright © 2017 Somatic Technologies, Inc. All rights reserved.
//

import CoreBluetooth

// MARK: - Identifier Constants

/**
 Constants for identifying the haptic timeline service and its characteristics
 */
internal struct Identifiers {
    
    // MARK: - Moment Bluetooth Service UUIDs
    
    /// Array of `CBUUID`s representing all services that Moment should advertise
    static let AdvertisedServices = [HapticTimelineServiceUUID]
    
    /// `CBUUID` that advertises the haptic timeline service
    static let HapticTimelineServiceUUID = CBUUID(string: "A28E9B69-E9B5-4C0A-9217-1C64D051D762")
    
    /// `CBUUID` for identifying the Nordic UART service
    static let NordicUARTServiceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    
    /// `CBUUID` for identifying the Nordic UART TX characteristic
    static let NordicUARTTXCharacteristicUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    
    /// `CBUUID` for identifying the Nordic UART RX characteristic
    static let NordicUARTRXCharacteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    
}
