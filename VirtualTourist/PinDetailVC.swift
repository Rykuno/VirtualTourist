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

class PinDetailVC: UIViewController, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var urlArray = [String]()
    var imageDictionary = [String:Data]()
    var annotation: MKAnnotation!
    var latitude: Double!
    var longitude: Double!
 
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        CoreDataHelper.sharedInstance().savePhotoToPin(latitude: latitude, longitude: longitude, images: imageDictionary) { (success, error) in
            if success {
                print("Updated")
            }
        }
    }
     
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(annotation.coordinate, span)
        self.mapView.setRegion(region, animated: false)
        retrieveImageUrls(latitude: latitude, longitude: longitude)
    }
 

    func retrieveImageUrls(latitude: Double, longitude: Double){
        FlickrClient.sharedInstance().sendRequest(latitude: latitude, longitude: longitude) { (urlArray, error) in
            guard error == nil else{
                self.displayError(title: "Download Error", message: error!)
                return
            }
            
            guard urlArray.count != 0 else {
                self.displayError(title: "Download Error", message: "No Images to Be Shown")
                return
            }
            
            CoreDataHelper.sharedInstance().createImageUrls(urlArray: urlArray, latitude: latitude, longitude: longitude, completionHandler: { (success, error) in
                if success {
                    DispatchQueue.main.async {
                    self.urlArray = urlArray
                    self.collectionView.reloadData()
                    }
                }
            })
            
        }
    }
    
    func configureCell(_ cell: UICollectionViewCell, for indexPath: IndexPath){
        guard let cell = cell as? ImageCell else {return}
        cell.activityIndicator.startAnimating()
        cell.backgroundColor = UIColor.gray
        
        
        //If Images DO NOT exist yet
        let url = URL(string: urlArray[indexPath.row])
        DispatchQueue.global().async {
            let data = try? Data(contentsOf: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
            self.imageDictionary.updateValue(data!, forKey: self.urlArray[indexPath.row])
            DispatchQueue.main.async {
                cell.image.image = UIImage(data: data!)
            }
        }
    }
}

extension PinDetailVC: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return urlArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ImageCell
        configureCell(cell, for: indexPath)
        return cell
    }
    
    
    
}
