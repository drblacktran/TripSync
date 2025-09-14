//
//  Participant.swift
//  TripSync
//
//  Created by Tien Tran on 14/9/2025.
//

import Foundation
import CoreData

@objc(Participant)
public class Participant: NSManagedObject {
    
}

extension Participant {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Participant> {
        return NSFetchRequest<Participant>(entityName: "Participant")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var email: String
    @NSManaged public var avatarURL: String?
    @NSManaged public var isOwner: Bool
    @NSManaged public var joinedDate: Date
    @NSManaged public var trip: Trip?
}