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
    
    /// Arrays of `CBUUID`s representing all services that Zorb device should advertise
    static let AdvertisedServices_V1 = [CBUUID]() // FIXME: Eventually replace with [HapticTimelineServiceUUID_V1]
    static let AdvertisedServices_V2 = [CBUUID]() // FIXME: Eventually replace with [HapticTimelineServiceUUID_V2]
    
    /// `CBUUID`s that advertises the haptic timeline service
    static let HapticTimelineServiceUUID_V1 = CBUUID(string: "A28E9217-E9B5-4C0A-9217-1C64D051D762")
    static let HapticTimelineServiceUUID_V2 = CBUUID(string: "D6E59217-D763-47FA-A092-C24EE6DF29D3")
    
    /// `CBUUID`s that advertises the setttings characteristic
    static let SettingsCharacteristicUUID_V1 = CBUUID(string: "A28EFC07-E9B5-4C0A-9217-1C64D051D762")
    static let SettingsCharacteristicUUID_V2 = CBUUID(string: "D6E5FC07-D763-47FA-A092-C24EE6DF29D3")
    
    /// `CBUUID` for identifying the basic actuator control characteristic
    static let ActuatorCharacteristicUUID_V1 = CBUUID(string: "A28EFC05-E9B5-4C0A-9217-1C64D051D762")
    static let ActuatorCharacteristicUUID_V2 = CBUUID(string: "D6E5FC05-D763-47FA-A092-C24EE6DF29D3")
    
    /// `CBUUID` for identifying the pattern trigger characteristic
    static let PatternTriggerCharacteristicUUID_V1 = CBUUID(string: "A28EFC08-E9B5-4C0A-9217-1C64D051D762")
    static let PatternTriggerCharacteristicUUID_V2 = CBUUID(string: "D6E5FC08-D763-47FA-A092-C24EE6DF29D3")
    
    /// `CBUUID` for identifying the Nordic UART service
    static let NordicUARTServiceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    
    /// `CBUUID` for identifying the Nordic UART TX characteristic
    static let NordicUARTTXCharacteristicUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    
    /// `CBUUID` for identifying the Nordic UART RX characteristic
    static let NordicUARTRXCharacteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    
}
