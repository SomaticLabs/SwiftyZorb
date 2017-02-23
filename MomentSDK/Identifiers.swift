//
//  Identifiers.swift
//  MomentSDK
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
    static let HapticTimelineServiceUUID = CBUUID(string: "00009B69-58FD-0A19-9B69-4CF88FC7B8DA")
    
    /// `CBUUID` for identifying the Nordic UART service
    static let NordicUARTServiceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    
    /// `CBUUID` for identifying the Nordic UART TX characteristic
    static let NordicUARTTXCharacteristicUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    
    /// `CBUUID` for identifying the Nordic UART RX characteristic
    static let NordicUARTRXCharacteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    
    // MARK: - Dummy Reserved UUID
    
    /// `CBUUID` to be passed when reseting manager state and data
    static let DummyUUID = CBUUID(string: "D7DBB824-D8A5-4655-BE50-7026B3FE7705")
    
}
