//
//  DeviceSettings.swift
//  SwiftMomentSDK
//
//  Created by Jacob Rockland on 12/22/17.
//  Copyright © 2017 Somatic Technologies, Inc. All rights reserved.
//

import Foundation

// MARK: - Device Settings Enumerations

/**
 Enumeration of left and right, used for keeping track of wrist and button orientation - conforms to `UInt8` type
 */
public enum Orientation: UInt8 {
    /// Left orientation, represented as `UInt8` of `0`
    case left = 0
    
    /// Right orientation, represented as `UInt8` of `1`
    case right = 1
}

/**
 Enumeration of low, medium and high, used for keeping track of device intensity level - conforms to `UInt8` type
 */
public enum Intensity: UInt8 {
    /// Low intensity, represented as `UInt8` of `0`
    case low = 0
    
    /// Medium intensity, represented as `UInt8` of `1`
    case medium = 1
    
    /// High intensity, represented as `UInt8` of `2`
    case high = 2
}
