//
//  GADCustomEventNativeAd.h
//  Google Mobile Ads SDK
//
//  Copyright 2015 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GADCustomEventRequest.h"

@protocol GADCustomEventNativeAdDelegate;

/// The protocol for a custom event for a native ad. Your custom event handler object for native ads
/// must implement this protocol. The
/// requestNativeAdWithParameter:request:adTypes:options:rootViewController: method will be called
/// when mediation schedules your custom event to be executed.
@protocol GADCustomEventNativeAd<NSObject>

/// This method is called by mediation when your custom event is scheduled to be executed.
/// |serverParameter| is the parameter configured in the mediation UI for the custom event.
/// |request| contains ad targeting information. |adTypes| contains the list of native ad types
/// requested. See GADAdLoaderAdTypes.h for available ad types. |options| are any additional options
/// configured by the publisher for requesting a native ad. See GADNativeAdImageAdLoaderOptions.h
/// for available image options. |rootViewController| is the view controller provided by the
/// publisher.
- (void)requestNativeAdWithParameter:(NSString *)serverParameter
                             request:(GADCustomEventRequest *)request
                             adTypes:(NSArray *)adTypes
                             options:(NSArray *)options
                  rootViewController:(UIViewController *)rootViewController;

/// Indicates if the custom event handles user clicks. Return YES if the custom event should handle
/// user clicks. In this case Google Mobile Ads SDK doesn't track user click and the custom event
/// should notify the click to Google Mobile Ads SDK using method
/// + [GADMediatedNativeAdNotificationSource mediatedNativeAdDidRecordClick:]. Return NO if the
/// custom event doesn't handles user clicks. In this case Google Mobile Ads SDK does tracks user
/// clicks and the custom event is notified about the user clicks using method
/// - [GADMediatedNativeAdDelegate
/// mediatedNativeAd:didRecordClickOnAssetWithName:view:viewController:].
- (BOOL)handlesUserClicks;

/// The delegate object, used for receiving custom native ad load request progress.
@property(nonatomic, weak) id<GADCustomEventNativeAdDelegate> delegate;

@end
