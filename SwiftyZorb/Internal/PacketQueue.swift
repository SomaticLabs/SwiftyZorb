//
//  PacketQueue.swift
//  SwiftyZorb
//
//  Created by Jacob Rockland on 12/22/17.
//  Copyright © 2017 Somatic Technologies, Inc. All rights reserved.
//

import Foundation

// MARK: - Packet Queue

/**
 A simple FIFO (first in, first out) queue for managing data to be written to the Javascript BLE characteristic (thread safe)
 */
final internal class PacketQueue {
    
    // MARK: - Private Properties
    
    /// Internal array for managing queue
    private var array = [ArraySlice<UInt8>]()
    
    /// Internal access queue for managing packet queue
    private let accessQueue = DispatchQueue(label: "SynchronizedArrayAccess", attributes: .concurrent)
    
    // MARK: - Accessible Properties
    
    /// Variable for counting the number of packet sets queued
    var numSets = 0
    
    /// Variable for getting count in queue
    var count: Int {
        var count = 0
        
        accessQueue.sync {
            count = self.array.count
        }
        
        return count
    }
    
    /// Variable for checking if the queue is empty
    var isEmpty: Bool {
        var isEmpty = true
        
        accessQueue.sync {
            isEmpty = self.array.isEmpty
        }
        
        return isEmpty
    }
    
    // MARK: - Queue Methods
    
    /// Method for adding item to the queue
    func enqueue(_ element: ArraySlice<UInt8>) {
        accessQueue.async(flags:.barrier) {
            self.array.append(element)
        }
    }
    
    /// Method for removing item from the queue
    func dequeue() -> ArraySlice<UInt8>? {
        var element: ArraySlice<UInt8>? = nil
        
        accessQueue.sync {
            element = self.array.first
        }
        
        accessQueue.async(flags:.barrier) {
            self.array.removeFirst()
        }
        
        return element
    }
}
