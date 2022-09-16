//
//  ISSTrackerNetwork.m
//  ISSTracker
//
//  Created by Seif Kobrosly on 9/14/22.
//

#import <Foundation/Foundation.h>
#import "ISSTrackerNetwork.h"

@implementation ISSTracker


- (void)retrieveJSONISSLocation:(void(^)(NSDictionary *, NSError *))completion {

    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.open-notify.org/iss-now.json"]];

    //create the Method "GET"
    [urlRequest setHTTPMethod:@"GET"];

    NSURLSession *session = [NSURLSession sharedSession];

    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if(httpResponse.statusCode == 200)
        {
            NSError *parseError = nil;
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
#if DEBUG
            NSLog(@"The response is - %@",responseDictionary);
#endif
            completion(responseDictionary, nil);
        }
        else
        {
#if DEBUG
            NSLog(@"Error: %@", error);
#endif
            completion(nil, error);
        }
    }];
    [dataTask resume];
}

@end
