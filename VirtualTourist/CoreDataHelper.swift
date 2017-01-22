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
     var image: UIImage?
    
    private var initialFetch = false
    public var getPinArrayCount: Int {
        get{
            return pinArray.count
        }
    }
    
    class func sharedInstance() -> CoreDataHelper {
        struct Singleton{
            static var sharedInstance = CoreDataHelper()
        }
        return Singleton.sharedInstance
    }
    
    
    //MARK: - Core Data
    func createPin(latitude: CLLocationDegrees, longitude: CLLocationDegrees, completionHandler: (_ error: String?) -> Void){
        let moc = persistentContainer.viewContext
        let pin = Pin(context: moc)
        pin.latitude = latitude
        pin.longitude = longitude
        pinArray.append(pin)
        
        do{
            try moc.save()
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
    
    
    func fetchPhotosForPin(latitude: CLLocationDegrees, longitude: CLLocationDegrees, callback: (_ image: UIImage) -> Void){
        let moc = persistentContainer.viewContext
        let request: NSFetchRequest<Pin> = Pin.fetchRequest()
        
        do{
            let results = try moc.fetch(request)
            for result in results {
                if (result.latitude == latitude && result.longitude == longitude){
                    let pin = result
                    let photos = pin.photo as! Set<Photo>
                    for photo in photos {
                        print(UIImage(data: photo.image as! Data)!)
                        image = (UIImage(data: photo.image as! Data)!)
                        callback(image!)
                    }
                }
            }
        }catch{
            
        }
    }
    
    
    func deletePin(latitude: CLLocationDegrees, longitude: CLLocationDegrees, completionHandler: (_ error: String?)-> Void){
        var pinToDelete: Pin?
        for pin in pinArray {
            if (pin.latitude == latitude && pin.longitude == longitude){
                pinToDelete = pin
                pinArray.remove(at: pinArray.index(of: pin)!)
            }
        }
        
        if let pinToDelete = pinToDelete{
                let moc = persistentContainer.viewContext
                do{
                    try moc.delete(pinToDelete)
                    try moc.save()
                    completionHandler(nil)
                }catch{
                    completionHandler("Failed to remove pin")
                }
        }
    }
    
    func addPhotosToPin(latitude: CLLocationDegrees, longitude: CLLocationDegrees, photoItem: UIImage, completionHandler: (_ error: String?)-> Void) {
        var pinToLocate : Pin?
        let moc = persistentContainer.viewContext
        //Find current pin
        for pin in pinArray {
            if (pin.latitude == latitude && pin.longitude == longitude){
                pinToLocate = pin
            }
        }
        
        let photo = Photo(context: moc)
        photo.image = UIImageJPEGRepresentation(photoItem, 1.0) as NSData?
        pinToLocate?.addToPhoto(photo) 
        print("yay")
        
        do{
            try saveContext()
            completionHandler(nil)
        }
    }
    
    func pinHasPhotos(latitude: Double, longitude: Double) -> Bool {
        let moc = persistentContainer.viewContext
        let request: NSFetchRequest<Pin> = Pin.fetchRequest()
        
        do{
            let results = try moc.fetch(request)
            for result in results {
                if (result.latitude == latitude && result.longitude == longitude) {
                     print("found")
                    if (result.photo?.count)! > 0 {
                        print("has photos")
                        return true
                    }else{
                        return false
                    }
                }
            }
        }catch{
            
        }
        return false
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
