//
//  CBManagerStateExtension.swift
//  MomentSDK
//
//  Created by Jacob Rockland on 2/22/17.
//  Copyright © 2017 Somatic Technologies, Inc. All rights reserved.
//

import CoreBluetooth

// MARK: - CBManagerState Extension

/**
 Extension of `CBManagerState` to add a description variable
 */
@available(iOS 10.0, *)
extension CBManagerState {
    /// `String` representation of state
    var description: String {
        switch self {
        case .poweredOn: return "Powered On"
        case .poweredOff: return "Powered Off"
        case .resetting: return "Resetting"
        case .unauthorized: return "Unauthorized"
        case .unknown: return "Unknown"
        case .unsupported: return "Unsuported"
        }
    }
}
