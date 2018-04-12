//
//  Identifiers.swift
//  SwiftyZorb
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
    
    // MARK: - General Bluetooth Service UUIDs
    
    /// `CBUUID` for identifying the standard device information service
    static let DeviceInformationServiceUUID = CBUUID(string: "180A")
    
    /// `CBUUID` for identifying the firmware revision string characteristic
    static let FirmwareRevisionStringCharacteristicUUID = CBUUID(string: "2A26")
    
    /// `CBUUID` for identifying the serial number string characteristic
    static let SerialNumberStringCharacteristicUUID = CBUUID(string: "2A25")
    
    // MARK: - Zorb Specific Bluetooth Service UUIDs
    
    /// Array of `CBUUID`s representing all services that Zorb device should advertise
    static let AdvertisedServices = [HapticTimelineServiceUUID]
    
    /// `CBUUID` that advertises the haptic timeline service
    static let HapticTimelineServiceUUID = CBUUID(string: "A28E9217-E9B5-4C0A-9217-1C64D051D762")
    
    /// `CBUUID` that advertises the setttings characteristic
    static let SettingsCharacteristicUUID = CBUUID(string: "A28EFC07-E9B5-4C0A-9217-1C64D051D762")
    
    /// `CBUUID` for identifying the basic actuator control characteristic
    static let ActuatorCharacteristicUUID = CBUUID(string: "A28EFC05-E9B5-4C0A-9217-1C64D051D762")
    
    /// `CBUUID` for identifying the pattern trigger characteristic
    static let PatternTriggerCharacteristicUUID = CBUUID(string: "A28EFC08-E9B5-4C0A-9217-1C64D051D762")
    
    /// `CBUUID` for identifying the Nordic UART service
    static let NordicUARTServiceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    
    /// `CBUUID` for identifying the Nordic UART TX characteristic
    static let NordicUARTTXCharacteristicUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    
    /// `CBUUID` for identifying the Nordic UART RX characteristic
    static let NordicUARTRXCharacteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    
}
