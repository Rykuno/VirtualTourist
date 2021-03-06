//
//  PhotoDownloader.swift
//  VirtualTourist
//
//  Created by Donny Blaine on 1/21/17.
//  Copyright © 2017 RyStudios. All rights reserved.
//

import Foundation
import UIKit

class PhotoDownloadClient: NSObject {
    
    private override init() {}
    
    class func sharedInstance() -> PhotoDownloadClient {
        struct Singleton{
            static var sharedInstance = PhotoDownloadClient()
        }
        return Singleton.sharedInstance
    }
    
    func downloadImage(url: String, completionHandler: @escaping (_ image:UIImage?) -> Void) {
        let session = URLSession.shared
        let task = session.dataTask(with: URL(string:url)!) { (data, response, error) in
            guard error == nil else{
                return
            }
            completionHandler(UIImage(data: data!))
        }
        task.resume()
    }
}
 
