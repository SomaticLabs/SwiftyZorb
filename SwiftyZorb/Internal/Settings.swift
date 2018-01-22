//
//  Settings.swift
//  SwiftyZorb
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
     Gets the stored peripheral `UUID` from UserDefaults
     
     - Returns: `UUID` object associated with last peripheral that was previously discovered
     */
    static func getZorbPeripheral() -> UUID? {
        guard let uuidString = UserDefaults.standard.string(forKey: "zorb-peripheral") else {
            return nil
        }
        return UUID(uuidString: uuidString)
    }
    
    /**
     Resets stored peripheral to `nil`
     */
    static func resetZorbPeripheral() {
        UserDefaults.standard.set(nil, forKey: "zorb-peripheral")
        UserDefaults.standard.synchronize()
    }
    
    /**
     Stores a given `UUID` to store a peripheral
     
     - Parameter identifier: `UUID` associated with a peripheral
     */
    static func saveZorbPeripheral(with identifier: UUID) {
        UserDefaults.standard.set(identifier.uuidString, forKey: "zorb-peripheral")
        UserDefaults.standard.synchronize()
    }

}
