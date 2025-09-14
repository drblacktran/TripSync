//
//  Trip.swift
//  TripSync
//
//  Created by Tien Tran on 14/9/2025.
//

import Foundation
import CoreData

@objc(Trip)
public class Trip: NSManagedObject {
    
}

extension Trip {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Trip> {
        return NSFetchRequest<Trip>(entityName: "Trip")
    }

    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var destination: String
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date
    @NSManaged public var createdDate: Date
    @NSManaged public var isShared: Bool
    @NSManaged public var participants: NSSet?
    @NSManaged public var activities: NSSet?
}

// MARK: Generated accessors for participants
extension Trip {
    @objc(addParticipantsObject:)
    @NSManaged public func addToParticipants(_ value: Participant)

    @objc(removeParticipantsObject:)
    @NSManaged public func removeFromParticipants(_ value: Participant)

    @objc(addParticipants:)
    @NSManaged public func addToParticipants(_ values: NSSet)

    @objc(removeParticipants:)
    @NSManaged public func removeFromParticipants(_ values: NSSet)
}

// MARK: Generated accessors for activities
extension Trip {
    @objc(addActivitiesObject:)
    @NSManaged public func addToActivities(_ value: Activity)

    @objc(removeActivitiesObject:)
    @NSManaged public func removeFromActivities(_ value: Activity)

    @objc(addActivities:)
    @NSManaged public func addToActivities(_ values: NSSet)

    @objc(removeActivities:)
    @NSManaged public func removeFromActivities(_ values: NSSet)
}