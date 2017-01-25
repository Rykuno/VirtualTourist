//
//  CoreDataHelper.swift
//  VirtualTourist
//
//  Created by Donny Blaine on 1/19/17.
//  Copyright © 2017 RyStudios. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class CoreDataHelper {
    
    private var pinArray = [Pin]()
    public var getPinArrayCount: Int {
        get{ 
            return pinArray.count
        }
    }
    
    private var initialFetch = false
    
    
    class func sharedInstance() -> CoreDataHelper {
        struct Singleton{
            static var sharedInstance = CoreDataHelper()
        }
        return Singleton.sharedInstance
    }
    
    
    //MARK: - Core Data
    func createPin(latitude: Double, longitude: Double, completionHandler: (_ error: String?) -> Void){
        let moc = persistentContainer.viewContext
        let pin = Pin(context: moc)
        pin.latitude = latitude
        pin.longitude = longitude
        pinArray.append(pin)
        do{
            try moc.save()
            print("created Pin")
            completionHandler(nil)
        }catch{
            completionHandler("Error Saving Data")
        }
    }
    
    func fetchPins(completionHandler: (_ annotationArray: [MKAnnotation]?, _ error:String?) -> Void) {
        let moc = persistentContainer.viewContext
        let request: NSFetchRequest<Pin> = Pin.fetchRequest()
        do{
            let results = try moc.fetch(request)
            if !initialFetch {
                pinArray.append(contentsOf: results)
                initialFetch = true
            }
            var annotationArr = [MKAnnotation]()
            for result in results {
                let annotation = MKPointAnnotation()
                annotation.coordinate.latitude = result.latitude
                annotation.coordinate.longitude = result.longitude
                annotationArr.append(annotation)
            }
            completionHandler(annotationArr, nil)
        }catch{
            completionHandler(nil, "Error fetching pins")
        }
    }
    
    func deletePin(latitude: CLLocationDegrees, longitude: CLLocationDegrees, completionHandler: (_ error: String?)-> Void){
        let pin = findPin(latitude: latitude, longitude: longitude)
        let moc = persistentContainer.viewContext
            do{
                if let pin = pin{
                    try moc.delete(pin)
                    try moc.save()
                    completionHandler(nil)
                }else{
                    completionHandler("Failed to remove Pin")
                }
            }catch{
                completionHandler("Failed to save removed pin")
            }
     }
    
    func createImageUrls(urlArray: [String], latitude: Double, longitude: Double, completionHandler: (_ success: Bool, _ error: String?) -> Void) {
        let pin = findPin(latitude: latitude, longitude: longitude)
        let moc = persistentContainer.viewContext
        do{
            if let pin = pin {
                for url in urlArray {
                    let photo = Photo(context: moc)
                    photo.url = url
                    pin.addToPhoto(photo)
                    print("added photo")
                }
                saveContext()
                completionHandler(true, nil)

            }else{
                completionHandler(false, "Error Creating Image Urls")
            }
        }
    }
    
    
    func fetchImageUrls(latitude: Double, longitude: Double, completionHandler: (_ urlArray: [String]?, _ error: String?) -> Void) {
        //Find pin with matching lat and long
        let pin = findPin(latitude: latitude, longitude: longitude)
        var urlArray = [String]()
        
        do{
            if let pin = pin {
                let photos = (pin.photo?.allObjects) as! [Photo]
                for photo in photos {
                    urlArray.append(photo.url!)
                }
                completionHandler(urlArray, nil)
            }else{
                completionHandler(nil, "Could Not Find URLs")
            }
        }
    }
    
    
    
    
    func savePhotoToPin(latitude: Double, longitude: Double, images: [String:Data], completionHandler: (_ success: Bool, _ error: String?) -> Void) {
        let moc = persistentContainer.viewContext
        let request: NSFetchRequest<Photo> = Photo.fetchRequest()
        
        do{
            let results = try moc.fetch(request)
            for result in results {
                if let resultURL = result.url{
                    let value = images[resultURL]
                    result.image = value as NSData?
                }
            }
            saveContext()
            completionHandler(true, nil)
        }catch{
            completionHandler(false, "Error creating image urls")
        }
    }
    
    
    func findPin(latitude: Double, longitude: Double) -> Pin?{
        let moc = persistentContainer.viewContext
        let request: NSFetchRequest<Pin> = Pin.fetchRequest()
        
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: true)
        let requestPredicateLat = NSPredicate(format: "latitude == %lf", latitude)
        let requestPredicateLon = NSPredicate(format: "longitude == %lf", longitude)
        let compoundPredicate = NSCompoundPredicate(type: .and, subpredicates: [requestPredicateLat,requestPredicateLon])
        request.sortDescriptors = [sortDescriptor]
        request.predicate = compoundPredicate
        
        do{
            let results = try moc.fetch(request)
            if results.count > 0 {
                return results[0]
            }else{
                return nil
            }
        }catch{
            
        }
        return nil
    }
    
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "VirtualTourist")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}
