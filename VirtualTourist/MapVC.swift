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

class MapVC: UIViewController {
    
    //MARK: - Variables
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var slideView: UIView!
    @IBOutlet weak var editBarItem: UIBarButtonItem!
    
    var currentEditing: Bool = false
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        createLongPressGestrueForMap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        slideView.isHidden = true
        addUserAnnotations()
        getMapSettings()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        showSlideView(showing: false)
        self.editBarItem.isEnabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        setMapSettings()
    }
    
    //MARK: - Actions
    @IBAction func editAction(_ sender: Any) {
        if currentEditing == false && CoreDataHelper.sharedInstance().getPinArrayCount == 0 {
            displayError(title: "No Pins to Delete", message: "Place a pin on the map first")
        }else{
            slideView.isHidden = false
            currentEditing = !currentEditing
            showSlideView(showing: currentEditing)
        }
    }
    
    func showSlideView(showing: Bool){
        if showing == false {
            self.editBarItem.isEnabled = false
            self.editBarItem.title = "Edit"
            UIView.animate(withDuration: 0.5, animations: {
                self.slideView.frame.origin.y = self.view.frame.origin.y + self.view.frame.size.height + 70
            }, completion: { (finished) in
                if finished {
                    self.slideView.isHidden = true
                    self.editBarItem.isEnabled = true
                }
            })
        }
        
        if (showing == true && CoreDataHelper.sharedInstance().getPinArrayCount > 0) {
            self.editBarItem.title = "Done"
            self.editBarItem.isEnabled = false
            UIView.animate(withDuration: 0.5, animations: { 
                self.slideView.frame.origin.y = self.view.frame.origin.y + self.view.frame.size.height - 70
            }, completion: { (finished) in
                if finished{
                    self.editBarItem.isEnabled = true
                }
            })
        }
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
        CoreDataHelper.sharedInstance().createPin(latitude: latitude, longitude: longitude) { (error) in
            guard error == nil else {
                displayError(title: "Data Error", message: error!)
                return
            }
            mapView.addAnnotation(annotation)
        }
    }
    
    func addUserAnnotations(){
        self.mapView.removeAnnotations(self.mapView.annotations)
        CoreDataHelper.sharedInstance().fetchPins { (annotationArray, error) in
            guard error == nil else{
                displayError(title: "Oh No!", message: "There was an error fetching Pins")
                return
            }
            
            guard let annotationArray = annotationArray else{
                //No Annotations To Display
                return
            }
            
            self.mapView.addAnnotations(annotationArray)
        }
    }
    
    

    
    //MARK: - UserDefaults
    func getMapSettings(){
        //get current region details
        var spanLat: CLLocationDegrees!
        var spanLong: CLLocationDegrees!
        var centerLat: CLLocationDegrees!
        var centerLong: CLLocationDegrees!
        
        if UserDefaults.standard.value(forKey: Constants.UserDefaults.spanLat) == nil {
            spanLat = mapView.region.span.latitudeDelta
            spanLong = mapView.region.span.longitudeDelta
            centerLat = mapView.region.center.latitude
            centerLong = mapView.region.center.longitude
        }else{
            spanLat = UserDefaults.standard.value(forKey: Constants.UserDefaults.spanLat) as! CLLocationDegrees
            spanLong = UserDefaults.standard.value(forKey: Constants.UserDefaults.spanLong) as! CLLocationDegrees
            centerLat = UserDefaults.standard.value(forKey: Constants.UserDefaults.centerLat) as! CLLocationDegrees
            centerLong = UserDefaults.standard.value(forKey: Constants.UserDefaults.centerLong) as! CLLocationDegrees
        }
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

extension MapVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if currentEditing == true && view.annotation != nil {
            let annotation = view.annotation
            let latitude = annotation?.coordinate.latitude
            let longitude = annotation?.coordinate.longitude
            
            CoreDataHelper.sharedInstance().deletePin(latitude: latitude!, longitude: longitude!, completionHandler: { (error) in
                guard error == nil else{
                    displayError(title: "Deletion Error", message: error!)
                    return
                }
                mapView.removeAnnotation(annotation!)
            })
        }else{
            let controller = storyboard?.instantiateViewController(withIdentifier: "PinDetailVC") as! PinDetailVC
            controller.annotation = view.annotation
            controller.latitude = view.annotation?.coordinate.latitude
            controller.longitude = view.annotation?.coordinate.longitude
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
}
