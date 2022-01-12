//
//  SensorData+CoreDataProperties.swift
//  QoE_companion
//
//  Created by David Atwood on 1/4/22.
//
//

import Foundation
import CoreData


extension SensorData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SensorData> {
        return NSFetchRequest<SensorData>(entityName: "SensorData")
    }

    @NSManaged public var duration: Int16
    @NSManaged public var id: Int16
    @NSManaged public var time: Date?
    @NSManaged public var selected: Bool
    @NSManaged public var datapoints: NSOrderedSet?

}

// MARK: Generated accessors for datapoints
extension SensorData {

    @objc(insertObject:inDatapointsAtIndex:)
    @NSManaged public func insertIntoDatapoints(_ value: DataPoint, at idx: Int)

    @objc(removeObjectFromDatapointsAtIndex:)
    @NSManaged public func removeFromDatapoints(at idx: Int)

    @objc(insertDatapoints:atIndexes:)
    @NSManaged public func insertIntoDatapoints(_ values: [DataPoint], at indexes: NSIndexSet)

    @objc(removeDatapointsAtIndexes:)
    @NSManaged public func removeFromDatapoints(at indexes: NSIndexSet)

    @objc(replaceObjectInDatapointsAtIndex:withObject:)
    @NSManaged public func replaceDatapoints(at idx: Int, with value: DataPoint)

    @objc(replaceDatapointsAtIndexes:withDatapoints:)
    @NSManaged public func replaceDatapoints(at indexes: NSIndexSet, with values: [DataPoint])

    @objc(addDatapointsObject:)
    @NSManaged public func addToDatapoints(_ value: DataPoint)

    @objc(removeDatapointsObject:)
    @NSManaged public func removeFromDatapoints(_ value: DataPoint)

    @objc(addDatapoints:)
    @NSManaged public func addToDatapoints(_ values: NSOrderedSet)

    @objc(removeDatapoints:)
    @NSManaged public func removeFromDatapoints(_ values: NSOrderedSet)

}

extension SensorData : Identifiable {

}
