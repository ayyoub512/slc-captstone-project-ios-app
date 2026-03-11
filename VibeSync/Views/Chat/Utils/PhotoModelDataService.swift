//
//  PhotoModelDataService.swift
//  VibeSync
//
//  Created by Ayyoub on 9/3/2026.
//

import Foundation
import SwiftUI

class PhotoModelDataService {
    
    static let shared = PhotoModelDataService()
    private init(){}
    
    var photoCache: NSCache<NSString, UIImage> = {
        var cache = NSCache<NSString, UIImage>()
        cache.countLimit = 50
        cache.totalCostLimit = 1024 * 1024 * 200 // 200mb
        return cache
    }()
    
    func add(key: String, value: UIImage){
        photoCache.setObject(value, forKey: key as NSString)
    }
    
    func get(key: String) -> UIImage? {
        return photoCache.object(forKey: key as NSString)
    }
}


