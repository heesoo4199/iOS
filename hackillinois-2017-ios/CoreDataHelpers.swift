//
//  CoreDataHelpers.swift
//  hackillinois-2017-ios
//
//  Created by Shotaro Ikeda on 5/27/16.
//  Copyright © 2016 Shotaro Ikeda. All rights reserved.
//

/* This file contains helper functions for CoreData operations */
import CoreData
import UIKit

/* Provide namespace for helpers */
class CoreDataHelpers {
    /* Mark - Helper functions to find location, tag, and create feeds */
    
    /* 
     * Helper function to find or create location 
     * Finds the location entity if it exists, otherwise returns a new entity representing a location object
     */
    class func createOrFetchLocation(location locationName: String, abbreviation shortName: String, locationLatitude latitude: NSNumber, locationLongitude longitude: NSNumber, address: String, locationFeeds feeds: [Feed]?) -> Location {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let fetchRequest = NSFetchRequest<Location>(entityName: "Location")
        fetchRequest.predicate = NSPredicate(format: "name == %@", locationName)
        
        if let locations = try? appDelegate.managedObjectContext.fetch(fetchRequest) {
            if locations.count > 0 {
                return locations[0]
            }
        }
        
        /* Was not found */
        let location = NSEntityDescription.insertNewObject(forEntityName: "Location", into: appDelegate.managedObjectContext) as! Location
        if feeds == nil {
            location.initialize(latitude: latitude, longitude: longitude, name: locationName, shortName: shortName, address: address, feeds: [])
        } else {
            location.initialize(latitude: latitude, longitude: longitude, name: locationName, shortName: shortName, address: address, feeds: feeds!)
        }
        
        return location
    }
    
    /* 
     * Helper function to find or create a tag
     * Finds the tag entity if it exists, otherwise returns a new entity representing a location object
     */
    class func createOrFetchTag(tag tagName: String, feeds: [Feed]?) -> Tag {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let fetchRequest = NSFetchRequest<Tag>(entityName: "Tag")
        fetchRequest.predicate = NSPredicate(format: "name == %@", tagName)
        
        if let tags = try? appDelegate.managedObjectContext.fetch(fetchRequest) {
            if tags.count > 0 {
                return tags[0]
            }
        }
        
        /* Was not found */
        let tag = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: appDelegate.managedObjectContext) as! Tag
        
        if feeds == nil {
            tag.initialize(name: tagName, feeds: NSSet())
        } else {
            tag.initialize(name: tagName, feeds: feeds!)
        }
        
        return tag
    }
    
    /* 
     * Helper function to create a feed
     * Finds a feed entity if it exists, otherwise returns a new entity representing a feed object
     * The database's Merge Policy is set to overwrite, so passing in the same id will overwrite the existing entry.
     * 
     * If there are valid locations and tags passed in, this will also add the object to each of the inverse relationships
     * Thus it is recommended to create the tags+locations before passing it in as arguments.
     *
     * locations and tags seems required, you can insert an empty array/list if it doesn't exist (done in order to have the
     * user have to make an intention not to have any locations or tags
     */
    class func createOrFetchFeed(id: NSNumber, message: String, timestamp: UInt64, locations: [Location], tags: [Tag]) -> Feed {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let fetchRequest = NSFetchRequest<Feed>(entityName: "Feed")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        
        if let feed = try? appDelegate.managedObjectContext.fetch(fetchRequest) {
            if feed.count > 0 {
                return feed[0]
            }
        }
        
        let feed = NSEntityDescription.insertNewObject(forEntityName: "Feed", into: appDelegate.managedObjectContext) as! Feed
        feed.initialize(id: id, message: message, time: Date(timeIntervalSince1970: TimeInterval(timestamp)), locations: locations, tags: tags)
        return feed
    }
    
    /*
     * Helper function to save the context 
     * Written to be asynchronous and nonobstructive (high priority) to prevent the main UI from freezing when it occurs
     */
    class func saveContext() {
        DispatchQueue.global(qos: .userInitiated).async() {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if appDelegate.managedObjectContext.hasChanges {
                do {
                    try appDelegate.managedObjectContext.save()
                } catch {
                    print("Error while saving: \(error)")
                }
            }
        }
    }
    
    /*
     * Helper function to save the context
     * Written to be done on the main thread instead of an asynchronous thread
     */
    class func saveContextMainThread() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if appDelegate.managedObjectContext.hasChanges {
            do {
                try appDelegate.managedObjectContext.save()
            } catch {
                print("Error while saving \(error)")
            }
        }
    }
    
    /*
     * Helper function to load a context.
     * Supply the entity in which you want to load from.
     *
     * The fetchConfiguration is a function which will let you configure the request that takes place.
     * Pass in a function which takes a NSFetchRequest as an argument and returns a void. This NSFetchRequest should be
     * modified to configure the request to take place.
     *
     * Returns a AnyObject? since the entity may not exist
     */
    class func loadContext(entityName: String, fetchConfiguration: ((NSFetchRequest<NSManagedObject>) -> Void)?) -> [NSManagedObject]? {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        // Fetch requested data
        let dataFetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        
        // Configure the fetch request with user parameters
        fetchConfiguration?(dataFetchRequest)
        
        do {
            return try appDelegate.managedObjectContext.fetch(dataFetchRequest)
        } catch {
            print("Failed to fetch feed data, critical error: \(error)")
        }
        
        return nil
    }
    
    /*
     * Helper function to update the last updated time
     */
    class func setLatestUpdateTime(_ time: Date) {
        let defaults = UserDefaults.standard
        defaults.set(time, forKey: "timestamp")
    }
    
    /*
     * Helper function to obtain the last updated time
     */
    class func getLatestUpdateTime() -> Date? {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: "timestamp") as? NSDate as Date?
    }
 
}

/* Helpers for User Profile */
extension CoreDataHelpers {
    class func storeUser(name: String, email: String, school: String, major: String, role: String, barcode: String, barcodeData: Data, auth: String, initTime: Date, expirationTime: Date, userID: NSNumber, diet: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: appDelegate.managedObjectContext) as! User
        user.initialize(name: name, email: email, school: school, major: major, role: role, barcode: barcode, barcodeData: barcodeData, token: auth, initTime: initTime, expirationTime: expirationTime, userID: userID, diet: diet)
        
        self.saveContext()
    }
}

/* Helpers for HelpQ */
extension CoreDataHelpers {
    class func createHelpQItem(technology: String, language: String, location: String, description: String) -> HelpQ {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let helpQ = NSEntityDescription.insertNewObject(forEntityName: "HelpQ", into: appDelegate.managedObjectContext) as! HelpQ
        helpQ.initialize(technology: technology, language: language, location: location, description: description)
        
        return helpQ
    }
    
    // To store chat items, use HelpQ.pushChatItem
}
