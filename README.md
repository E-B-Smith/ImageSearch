# ImageSearch

<img height="200" src="Artwork/Icon.png" alt="ImageSearch Icon">

### A Flickr image search app for iOS.

### Application Architecture

I wrote the app in Swift, the new hot Apple language. The app itself is a pretty simple: It's a `UITableView` app that loads images.

I used the basic networking and logging classes that I wrote for Branch Metrics in Object-C since I know them well.
They're solid and have been tested a lot.

I spent more than four hours on this because I made sure the code was super clean and spent time making some simple app icons and a LaunchScreen. I think apps, even demo apps, seem off with out these.

### Improvements

#### App Architecture Improvements

1. Better error handling and network retries.

2. I'd preload some images as well as the photo data.

3. I'd create two network queues, one for photo metadata, and another for the bulk image downloads so that network traffic
   could be better controlled. The photo metadata should get download priority since it's central to the app functionality.
   People understand if images download slow.

4. For image cacheing I just used a large cache policy on the `NSURLRequest` object, which is super simple and effective.
   If image loading were a problem I'd use a more sophisticated cache.

#### User Interface Improvements

1. The user should be able to select a picture and get a full screen view of the picture. The viewer should allow panning and zooming.

2. The user should be able to see info about the picture: title, picture owner, date taken, picture size, etc.
