//
//  AudioEventListener.h
//  AudioClassifier
//
//  Created by Luke Oglesbee on 11/10/16.
//  Copyright © 2016 LukeOglesbee. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^UpdateBlock)(float *fttMagnitude, UInt32 length);

@interface AudioEventListener : NSObject
@property (nonatomic, copy) UpdateBlock updateBlock;

-(AudioEventListener*)initWithNoiseThreshold:(float)threshold
                              andUpdateBlock:(UpdateBlock)updateBlock;

-(void)setNoiseThreshold:(float)noiseThreshold;
-(void)setUpdateBlock:(UpdateBlock)updateBlock;

-(void)play;
@end
