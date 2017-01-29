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
 
class CoreDataClient {
    
    //MARK: - Variables
    private var pinArray = [Pin]()
    public var getPinArrayCount: Int {
        get{
            return pinArray.count
        }
    }
    private var initialFetch = false
    
    //MARK: - Singleton
    class func sharedInstance() -> CoreDataClient {
        struct Singleton{
            static var sharedInstance = CoreDataClient()
        }
        return Singleton.sharedInstance
    } 
    
    //MARK: - Pin Operations
    func savePin(latitude: Double, longitude: Double, completionHandler: (_ error: String?) -> Void){
        let moc = persistentContainer.viewContext
        let pin = Pin(context: moc)
        pin.latitude = latitude
        pin.longitude = longitude
        pinArray.append(pin)
        do{
            try moc.save()
            completionHandler(nil)
        }catch{
            completionHandler(Constants.Error.Message.saveError)
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
    
    func fetchNumberOfPages(annotation: MKAnnotation, completionHandler: (_ pages: Int16) -> Void){
        let pin = findPin(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        if let pin = pin{
            let numberOfPages = pin.pages
            completionHandler(numberOfPages)
        }else{ 
            completionHandler(1)
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
            completionHandler(nil, Constants.Error.Message.fetchError)
        }
    }
    
    func deletePin(latitude: CLLocationDegrees, longitude: CLLocationDegrees, completionHandler: (_ error: String?)-> Void){
        let pin = findPin(latitude: latitude, longitude: longitude)
        let moc = persistentContainer.viewContext
        do{
            if let pin = pin{
                moc.delete(pin)
                try moc.save()
                completionHandler(nil)
            }else{
                completionHandler("Failed to remove Pin")
            }
        }catch{
            completionHandler("Failed to save removed pin")
        }
    }
    
    func savePagesForPin(latitude: Double, longitude: Double, pages: Int) {
        let moc = persistentContainer.viewContext
        moc.performAndWait {
        let pin = self.findPin(latitude: latitude, longitude: longitude)
        pin?.pages = Int16(pages)
        
        do{
            self.saveContext()
        }
        }
    }
    
    
    //MARK: - Photo Operations
    func saveImageUrls(urlArray: [String], latitude: Double, longitude: Double, completionHandler: (_ success: Bool, _ error: String?) -> Void) {
        let pin = findPin(latitude: latitude, longitude: longitude)
        let moc = persistentContainer.viewContext
        do{
            if let pin = pin {
                for url in urlArray {
                    let photo = Photo(context: moc)
                    photo.url = url
                    pin.addToPhoto(photo)
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
    
    func savePhotos(annotation: MKAnnotation, photos: [Photo], completionHandler: (_ success: Bool, _ error: String?) -> Void) {
        let pin = findPin(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        let pinPhotos = pin?.photo
        if pin == pin {
            pin?.removeFromPhoto(pinPhotos!)
            for photo in photos{
                pin?.addToPhoto(photo)
            }
            
            do{
                saveContext()
            }
        }
    }
    
    func deletePhoto(photo: Photo){
        let moc = persistentContainer.viewContext
        
        do{
            moc.delete(photo)
        }
    }
    
    func deleteAllPhotos(annotation: MKAnnotation){
        let pin = findPin(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        let photos = pin?.photo?.allObjects as! [Photo]
        let moc = persistentContainer.viewContext
        
        do{
            for photo in photos{
                moc.delete(photo)
            }
            saveContext()
        }
    }
    
    func fetchPhotos(annotation: MKAnnotation, completionHandler: (_ arrayOfPhotos:[Photo]?, _ error: String?) -> Void ){
        let pin = findPin(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        
        if let pin = pin{
            let photos = pin.photo?.allObjects as! [Photo]
            completionHandler(photos, nil)
        }else{
            completionHandler(nil, "Could not find Pin")
        }
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
