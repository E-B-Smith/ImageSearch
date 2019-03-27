//
//  ISImageTableViewController.swift
//  ImageSearch
//
//  Created by Edward Smith on 3/22/19.
//  Copyright © 2019 Edward Smith. All rights reserved.
//

import UIKit

class ISImageTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching, UISearchBarDelegate {

    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var activityView: UIActivityIndicatorView!
    
    var totalPhotos:Int = 0
    var photoData = [ISFlickrPhoto]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNeedsStatusBarAppearanceUpdate()
        self.tableView.contentInset = UIEdgeInsets.init(top: -36.0, left: 0.0, bottom: -36.0, right: 0.0)
        let nib = UINib.init(nibName: "ISImageTableViewCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: ISImageTableViewCell.reuseID)
        searchTerm = "Happy Dogs"
        self.searchBar.text = searchTerm
        self.fetchPhotoData(page: 1)
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    // MARK: - Table View

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return totalPhotos
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ISImageTableViewCell.height
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ISImageTableViewCell.reuseID,
            for: indexPath
        ) as! ISImageTableViewCell
        //cell.debugLabel.text = "\(indexPath.row)"
        cell.debugLabel.isHidden = true
        if indexPath.row < photoData.count {
            let photo = photoData[indexPath.row]
            cell.largeImageView.setImageURL(_: photo.url)
        } else {
            // The cell data didn't prefetch in time. Show the default image for now.
            BNCLog(level: .warning, message: "No data for row \(indexPath.row)!")
            cell.largeImageView.image = ISFlickrPhoto.kDefaultImage
        }
        return cell
    }

    // MARK: - Search
    
    var searchTerm: String = ""

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchTerm = searchBar.text ?? ""
        searchTerm = searchTerm.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        searchBar.resignFirstResponder()
        BNCLog(level: .debug, message: "Search: '\(searchTerm)'.")
        self.messageLabel.text = "Finding '\(searchTerm)'..."
        self.totalPhotos = 0
        self.tableView.reloadData()
        cancelAllPageLoads()
        self.photoData.removeAll()
        fetchPhotoData(page: 1)
    }

    // MARK: - Data Prefetch

    var currentPageOperations = Dictionary<Int, BNCNetworkOperation>()
    var currentPageOperationQueue = DispatchQueue.init(label: "ImageSearch.pageoperation.queue")

    func pageFor(row: Int) -> Int {
        return (row / ISFlickrPhotoService.photosPerPage) + 1
    }

    func pageNeedsLoading(page: Int) -> Bool {
        var result = true
        self.currentPageOperationQueue.sync {
            // Is the page already loaded?
            let lastRowForPage = (page * ISFlickrPhotoService.photosPerPage) - 1
            if (lastRowForPage < self.photoData.count) {
                result = false
                return
            }

            // Is the page loading?
            if currentPageOperations[page] != nil {
                result = false
                return
            }
        }
        return result
    }

    func cancelPageLoad(page: Int) {
        self.currentPageOperationQueue.sync {
            if let operation = currentPageOperations[page] {
                operation.cancel()
                currentPageOperations[page] = nil
            }
        }
    }

    func cancelAllPageLoads() {
        self.currentPageOperationQueue.sync {
            for operation in currentPageOperations.values {
                operation.cancel()
            }
            currentPageOperations.removeAll()
        }
    }

    func update(photoData: ISFlickrPhotoOperation) {
        DispatchQueue.main.async {
            if photoData.networkOperation?.error != nil {
                self.messageLabel.text = photoData.networkOperation?.error?.localizedDescription
            }
            else
            if photoData.photos.count <= 0 {
                self.messageLabel.text = "Can't find photos for '\(self.searchTerm)'."
            }
            else {
                var index = (photoData.page - 1) * photoData.photosPerPage
                // Resize the array if needed. Just add the first element a bunch for now.
                let total = index + photoData.photosPerPage
                while self.photoData.count < total {
                    self.photoData.append(photoData.photos[0])
                }
                for photo in photoData.photos {
                    self.photoData[index] = photo
                    index += 1
                }
                if self.totalPhotos != photoData.totalPhotos {
                    self.totalPhotos = photoData.totalPhotos
                    self.tableView.reloadData()
                }
            }
        }
        self.currentPageOperationQueue.sync {
            currentPageOperations[photoData.page] = nil
        }
    }
    
    func fetchPhotoData(page: Int) {
        self.activityView.startAnimating()
        self.currentPageOperationQueue.sync {
            let operation = ISFlickrPhotoService.fetchPhotoData(
                searchTerm: searchTerm,
                page: page) { (operation) in
                DispatchQueue.main.async {
                    self.update(photoData: operation)
                    self.activityView.stopAnimating()
                }
            }
            currentPageOperations[page] = operation
            operation.start()
        }
    }

    func tableView(_ tableView: UITableView, prefetchRowsAt: [IndexPath]) {
        for row in prefetchRowsAt {
            let page = pageFor(row: row.row)
            if pageNeedsLoading(page: page) {
                self.fetchPhotoData(page: page)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt: [IndexPath]) {
        for row in cancelPrefetchingForRowsAt {
            let page = pageFor(row: row.row)
            cancelPageLoad(page: page)
        }
    }

}
