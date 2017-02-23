//
//  Settings.swift
//  MomentSDK
//
//  Created by Jacob Rockland on 2/22/17.
//  Copyright © 2017 Somatic Technologies, Inc. All rights reserved.
//

import CoreBluetooth

// MARK: - Settings Class

/**
 For storing and retrieving settings from UserDefaults
 */
final internal class Settings: NSObject {

    // MARK: - Peripheral Settings
    
    /**
     Gets the stored Moment peripheral `UUID` from UserDefaults
     
     - Returns: `UUID` object associated with last Moment peripheral that was previously discovered
     */
    static func getMomentPeripheral() -> UUID? {
        guard let uuidString = UserDefaults.standard.string(forKey: "moment-peripheral") else {
            return nil
        }
        return UUID(uuidString: uuidString)
    }
    
    /**
     Resets stored Moment peripheral to `nil`
     */
    static func resetMomentPeripheral() {
        UserDefaults.standard.set(nil, forKey: "moment-peripheral")
        UserDefaults.standard.synchronize()
    }
    
    /**
     Stores a given `UUID` to store a Moment peripheral
     
     - Parameter identifier: `UUID` associated with a Moment peripheral
     */
    static func saveMomentPeripheral(with identifier: UUID) {
        UserDefaults.standard.set(identifier.uuidString, forKey: "moment-peripheral")
        UserDefaults.standard.synchronize()
    }

}
