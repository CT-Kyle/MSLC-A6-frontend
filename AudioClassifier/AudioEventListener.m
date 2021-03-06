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
#define DEFAULT_THRESHOLD -35.0;

@interface AudioEventListener ()
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) FFTHelper *fftHelper;
@property (strong, nonatomic) NSTimer* timer;
@property (nonatomic) float noiseThreshold;
@end

@implementation AudioEventListener

+(AudioEventListener*) sharedInstance {
    static AudioEventListener* _sharedInstance = nil;
    
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[AudioEventListener alloc] init];
    });
    
    return _sharedInstance;
}

-(id)init {
    if (self = [super init]) {
        _noiseThreshold = DEFAULT_THRESHOLD;
        
        __block AudioEventListener * __weak  weakSelf = self;
        [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels) {
            [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
        }];
        
        return self;
    }
    
    return nil;
}

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

-(void)setNoiseThreshold:(float)noiseThreshold {
    _noiseThreshold = noiseThreshold;
}

-(void)setUpdateBlock:(UpdateBlock)updateBlock {
    _updateBlock = updateBlock;
}

-(void)play{
    if (_timer) {
        [_timer invalidate];
    }
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                              target:self
                                            selector:@selector(update)
                                            userInfo:nil
                                             repeats:YES];
    
    [self.audioManager play];
}

-(void)pause{
    if (_timer) {
        [_timer invalidate];
    }
    
    [self.audioManager pause];
}

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
