//
//  ISFlickrImage.swift
//  ImageSearch
//
//  Created by Edward Smith on 3/22/19.
//  Copyright © 2019 Edward Smith. All rights reserved.
//

import UIKit

/*
    Flickr image data from JSON. Here's an example of the expected JSON:
    {
       "farm": 1,
       "height_s": "240",
       "id": "33094387050",
       "isfamily": 0,
       "isfriend": 0,
       "ispublic": 1,
       "owner": "29314320@N07",
       "secret": "89019909cc",
       "server": "667",
       "title": "Stanley T. 3-16-2017",
       "url_s": "https://farm1.staticflickr.com/667/33094387050_89019909cc_m.jpg",
       "width_s": "180"
    }
*/

class ISFlickrPhoto {
    private var dictionary: [String:Any]!
    static var kDefaultImage = UIImage.init(named: "PlaceholderImage")!
    
    init(dictionary: [String:Any]) {
        self.dictionary = dictionary
    }
    var title: String? {
        return self.dictionary["title"] as? String
    }
    var url: URL? {
        if let s = self.dictionary["url_s"] as? String {
            return URL.init(string: s)
        }
        return nil
    }
}

class ISFlickrPhotoOperation {
    var networkOperation: BNCNetworkOperation? = nil
    var page: Int = 0
    var photosPerPage: Int = 0
    var totalPhotos: Int = 0
    var photos: [ISFlickrPhoto] = []
}

extension String {
    func stringByAddingPercentEncodingForRFC3986() -> String? {
        let unreserved = "-._~/?"
        let allowed = NSMutableCharacterSet.alphanumeric()
        allowed.addCharacters(in: unreserved)
        return self.addingPercentEncoding(withAllowedCharacters: allowed as CharacterSet)
    }
}

class ISFlickrPhotoService {

    /* Get Flickr photos with search text starting at page
    Flickr API:
    https://www.flickr.com/services/api/flickr.photos.search.html
    https://www.flickr.com/services/api/misc.urls.html
    */

    static let photosPerPage: Int = 10

    @discardableResult
    static func fetchPhotoData(
        searchTerm: String,
        page: Int,
        completion: @escaping (ISFlickrPhotoOperation) -> Void
    ) -> BNCNetworkOperation {

        let encodedTerm = searchTerm.stringByAddingPercentEncodingForRFC3986()!
        let s =
            "https://api.flickr.com/services/rest/?method=flickr.photos.search" +
            "&api_key=675894853ae8ec6c242fa4c077bcf4a0&text=\(encodedTerm)&page=\(page)" +
            "&extras=url_s&format=json&nojsoncallback=1" +
            "&per_page=\(photosPerPage)"
        guard let url = URL.init(string: s)
        else {
            fatalError("Can't make a URL from '\(s)'.")
        }
        let netop = BNCNetworkService.shared().getOperationWith(url) { (operation) in
            let flickrResponse = ISFlickrPhotoOperation()
            flickrResponse.networkOperation = operation
            if operation.error != nil {
                completion(flickrResponse)
                return
            }
            operation.deserializeJSONResponseData()
            if  let outer = operation.responseData as? [String:Any],
                let dictionary = outer["photos"] as? [String:Any] {
                flickrResponse.page = dictionary["page"] as? Int ?? 0
                flickrResponse.photosPerPage = dictionary["perpage"] as? Int ?? 0
                flickrResponse.totalPhotos = Int(dictionary["total"] as? String ?? "0") ?? 0
                if let a = dictionary["photo"] as? [Dictionary<String, Any>] {
                    for d in a {
                        let photo = ISFlickrPhoto.init(dictionary: d)
                        flickrResponse.photos.append(photo)
                    }
                }
            completion(flickrResponse)
            }
        }
        netop.request?.cachePolicy = .reloadIgnoringLocalCacheData
        return netop
    }

    @discardableResult
    static func fetch(
        photo: ISFlickrPhoto,
        completion: @escaping (BNCNetworkOperation) -> Void
    ) -> BNCNetworkOperation? {
        guard let url = photo.url else { return nil }
        let netop = BNCNetworkService.shared().getOperationWith(url) { (operation) in
            completion(operation)
        }
        netop.request?.cachePolicy = .returnCacheDataElseLoad
        return netop
    }

}
