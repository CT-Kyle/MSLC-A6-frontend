//
//  SettingsModel.m
//  AudioClassifier
//
//  Created by Luke Oglesbee on 11/14/16.
//  Copyright © 2016 LukeOglesbee. All rights reserved.
//

#import "SettingsModel.h"
#import "HTTPConstants.h"

@interface SettingsModel() <NSURLSessionTaskDelegate>

@property (strong, nonatomic) NSURLSession *session;
@end

@implementation SettingsModel


+(SettingsModel*)sharedInstance {
    static SettingsModel* _sharedInstance = nil;
    
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[SettingsModel alloc] init];
    });
    
    return _sharedInstance;
}

-(id)init{
    if(self=[super init]) {
        _KNAlgorithm = @"Auto";
        _KNNeighbors = 5;
        _RFTrees = 10;
        _noiseThreshold = -35;
    }

   
    
    return self;
}

-(NSURLSession*)session {
    if (!_session) {
        NSURLSessionConfiguration *sessionConfig =
        [NSURLSessionConfiguration ephemeralSessionConfiguration];
        
        sessionConfig.timeoutIntervalForRequest = 5.0;
        sessionConfig.timeoutIntervalForResource = 8.0;
        sessionConfig.HTTPMaximumConnectionsPerHost = 1;
        
        _session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                 delegate:self
                                                delegateQueue:nil];
    }
    return _session;
}


-(void)getRemote:(CompletionBlock)completionBlock {
    NSString *baseURL = [NSString stringWithFormat:@"%s/GetParameters", BASE_URL];
    NSURL *url = [NSURL URLWithString:baseURL];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithURL:url
        completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
            if (error) {
                NSLog(@"error: %@", error);
                return;
            }
            
            NSUInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
            if (statusCode != HTTP_OK) {
                NSLog(@"Get Parameters: %lu", (unsigned long)statusCode);
                return;
            }
            
            NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            _KNAlgorithm = [NSString stringWithFormat:@"%@",[responseData valueForKey:@"KNeighborsAlg"]];;
            _KNNeighbors = [[responseData valueForKey:@"KNeighborsN"] intValue];
            _RFTrees = [[responseData valueForKey:@"RandomForestN"] intValue];
            
            completionBlock();
    }];
    
    [task resume];
}

-(void)postRemote:(CompletionBlock)completionBlock {
    NSString *baseURL = [NSString stringWithFormat:@"%s/SetParameters", BASE_URL];
    NSURL *url = [NSURL URLWithString:baseURL];
    
    NSError *error = nil;
    NSDictionary *jsonUpload = @{
                                 @"KNeighborsAlg": self.KNAlgorithm,
                                 @"KNeighborsN": [NSNumber numberWithInt:self.KNNeighbors],
                                 @"RandomForestN": [NSNumber numberWithInt:self.RFTrees],
                                 };
    
    NSData *requestBody = [NSJSONSerialization dataWithJSONObject:jsonUpload options:NSJSONWritingPrettyPrinted error:&error];
    
    if (error != nil) {
        NSLog(@"Error encoding json. %@", error);
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:requestBody];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
        completionHandler:^(NSData * data, NSURLResponse * response, NSError * error) {
            if (error) {
                NSLog(@"error: %@", error);
                return;
            }
            
            NSUInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
            if (statusCode != HTTP_OK) {
                NSLog(@"Set Parameters: %lu", (unsigned long)statusCode);
                return;
            }
            
            completionBlock();
    }];
    
    [task resume];
    
}


@end

