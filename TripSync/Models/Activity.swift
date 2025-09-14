//
//  Activity.swift
//  TripSync
//
//  Created by Tien Tran on 14/9/2025.
//

import Foundation
import CoreData

@objc(Activity)
public class Activity: NSManagedObject {
    
}

extension Activity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Activity> {
        return NSFetchRequest<Activity>(entityName: "Activity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var desc: String?
    @NSManaged public var location: String?
    @NSManaged public var scheduledDate: Date?
    @NSManaged public var createdDate: Date
    @NSManaged public var isCompleted: Bool
    @NSManaged public var trip: Trip?
}