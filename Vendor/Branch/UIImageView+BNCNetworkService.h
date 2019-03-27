/**
 @file          UIImageView+BNCNetworkService.h
 @package       Branch Groot
 @brief         A UIImageView that downloads web images.

 @author        Edward Smith
 @date          April 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

#import <UIKit/UIKit.h>
#import "BNCNetworkService.h"

@interface UIImageView (BNCNetworkService)
- (NSURL*_Nullable) imageURL;
- (void) setImageURL:(NSURL*_Nullable)URL;
- (void) setImageURL:(NSURL*_Nullable)URL completion:(void(^_Nullable)(BNCNetworkOperation*_Nonnull operation))completionBlock;
@end
