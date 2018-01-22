//
//  ManagerError.swift
//  SwiftyZorb
//
//  Created by Jacob Rockland on 12/22/17.
//  Copyright © 2017 Somatic Technologies, Inc. All rights reserved.
//

import Foundation

// MARK: - Manager Error Enumeration

/**
 Error type for generating custom errors
 */
final internal class ManagerError: NSError {
    
    /**
     Error initializer, sets localized description to `String` passed in
     */
    init(_ localizedDescription: String) {
        super.init(domain: "com.SomaticLabs.SwiftyZorb", code: 404, userInfo: [NSLocalizedDescriptionKey: localizedDescription])
    }
    
    /**
     Required coder initializer
     */
    required init?(coder aDecoder: NSCoder) {
        // Calls super
        super.init(coder: aDecoder)
    }
    
}
