//
//  SensorOutput.swift
//  QoE_companion
//
//  Created by David Atwood on 10/28/21.
//

import Foundation

class SensorOutput: Codable {
    
    var timeStamp: Double?
    
    var accX: Double?
    var accY: Double?
    var accZ: Double?
    
    var gyroX: Double?
    var gyroY: Double?
    var gyroZ: Double?
    
    var heartRate: Int16?
    
    var bloodOx: Double?
    
    init() {}
}
