/**
 @file          UIImageView+BNCNetworkService.m
 @package       Branch Groot
 @brief         A UIImageView that downloads web images.

 @author        Edward Smith
 @date          April 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

#import "UIImageView+BNCNetworkService.h"
#import "BNCLog.h"
#import <objc/runtime.h>

static inline void BNCPerformBlockOnMainThreadAsync(dispatch_block_t block) {
    dispatch_async(dispatch_get_main_queue(), block);
}

@interface BNCNetworkOperation (UIImageView)
@property (readwrite) NSError*_Nullable      error;
@property (readwrite) id<NSObject>           responseData;
@end

#pragma mark -

@implementation UIImageView (BNCNetworkService)

- (BNCNetworkOperation*) networkOperation {
    return (BNCNetworkOperation*)objc_getAssociatedObject(self, @selector(networkOperation));
}

- (void) setNetworkOperation:(BNCNetworkOperation*)networkOperation {
    objc_setAssociatedObject(
        self,
        @selector(networkOperation),
        networkOperation,
        OBJC_ASSOCIATION_RETAIN
    );
}

- (NSURL*) imageURL {
    return self.networkOperation.request.URL;
}

- (void) deserializeImageWithOperation:(BNCNetworkOperation*)operation {
    @synchronized (self) {
        if (!operation) return;
        UIImage *image = nil;
        if ([operation.responseData isKindOfClass:[UIImage class]]) {
            image = (UIImage*) operation.responseData;
        } else if ([operation.responseData isKindOfClass:[NSData class]]) {
            @try {
                image = [UIImage imageWithData:(NSData*)operation.responseData];
            }
            @catch (id exception) {
                image = nil;
            }
        } else {
            BNCLogWarning(@"Unknown response class '%@'.", [operation.responseData class]);
        }
        if (image) {
            operation.responseData = image;
        } else {
            operation.error =
                [NSError errorWithDomain:NSCocoaErrorDomain code:NSURLErrorCannotDecodeContentData
                    userInfo:@{ NSLocalizedDescriptionKey: @"Can't decode image data."}];
        }
    }
}

- (void) setImageURL:(NSURL*)URL {
    [self setImageURL:URL completion:nil];
}

- (void) setImageURL:(NSURL*)URL completion:(void (^)(BNCNetworkOperation *))completionBlock {

    void (^localCompletionBlock)(BNCNetworkOperation*operation) =
        ^ (BNCNetworkOperation*operation) {
            // BNCLogDebug(@"Image load completion start.");
            if (operation.responseData) {
                [self deserializeImageWithOperation:operation];
            }
            BNCPerformBlockOnMainThreadAsync(^{
                if ([operation.responseData isKindOfClass:[UIImage class]]) {
                    UIImage *image = (id) operation.responseData;
                    if ([self.superview isKindOfClass:[UIButton class]]) {
                        [(UIButton*)self.superview setImage:image forState:UIControlStateNormal];
                        [self.superview setNeedsLayout];
                        [self.superview setNeedsDisplay];
                    } else {
                        self.image = image;
                        [self setNeedsLayout];
                        [self setNeedsDisplay];
                    }
                }
                if (completionBlock)
                    completionBlock(operation);
                // BNCLogDebug(@"Image load completion complete.");
            });
            // BNCLogDebug(@"Image load completion finish.");
        };

    BNCNetworkOperation *operation = self.networkOperation;
    if (operation.request.URL && URL && [operation.request.URL isEqual:URL]) {
        localCompletionBlock(operation);
        return;
    }
    [operation cancel];
    self.image = [UIImage imageNamed:@"PlaceholderImage"];
    [self setNeedsDisplay];
    if (URL.absoluteString.length == 0) {
        self.networkOperation = nil;
        localCompletionBlock(nil);
        return;
    }
    NSString *scheme = URL.scheme;
    if (scheme.length == 0) {
        NSString *urlString = [URL absoluteString];
        urlString =
            [urlString stringByTrimmingCharactersInSet:
                [NSCharacterSet characterSetWithCharactersInString:@"/"]];
        urlString = [NSString stringWithFormat:@"http://%@", urlString];
        URL = [NSURL URLWithString:urlString];
    }
    self.networkOperation =
        [[BNCNetworkService shared]
            getOperationWithURL:URL
            completion:localCompletionBlock];
    self.networkOperation.request.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
    [self.networkOperation start];
}

@end
