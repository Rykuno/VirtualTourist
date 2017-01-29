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
    let moc = CoreDataClient.sharedInstance().persistentContainer.viewContext
    private override init(){}
 
    //MARK: - Singleton
    class func sharedInstance() -> FlickrClient {
        struct Singleton{
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }

    //MARK: - Download JSON
    func sendRequest(latitude: Double, longitude: Double, page: Int, completionHandler: @escaping (_ urlArray: [String]?, _ error: String?) -> Void) {
        let sessionConfig = URLSessionConfiguration.default
        /* Create session, and optionally set a URLSessionDelegate. */
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        // Create the Request:
        guard var URL = URL(string: Constants.Flickr.baseUrl) else {return}
        let URLParams = [
            Constants.Flickr.Param.method: Constants.Flickr.Key.method,
            Constants.Flickr.Param.apiKey: Constants.Flickr.Key.apiKey,
            Constants.Flickr.Param.safeSearch: Constants.Flickr.Key.safeSearch,
            Constants.Flickr.Param.extras: Constants.Flickr.Key.extras,
            Constants.Flickr.Param.perPage: Constants.Flickr.Key.perPage,
            Constants.Flickr.Param.format: Constants.Flickr.Key.format,
            Constants.Flickr.Param.noJsonCallback: Constants.Flickr.Key.noJsonCallback,
            Constants.Flickr.Param.latitude: "\(latitude)",
            Constants.Flickr.Param.longitude: "\(longitude)",
            Constants.Flickr.Param.radius: Constants.Flickr.Key.radius,
            Constants.Flickr.Param.page: "\(page)",
            Constants.Flickr.Param.radiusUnits: Constants.Flickr.Key.radiusUnits,
            ]
        
        URL = URL.appendingQueryParameters(URLParams)
        var request = URLRequest(url: URL)
        request.httpMethod = Constants.Flickr.httpMethod
        
        // Headers
        request.addValue(Constants.Flickr.HTTPHeaderValue, forHTTPHeaderField: Constants.Flickr.HTTPHeaderField)
        
        // JSON Body
        let bodyObject: [String : Any] = [:]
        request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
        
        // Start a new Task
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            
            guard error == nil else{
                completionHandler(nil, Constants.Error.Message.checkConnection)
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else{
                return
            }
            
            guard statusCode >= 200 && statusCode <= 299 else{
                completionHandler(nil, Constants.Error.Message.tryAgain)
                return
            }
            
            guard let data = data else{
                completionHandler(nil, Constants.Error.Message.dataError)
                return
            }
  
            convertData(data: data, completionHandlerForData: { (result, error) in
                guard error == nil else{
                    completionHandler(nil, Constants.Error.Message.dataError)
                    return
                }
                
                guard let result = result else{
                    completionHandler(nil, Constants.Error.Message.dataError)
                    return
                }
                
                guard let photos = result[Constants.Flickr.Results.photos] as? [String:AnyObject] else {
                    completionHandler(nil, Constants.Error.Message.dataError)
                    return
                }
                
                guard let pages = photos[Constants.Flickr.Results.pages] as? Int else {
                    completionHandler(nil, Constants.Error.Message.dataError)
                    return
                }

                guard let photoArr = photos[Constants.Flickr.Results.photo] as? [[String:AnyObject]] else{
                    completionHandler(nil, Constants.Error.Message.dataError)
                    return
                }
                
                var arrayOfUrls = [String]()
                
                self.moc.performAndWait({ 
                CoreDataClient.sharedInstance().savePagesForPin(latitude: latitude, longitude: longitude, pages: pages)
                })

                
                
                for picture in photoArr{
                        let url = parseImages(dictionary: picture)
                        arrayOfUrls.append(url)
                }
                
                    completionHandler(arrayOfUrls, nil)
                
            })
        })
        task.resume()
        session.finishTasksAndInvalidate()
    }
    //MARK: - Download Images
    func downloadImage(url: URL, completionHandler: @escaping (_ downloadedData: Data?) -> Void){
        DispatchQueue.global().async {
            let data = try? Data(contentsOf: url)
            completionHandler(data!)
        }
    }
}
 //MARK: - Helper Functions
private func parseImages(dictionary: [String:AnyObject]) -> String{
    
    guard let url = dictionary[Constants.Flickr.Key.extras] else{
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



    
 
