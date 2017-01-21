//
//  MapVC.swift
//  VirtualTourist
//
//  Created by Donny Blaine on 1/19/17.
//  Copyright © 2017 RyStudios. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapVC: UIViewController, MKMapViewDelegate {
    
    //MARK: - Variables
    @IBOutlet weak var mapView: MKMapView!
    
    var currentlyEditing: Bool = false
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        createLongPressGestrueForMap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        addUserAnnotations()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        setMapSettings()
    }
    
    //MARK: - Actions
    @IBAction func editAction(_ sender: Any) {
        
    }
    
    //MARK: - Map functions
    func createLongPressGestrueForMap(){
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(createPinOnMap(getstureRecognizer:)))
        longPressRecogniser.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecogniser)
    }
    
    func createPinOnMap(getstureRecognizer : UIGestureRecognizer){
        if getstureRecognizer.state != .began { return }
        let touchPoint = getstureRecognizer.location(in: self.mapView)
        let touchMapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        //create annotation and store lat & long coords
        let annotation = MKPointAnnotation()
        annotation.coordinate = touchMapCoordinate
        let latitude = annotation.coordinate.latitude
        let longitude = annotation.coordinate.longitude
        
        //add the pin to core data
        CoreDataHelper.shared.createPin(latitude: latitude, longitude: longitude) { (error) in
            guard error == nil else {
                displayError(title: "Data Error", message: error!)
                return
            }
            mapView.addAnnotation(annotation)
        }
    }
    
    func addUserAnnotations(){
        self.mapView.removeAnnotations(self.mapView.annotations)
        CoreDataHelper.shared.fetchPins { (annotationArray, error) in
            guard error == nil else{
                return
            }
            
            guard let annotationArray = annotationArray else{
                //No Annotations To Display
                return
            }
            
            self.mapView.addAnnotations(annotationArray)
        }
        //retreive user defined map settings
        getMapSettings()
    }
    
    

    
    //MARK: - UserDefaults
    func getMapSettings(){
        //get current region details
        let spanLat = UserDefaults.standard.value(forKey: Constants.UserDefaults.spanLat) as! CLLocationDegrees
        let spanLong = UserDefaults.standard.value(forKey: Constants.UserDefaults.spanLong) as! CLLocationDegrees
        let centerLat = UserDefaults.standard.value(forKey: Constants.UserDefaults.centerLat) as! CLLocationDegrees
        let centerLong = UserDefaults.standard.value(forKey: Constants.UserDefaults.centerLong) as! CLLocationDegrees
        
        //create new region
        let coordCenter = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLong)
        let coordSpan = MKCoordinateSpanMake(spanLat, spanLong)
        let newRegion = MKCoordinateRegionMake(coordCenter, coordSpan)
        
        //set map to region
        mapView.setRegion(newRegion, animated: true)
    }
    
    func setMapSettings(){
        UserDefaults.standard.setValue(mapView.region.span.latitudeDelta, forKey: Constants.UserDefaults.spanLat)
        UserDefaults.standard.setValue(mapView.region.span.longitudeDelta, forKey: Constants.UserDefaults.spanLong)
        UserDefaults.standard.setValue(mapView.region.center.latitude, forKey: Constants.UserDefaults.centerLat)
        UserDefaults.standard.setValue(mapView.region.center.longitude, forKey: Constants.UserDefaults.centerLong)
        UserDefaults.standard.synchronize()
    }
    
    
}
