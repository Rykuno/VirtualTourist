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
    @IBOutlet weak var modificationButton: UIButton!
    
    var urlArray = [String]()
    var imageDictionary = [String:Data]()
    var dataArray = [Data]()
    var annotation: MKAnnotation!
    var latitude: Double!
    var longitude: Double!
    var pinHasPhotos: Bool = false
 
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
        CoreDataHelper.sharedInstance().pinHasPhotos(latitude: latitude, longitude: longitude, completionHandler: { (success, hasPhotos) in
            if success {
                retrieveImageUrls(latitude: latitude, longitude: longitude, hasPhotos: hasPhotos)
            }
        })
    }
  
 
    @IBAction func modifyPhotos(_ sender: Any) {
    }
    
    
    func retrieveImageUrls(latitude: Double, longitude: Double, hasPhotos: Bool){
        
        if hasPhotos{
            CoreDataHelper.sharedInstance().fetchPhotos(latitude: latitude, longitude: longitude, completionHandler: { (success, dictionary) in
                if success {
                    DispatchQueue.main.async {
                        self.pinHasPhotos = true
                        self.imageDictionary = dictionary!
                        for (_,value) in self.imageDictionary{
                            self.dataArray.append(value)
                        }
                        self.collectionView.reloadData()
                    }
                }
            })
        }else{
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
    }
    
    func configureCell(_ cell: UICollectionViewCell, for indexPath: IndexPath){
        guard let cell = cell as? ImageCell else {return}
        cell.activityIndicator.startAnimating()
        cell.backgroundColor = UIColor.gray
        if pinHasPhotos == false{
            //If Images DO NOT exist yet
            let url = URL(string: urlArray[indexPath.row])
            DispatchQueue.global().async {
                let data = try? Data(contentsOf: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                self.imageDictionary.updateValue(UIImageJPEGRepresentation(UIImage(data: data!)!, 0.3)!, forKey: self.urlArray[indexPath.row])
                DispatchQueue.main.async {
                    cell.image.image = UIImage(data: data!)
                }
            }
        }else{
         cell.image.image = UIImage(data: dataArray[indexPath.row])
        }
    }
}

extension PinDetailVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if urlArray.count == 0 {
            return dataArray.count
        }else{
            return urlArray.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ImageCell
        configureCell(cell, for: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        //
    }
    
}

