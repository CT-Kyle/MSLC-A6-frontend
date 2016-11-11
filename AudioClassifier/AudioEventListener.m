//
//  AudioEventListener.m
//  AudioClassifier
//
//  Created by Luke Oglesbee on 11/10/16.
//  Copyright © 2016 LukeOglesbee. All rights reserved.
//

#import "AudioEventListener.h"
#import "Novocaine.h"
#import "CircularBuffer.h"
#import "FFTHelper.h"

#define BUFFER_SIZE 8192

@interface AudioEventListener ()
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) FFTHelper *fftHelper;
@property (nonatomic) float noiseThreshold;
@end

@implementation AudioEventListener

-(Novocaine*)audioManager{
    if(!_audioManager){
        _audioManager = [Novocaine audioManager];
    }
    
    return _audioManager;
}

-(CircularBuffer*)buffer{
    if(!_buffer){
        _buffer = [[CircularBuffer alloc]initWithNumChannels:1 andBufferSize:BUFFER_SIZE];
    }
    return _buffer;
}

-(FFTHelper*)fftHelper{
    if(!_fftHelper){
        _fftHelper = [[FFTHelper alloc]initWithFFTSize:BUFFER_SIZE];
    }
    return _fftHelper;
}

-(AudioEventListener*)initWithNoiseThreshold:(float)threshold
                              andUpdateBlock:(UpdateBlock)updateBlock{
    if (self = [super init]) {
        self.noiseThreshold = threshold;
        
        self.updateBlock = updateBlock;
        
        __block AudioEventListener * __weak  weakSelf = self;
        [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels) {
            [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
        }];

        return self;
    }
    
    return nil;
}

-(void)setNoiseThreshold:(float)noiseThreshold {
    _noiseThreshold = noiseThreshold;
}

-(void)setUpdateBlock:(UpdateBlock)updateBlock {
    _updateBlock = updateBlock;
}

-(void)play{
    [NSTimer scheduledTimerWithTimeInterval:0.1
                                     target:self
                                   selector:@selector(update)
                                   userInfo:nil
                                    repeats:YES];
    
    [self.audioManager play];
}

// TODO: Implement a pause

-(void)update{
    float * data = calloc(sizeof(float), BUFFER_SIZE);
    float * fftMagnitude = calloc(sizeof(float), BUFFER_SIZE/2);
    
    [self.buffer fetchFreshData:data
                 withNumSamples:BUFFER_SIZE];
    
    [self.fftHelper performForwardFFTWithData:data
                   andCopydBMagnitudeToBuffer:fftMagnitude];
    
    if (fftMagnitude[0] > self.noiseThreshold) {
        self.updateBlock(fftMagnitude, BUFFER_SIZE/2);
    }
}

@end
