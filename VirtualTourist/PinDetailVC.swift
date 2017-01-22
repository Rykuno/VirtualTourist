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

class PinDetailVC: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var imageArray = [UIImage]()
    var annotation: MKAnnotation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(annotation.coordinate, span)
        self.mapView.setRegion(region, animated: false)
        requestPhotos()
        CoreDataHelper.sharedInstance().fetchPhotosForPin(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude) { (image) in
                imageArray.append(image)
            print("appended image")
            collectionView.reloadData()
        }
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! ImageCell
        cell.image.image = imageArray[indexPath.row]
        return cell
    }
    

    func requestPhotos(){
        let hasPhotosSaved = CoreDataHelper.sharedInstance().pinHasPhotos(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        
        if !hasPhotosSaved{
            FlickrClient.sharedInstance().sendRequest(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude) { (UrlArray, error) in
                guard error == nil else{
                    return
                }
                
                for url in UrlArray {
                    PhotoDownloadClient.sharedInstance().downloadImage(url: url, completionHandler: { (imageData) in
                        DispatchQueue.main.async {
                            CoreDataHelper.sharedInstance().addPhotosToPin(latitude: self.annotation.coordinate.latitude, longitude: self.annotation.coordinate.longitude, photoItem: imageData!, completionHandler: { (error) in
                            })
                        }
                    })
                }
            }
        }
    }
}
