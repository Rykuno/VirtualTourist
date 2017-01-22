//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Donny Blaine on 1/21/17.
//  Copyright © 2017 RyStudios. All rights reserved.
//

import Foundation
import UIKit

class FlickrClient: NSObject {
    let session = URLSession.shared
    
    private override init(){}
 
    class func sharedInstance() -> FlickrClient {
        struct Singleton{
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }

    
    func sendRequest(latitude: Double, longitude: Double, completionHandler: @escaping (_ urlArray: [String], _ error: String?) -> Void) {
        let sessionConfig = URLSessionConfiguration.default
        
        /* Create session, and optionally set a URLSessionDelegate. */
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        // Create the Request:

        guard var URL = URL(string: "https://api.flickr.com/services/rest/") else {return}
        let URLParams = [
            "method": "flickr.photos.search",
            "api_key": "040e5c9f08eb49f7ff3ffc7b417af8e9",
            "safe_search": "1",
            "extras": "url_s",
            "per_page": "21",
            "format": "json",
            "nojsoncallback": "1",
            "lat": "\(latitude)",
            "lon": "\(longitude)",
            "radius": "5",
            "radius_units": "mi",
            ]
        URL = URL.appendingQueryParameters(URLParams)
        var request = URLRequest(url: URL)
        request.httpMethod = "GET"
        
        // Headers
        
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        // JSON Body
        
        let bodyObject: [String : Any] = [:]
        request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
        
        /* Start a new Task */
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            
            guard error == nil else{
                completionHandler([], "Check connection and try again")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else{
                return
            }
            
            guard statusCode >= 200 && statusCode <= 299 else{
                completionHandler([], "Error, Try again later")
                return
            }
            
            guard let data = data else{
                completionHandler([], "Data Error")
                return
            }
  
            convertData(data: data, completionHandlerForData: { (result, error) in
                guard error == nil else{
                    completionHandler([], "Data Error")
                    return
                }
                
                guard let result = result else{
                    completionHandler([], "Error parsing data")
                    return
                }
                
                guard let photos = result["photos"] as? [String:AnyObject] else {
                    completionHandler([], "Error Parsing Data")
                    return
                }

                guard let photoArr = photos["photo"] as? [[String:AnyObject]] else{
                    completionHandler([], "Error Parsing Data")
                    return
                }
                
                var arrayOfPhotos = [String]()
                
                for picture in photoArr{
                    let url = parseImages(dictionary: picture)
                    arrayOfPhotos.append(url)
                    }
                
                completionHandler(arrayOfPhotos, nil)
            })
        })
        task.resume()
        session.finishTasksAndInvalidate()
    }
}

private func parseImages(dictionary: [String:AnyObject]) -> String{
    
    guard let url = dictionary["url_s"] else{
        return ""
    }
    return url as! String
}

private func convertData(data: Data, completionHandlerForData:(_ result: AnyObject?, _ error: NSError?) -> Void){
    var parsedData: AnyObject? = nil
    do{
        parsedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        
    }catch{
        let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
        completionHandlerForData(nil, NSError(domain: "convertData", code: 1, userInfo: userInfo))
    }
    completionHandlerForData(parsedData, nil)
}


protocol URLQueryParameterStringConvertible {
    var queryParameters: String {get}
}

extension Dictionary : URLQueryParameterStringConvertible {
    /**
     This computed property returns a query parameters string from the given NSDictionary.
     @return The computed parameters string.
     */
    var queryParameters: String {
        var parts: [String] = []
        for (key, value) in self {
            let part = String(format: "%@=%@",
                              String(describing: key).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!,
                              String(describing: value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
            parts.append(part as String)
        }
        return parts.joined(separator: "&")
    }
    
}

extension URL {
    /**
     Creates a new URL by adding the given query parameters.
     @param parametersDictionary The query parameter dictionary to add.
     @return A new URL.
     */
    func appendingQueryParameters(_ parametersDictionary : Dictionary<String, String>) -> URL {
        let URLString : String = String(format: "%@?%@", self.absoluteString, parametersDictionary.queryParameters)
        return URL(string: URLString)!
    }
    
    
}



    
 
