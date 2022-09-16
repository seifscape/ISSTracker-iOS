//
//  ISSTrackerNetwork.h
//  ISSTracker
//
//  Created by Seif Kobrosly on 9/14/22.
//
#import <Foundation/Foundation.h>

@interface ISSTracker : NSObject

- (void)retrieveJSONISSLocation:(void(^)(NSDictionary *, NSError *))completion;

@end
