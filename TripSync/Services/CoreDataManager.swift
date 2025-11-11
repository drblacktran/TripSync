//
//  CoreDataManager.swift
//  TripSync
//
//  Created by Tien Tran on 14/9/2025.
//

import CoreData
import UIKit

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "TripSync")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func save() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            print("🔄 [CORE DATA] Starting save operation...")
            print("📊 [CORE DATA] Context has \(context.insertedObjects.count) inserted objects")
            print("📊 [CORE DATA] Context has \(context.updatedObjects.count) updated objects")
            print("📊 [CORE DATA] Context has \(context.deletedObjects.count) deleted objects")

            // Log inserted objects
            for object in context.insertedObjects {
                let entityName = object.entity.name ?? "Unknown"
                if let trip = object as? TripEntity {
                    print("➕ [CORE DATA] Inserting TripEntity: \(trip.title ?? "Untitled") (id: \(trip.id ?? "nil"))")
                } else if let profile = object as? UserProfileEntity {
                    print("➕ [CORE DATA] Inserting UserProfileEntity: \(profile.firstName ?? "") \(profile.lastName ?? "") (id: \(profile.id ?? "nil"))")
                } else if let travel = object as? TravelPreferencesEntity {
                    print("➕ [CORE DATA] Inserting TravelPreferencesEntity: defaultTripLength=\(travel.defaultTripLength) (id: \(travel.id ?? "nil"))")
                } else if let notification = object as? NotificationSettingsEntity {
                    print("➕ [CORE DATA] Inserting NotificationSettingsEntity: pushNotifications=\(notification.pushNotifications) (id: \(notification.id ?? "nil"))")
                } else if let privacy = object as? PrivacySettingsEntity {
                    print("➕ [CORE DATA] Inserting PrivacySettingsEntity: shareLocation=\(privacy.shareLocationData) (id: \(privacy.id ?? "nil"))")
                } else {
                    print("➕ [CORE DATA] Inserting \(entityName)")
                }
            }

            // Log updated objects
            for object in context.updatedObjects {
                let entityName = object.entity.name ?? "Unknown"
                if let trip = object as? TripEntity {
                    print("📝 [CORE DATA] Updating TripEntity: \(trip.title ?? "Untitled") (id: \(trip.id ?? "nil"))")
                } else if let profile = object as? UserProfileEntity {
                    print("📝 [CORE DATA] Updating UserProfileEntity: \(profile.firstName ?? "") \(profile.lastName ?? "")")
                    print("   - Home country: \(profile.homeCountry ?? "nil")")
                    print("   - Currency: \(profile.homeCurrency ?? "nil")")
                    print("   - Units: \(profile.preferredUnits ?? "nil")")
                } else {
                    print("📝 [CORE DATA] Updating \(entityName)")
                }
            }

            // Log deleted objects
            for object in context.deletedObjects {
                let entityName = object.entity.name ?? "Unknown"
                print("🗑️ [CORE DATA] Deleting \(entityName)")
            }

            do {
                try context.save()
                print("✅ [CORE DATA] Save operation completed successfully")
            } catch {
                let nserror = error as NSError
                print("❌ [CORE DATA] Save failed: \(nserror.localizedDescription)")
                print("❌ [CORE DATA] Error details: \(nserror.userInfo)")
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        } else {
            print("ℹ️ [CORE DATA] No changes to save")
        }
    }

    // MARK: - Trip Operations
    func fetchTrips() -> [TripEntity] {
        let request: NSFetchRequest<TripEntity> = TripEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching trips: \(error)")
            return []
        }
    }

    func createTrip(from trip: Trip) -> TripEntity? {
        print("🏗️ [CORE DATA] Creating new TripEntity from Trip model")
        print("   - Title: \(trip.title)")
        print("   - Destination: \(trip.targetCountries.joined(separator: ", "))")
        print("   - Dates: \(trip.startDate.formatted()) to \(trip.endDate.formatted())")
        print("   - Budget: \(trip.totalBudget?.formatted() ?? "Not set")")

        let tripEntity = TripEntity(context: context)
        updateTripEntity(tripEntity, from: trip)
        save()
        return tripEntity
    }

    func updateTripEntity(_ entity: TripEntity, from trip: Trip) {
        entity.id = trip.id
        entity.title = trip.title
        entity.startDate = trip.startDate
        entity.endDate = trip.endDate
        entity.createdDate = trip.createdDate
        entity.lastModified = trip.lastModified
        entity.homeCountry = trip.homeCountry
        entity.targetCountries = trip.targetCountries
        entity.isInternational = trip.isInternational
        entity.baseCurrency = trip.baseCurrency
        entity.totalBudget = trip.totalBudget ?? 0
        entity.actualSpent = trip.actualSpent
        entity.primaryTransportMode = trip.primaryTransportMode.rawValue
        entity.hasFlightDetails = trip.hasFlightDetails
        entity.flightPromptDismissed = trip.flightPromptDismissed
        entity.isShared = trip.isShared
        entity.collaborators = trip.collaborators
        entity.tags = trip.tags
        
        // Save daily schedules and activities
        print("📅 [CORE DATA] Saving \(trip.dailySchedules.count) daily schedules")
        
        // Remove existing schedules
        if let existingSchedules = entity.dailySchedules as? Set<DailyScheduleEntity> {
            for schedule in existingSchedules {
                context.delete(schedule)
            }
        }
        
        // Create new schedules
        for schedule in trip.dailySchedules {
            let scheduleEntity = DailyScheduleEntity(context: context)
            scheduleEntity.id = UUID().uuidString
            scheduleEntity.date = schedule.date
            scheduleEntity.trip = entity
            
            print("   📆 Day: \(schedule.date.formatted(date: .abbreviated, time: .omitted)) - \(schedule.plannedActivities.count) activities")
            
            // Create activities for this schedule
            for activity in schedule.plannedActivities {
                let activityEntity = ScheduledActivityEntity(context: context)
                activityEntity.id = UUID().uuidString
                activityEntity.title = activity.title
                activityEntity.startTime = activity.startTime
                activityEntity.endTime = activity.endTime
                activityEntity.notes = activity.notes
                activityEntity.schedule = scheduleEntity
                
                // Try to link to POI if we have a poiId
                if let poiId = activity.poiId {
                    // Find POI entity by ID (if it exists in the database)
                    let poiFetchRequest: NSFetchRequest<PointOfInterestEntity> = PointOfInterestEntity.fetchRequest()
                    poiFetchRequest.predicate = NSPredicate(format: "id == %@", poiId)
                    poiFetchRequest.fetchLimit = 1
                    
                    if let poiEntity = try? context.fetch(poiFetchRequest).first {
                        activityEntity.pointOfInterest = poiEntity
                        print("      🔗 Linked to POI: \(poiEntity.name ?? "Unknown")")
                    }
                }
                
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "h:mm a"
                print("      🎯 \(activity.title): \(timeFormatter.string(from: activity.startTime)) - \(timeFormatter.string(from: activity.endTime))")
            }
        }
    }

    // MARK: - User Profile Operations
    func fetchUserProfile(for userId: String) -> UserProfileEntity? {
        let request: NSFetchRequest<UserProfileEntity> = UserProfileEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", userId)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching user profile: \(error)")
            return nil
        }
    }

    func createUserProfile(from profile: UserProfile) -> UserProfileEntity? {
        print("👤 [CORE DATA] Creating new UserProfileEntity from UserProfile model")
        print("   - Name: \(profile.fullName)")
        print("   - Email: \(profile.email)")
        print("   - Home Country: \(profile.homeCountry)")
        print("   - Currency: \(profile.homeCurrency)")
        print("   - Units: \(profile.preferredUnits.rawValue)")
        print("   - Language: \(profile.languageCode)")

        let profileEntity = UserProfileEntity(context: context)
        updateUserProfileEntity(profileEntity, from: profile)
        save()
        return profileEntity
    }

    func updateUserProfileEntity(_ entity: UserProfileEntity, from profile: UserProfile) {
        entity.id = profile.id
        entity.firstName = profile.firstName
        entity.lastName = profile.lastName
        entity.email = profile.email
        entity.profileImageURL = profile.profileImageURL
        entity.homeCountry = profile.homeCountry
        entity.homeCurrency = profile.homeCurrency
        entity.preferredUnits = profile.preferredUnits.rawValue
        entity.languageCode = profile.languageCode
        entity.timeZone = profile.timeZone
        entity.dateJoined = profile.dateJoined
        entity.lastUpdated = profile.lastUpdated

        // Update related settings entities
        updateTravelPreferences(for: entity, from: profile.travelPreferences)
        updateNotificationSettings(for: entity, from: profile.notificationSettings)
        updatePrivacySettings(for: entity, from: profile.privacySettings)
    }

    private func updateTravelPreferences(for profile: UserProfileEntity, from preferences: TravelPreferences) {
        print("🧳 [CORE DATA] Updating TravelPreferencesEntity:")
        print("   - Default trip length: \(preferences.defaultTripLength) days")
        print("   - Transport mode: \(preferences.preferredTransportMode.rawValue)")
        print("   - Budget range: \(preferences.budgetRange.rawValue)")
        print("   - Accommodation: \(preferences.accommodationType.rawValue)")
        print("   - Activity preferences: \(preferences.activityPreferences.map { $0.rawValue })")

        let entity = profile.travelPreferences ?? TravelPreferencesEntity(context: context)
        entity.id = UUID().uuidString
        entity.defaultTripLength = Int32(preferences.defaultTripLength)
        entity.preferredTransportMode = preferences.preferredTransportMode.rawValue
        entity.budgetRange = preferences.budgetRange.rawValue
        entity.accommodationType = preferences.accommodationType.rawValue
        entity.activityPreferences = preferences.activityPreferences.map { $0.rawValue }
        entity.dietaryRestrictions = preferences.dietaryRestrictions
        entity.accessibilityNeeds = preferences.accessibilityNeeds
        entity.userProfile = profile
        profile.travelPreferences = entity
    }

    private func updateNotificationSettings(for profile: UserProfileEntity, from settings: NotificationSettings) {
        print("🔔 [CORE DATA] Updating NotificationSettingsEntity:")
        print("   - Push notifications: \(settings.pushNotifications)")
        print("   - Email notifications: \(settings.emailNotifications)")
        print("   - Trip reminders: \(settings.tripReminders)")
        print("   - Flight updates: \(settings.flightUpdates)")
        print("   - Budget alerts: \(settings.budgetAlerts)")
        print("   - Reminder days before: \(settings.reminderDaysBefore)")

        let entity = profile.notificationSettings ?? NotificationSettingsEntity(context: context)
        entity.id = UUID().uuidString
        entity.pushNotifications = settings.pushNotifications
        entity.emailNotifications = settings.emailNotifications
        entity.tripReminders = settings.tripReminders
        entity.flightUpdates = settings.flightUpdates
        entity.documentReminders = settings.documentReminders
        entity.budgetAlerts = settings.budgetAlerts
        entity.reminderDaysBefore = Int32(settings.reminderDaysBefore)
        entity.userProfile = profile
        profile.notificationSettings = entity
    }

    private func updatePrivacySettings(for profile: UserProfileEntity, from settings: PrivacySettings) {
        print("🔒 [CORE DATA] Updating PrivacySettingsEntity:")
        print("   - Share trips with contacts: \(settings.shareTripsWithContacts)")
        print("   - Allow trip discovery: \(settings.allowTripDiscovery)")
        print("   - Share location data: \(settings.shareLocationData)")
        print("   - Analytics opt-in: \(settings.analyticsOptIn)")
        print("   - Marketing emails: \(settings.marketingEmails)")

        let entity = profile.privacySettings ?? PrivacySettingsEntity(context: context)
        entity.id = UUID().uuidString
        entity.shareTripsWithContacts = settings.shareTripsWithContacts
        entity.allowTripDiscovery = settings.allowTripDiscovery
        entity.shareLocationData = settings.shareLocationData
        entity.analyticsOptIn = settings.analyticsOptIn
        entity.marketingEmails = settings.marketingEmails
        entity.userProfile = profile
        profile.privacySettings = entity
    }

    // MARK: - Delete Operations
    func deleteTrip(_ tripEntity: TripEntity) {
        print("🗑️ [CORE DATA] Deleting TripEntity: \(tripEntity.title ?? "Untitled") (id: \(tripEntity.id ?? "nil"))")
        context.delete(tripEntity)
        save()
    }

    func deleteUserProfile(_ profileEntity: UserProfileEntity) {
        print("🗑️ [CORE DATA] Deleting UserProfileEntity: \(profileEntity.firstName ?? "") \(profileEntity.lastName ?? "") (id: \(profileEntity.id ?? "nil"))")
        context.delete(profileEntity)
        save()
    }
}