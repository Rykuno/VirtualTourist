//
//  Constants.swift
//  VirtualTourist
//
//  Created by Donny Blaine on 1/20/17.
//  Copyright © 2017 RyStudios. All rights reserved.
//

import Foundation

struct Constants {
    
    //MARK: - UserDefaults
    struct UserDefaults{
       static let centerLat = "centerLat"
       static let centerLong = "centerLong"
       static let spanLat = "spanLat"
       static let spanLong = "spanLong"
    }
    
    //MARK: - Flickr API
    struct Flickr{
        
        static let baseUrl = "https://api.flickr.com/services/rest/"
        static let httpMethod = "GET"
        static let HTTPHeaderField = "Content-Type"
        static let HTTPHeaderValue = "application/json; charset=utf-8"
        
        struct Param{
            static let method = "method"
            static let apiKey = "api_key"
            static let safeSearch = "safe_search"
            static let extras = "extras"
            static let perPage = "per_page"
            static let format = "format"
            static let noJsonCallback = "nojsoncallback"
            static let latitude = "lat"
            static let longitude = "lon"
            static let radius = "radius"
            static let page = "page"
            static let radiusUnits = "radius_units"
        }
        
        struct Key{
            static let method = "flickr.photos.search"
            static let apiKey = "040e5c9f08eb49f7ff3ffc7b417af8e9"
            static let safeSearch = "1"
            static let extras = "url_s"
            static let perPage = "20"
            static let format = "json"
            static let noJsonCallback = "1"
            static let radius = "5"
            static let radiusUnits = "mi"
        }
        
        struct Results{
            static let photos = "photos"
            static let pages = "pages"
            static let photo = "photo"
        }
    }
    
    //MARK: - Error Messages
    struct Error {
        
        struct Title {
            static let generic = "Oh-No!"
            static let checkConnection = "Connection Error"
            static let fetchError = "Fetch Error"
            
            
        }
        
        struct Message {
            static let tryAgain = "Error, Try again later"
            static let dataError = "Error parsing data"
            static let checkConnection = "Check connection and try again"
            static let saveError = "Error saving data"
            static let fetchError = "Unable to fetch from database"
            
        }
    }
} 
 
