//
//  DataPoint+CoreDataProperties.swift
//  QoE_companion
//
//  Created by David Atwood on 1/4/22.
//
//

import Foundation
import CoreData


extension DataPoint {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DataPoint> {
        return NSFetchRequest<DataPoint>(entityName: "DataPoint")
    }

    @NSManaged public var accX: Double
    @NSManaged public var accY: Double
    @NSManaged public var accZ: Double
    @NSManaged public var gyroX: Double
    @NSManaged public var gyroY: Double
    @NSManaged public var gyroZ: Double
    @NSManaged public var heartRate: Int16
    @NSManaged public var timestamp: Double
    @NSManaged public var sensordata: SensorData?

}

extension DataPoint : Identifiable {

}
