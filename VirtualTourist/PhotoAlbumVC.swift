//
//  PinDetailVC.swift
//  VirtualTourist
//
//  Created by Donny Blaine on 1/21/17.
//  Copyright © 2017 RyStudios. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumVC: UIViewController, MKMapViewDelegate {
    
    //MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var modificationButton: UIButton!
    
    //MARK: - Variables
    var annotation: MKAnnotation!
    var photos = [Photo]()
    var selectedItems = [IndexPath]()
    let moc = CoreDataClient.sharedInstance().persistentContainer.viewContext
    
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        //Saves Album upon Exit
        CoreDataClient.sharedInstance().savePhotos(annotation: annotation, photos: photos) { (success, error) in
            print("success")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(annotation.coordinate, span)
        self.mapView.setRegion(region, animated: false)
        
        if photos.count == 0 {
            downloadCollectionOfPhotos(randomPage: false)
        }
    }
    
    //MARK: - Photo Downloader
    func downloadCollectionOfPhotos(randomPage: Bool){
        let latitude = annotation.coordinate.latitude
        let longitude = annotation.coordinate.longitude
        var pageToSearch: Int!
        modificationButton.isEnabled = false
        
        if currentReachabilityStatus  != .notReachable{
            photos.removeAll()
            collectionView.reloadData()
            
            if randomPage == false{
                pageToSearch = 1
            }else{
                CoreDataClient.sharedInstance().fetchNumberOfPages(annotation: annotation) { (pages) in
                    
                    if pages < 200{
                        pageToSearch = Int(arc4random_uniform(UInt32(pages)))
                    }else{
                        pageToSearch = Int(arc4random_uniform(UInt32(200)))
                    }
                }
            }
            FlickrClient.sharedInstance().sendRequest(latitude: latitude, longitude: longitude, page: pageToSearch) { (urlArray, error) in
                
                guard error == nil else {
                    self.displayError(title: Constants.Error.Title.generic, message: error!)
                    return
                }
                
                guard let urlArray = urlArray else{
                    self.displayError(title: Constants.Error.Title.generic, message: "No images to display")
                    return
                }
                self.moc.performAndWait({
                    CoreDataClient.sharedInstance().saveImageUrls(urlArray: urlArray, latitude: latitude, longitude: longitude, completionHandler: { (success, error) in
                        
                        guard success == true else{
                            self.displayError(title: Constants.Error.Title.generic, message: error!)
                            return
                        }
                        CoreDataClient.sharedInstance().fetchPhotos(annotation: self.annotation, completionHandler: { (photos, error) in
                            guard error == nil else {
                                self.displayError(title: Constants.Error.Title.fetchError, message: error!)
                                return
                            }
                            guard let photos = photos else{
                                self.displayError(title: Constants.Error.Title.fetchError, message: error!)
                                return
                            }
                            DispatchQueue.main.async {
                                self.photos = photos
                                self.collectionView.reloadData()
                                self.modificationButton.isEnabled = true
                            }
                        })
                    })
                    
                })
            }
        }else{
            modificationButton.isEnabled = true
            self.displayError(title: Constants.Error.Title.checkConnection, message: Constants.Error.Message.checkConnection)
        }
    }
    
    //MARK: - Modify Photos
    func deleteSelectedPhotos(){
        var photosToDelete = [Photo]()
        
        collectionView.performBatchUpdates({
            let sortedIndexes = self.selectedItems.sorted( by: {$0.row > $1.row})
            for index in sortedIndexes {
                self.collectionView.deleteItems(at: [index])
                let photo = self.photos[index.row]
                photosToDelete.append(photo)
                self.photos.remove(at: index.row)
            }
        }) { (completed) in
            if self.photos.count == 0 {
                self.downloadCollectionOfPhotos(randomPage: true)
            }
        }
        
        for photo in photosToDelete {
            CoreDataClient.sharedInstance().deletePhoto(photo: photo)
        }
        
        //saves context after deletion
        CoreDataClient.sharedInstance().saveContext()
        selectedItems = [IndexPath]()
        updateButton()
    }
    
    @IBAction func modifyPhotosButton(_ sender: Any) {
        if selectedItems.count > 0 {
            deleteSelectedPhotos()
        }else{
            CoreDataClient.sharedInstance().deleteAllPhotos(annotation: annotation)
            downloadCollectionOfPhotos(randomPage: true)
        }
    }
    
    func updateButton(){
        if selectedItems.count > 0 {
            modificationButton.setTitle("Remove Selected", for: .normal)
        }else{
            modificationButton.setTitle("New Collection", for: .normal)
        }
    }
}

//MARK: - CollectionView Functions
extension PhotoAlbumVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ImageCell
        cell.activityIndicator.startAnimating()
        cell.backgroundColor = UIColor.gray
        let photo = photos[indexPath.row]
        
        if let image = photo.image{
            cell.image.image = UIImage(data: image as Data)
            cell.activityIndicator.stopAnimating()
        }else{
            if let photoUrl = photo.url {
                let url = URL(string: photoUrl)
                FlickrClient.sharedInstance().downloadImage(url: url!, completionHandler: { (data) in
                    DispatchQueue.main.async {
                        if let data = data {
                            photo.image = data as NSData?
                            cell.activityIndicator.stopAnimating()
                            cell.image.image = UIImage(data: data)
                            CoreDataClient.sharedInstance().saveContext()  
                        }else{
                            cell.image.image = UIImage(named: "EmptyImage")
                            cell.activityIndicator.stopAnimating()
                        }
                    }
                })
            }
        }
        
        if (selectedItems.contains(indexPath)){
            cell.image.alpha = 0.25
        } else {
            cell.image.alpha = 1.0
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! ImageCell
        
        if let index = selectedItems.index(of: indexPath) {
            selectedItems.remove(at: index)
            cell.image.alpha = 1.0
        } else {
            selectedItems.append(indexPath)
            cell.image.alpha = 0.25
        }
        
        updateButton()
    }
    
}

