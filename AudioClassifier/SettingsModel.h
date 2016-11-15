//
//  SettingsModel.h
//  AudioClassifier
//
//  Created by Luke Oglesbee on 11/14/16.
//  Copyright © 2016 LukeOglesbee. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^CompletionBlock)();

@interface SettingsModel : NSObject
@property (strong, nonatomic) NSString* KNAlgorithm;
@property int KNNeighbors;
@property int RFTrees;
@property int noiseThreshold;

+(SettingsModel*)sharedInstance;

-(void)getRemote:(CompletionBlock)completionBlock;
-(void)postRemote:(CompletionBlock)completionBlock;

@end
