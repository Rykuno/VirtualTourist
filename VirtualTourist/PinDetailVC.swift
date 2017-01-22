//
//  PinDetailVC.swift
//  VirtualTourist
//
//  Created by Donny Blaine on 1/21/17.
//  Copyright © 2017 RyStudios. All rights reserved.
//

import UIKit
import MapKit

class PinDetailVC: UIViewController, MKMapViewDelegate, UICollectionViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var annotation: MKAnnotation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
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
    }
    
    func requestPhotos(){
        let hasPhotosSaved = CoreDataHelper.sharedInstance().pinHasPhotos(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        if !hasPhotosSaved{
            FlickrClient.sharedInstance().sendRequest(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude) { (UrlArray, error) in
                guard error == nil else{
                    return
                }
                
                for url in UrlArray {
                    PhotoDownloader.sharedInstance().downloadImage(url: url, completionHandler: { (imageData) in
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
