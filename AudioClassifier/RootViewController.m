//
//  RootViewController.m
//  AudioClassifier
//
//  Created by Luke Oglesbee on 11/10/16.
//  Copyright © 2016 LukeOglesbee. All rights reserved.
//

#import "RootViewController.h"
#import "Novocaine.h"
#import "CircularBuffer.h"
#import "FFTHelper.h"

#define BUFFER_SIZE 8192
#define STARTING_THRESHOLD -35

@interface RootViewController ()
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) FFTHelper *fftHelper;
@property float noiseThreshold;
@property (weak, nonatomic) IBOutlet UILabel *NoiseLevelTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *NoiseThresholdTextLabel;
@end


@implementation RootViewController

#pragma mark UI Stuff
- (IBAction)NoiseThresholdSliderChange:(UISlider *)sender {
    self.noiseThreshold = sender.value;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.NoiseThresholdTextLabel setText:[NSString stringWithFormat:@"%.f", sender.value]];
    });
}

#pragma mark Lazy Instantiation
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

-(void)viewDidLoad{
    [super viewDidLoad];
    
    __block RootViewController * __weak  weakSelf = self;
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels) {
        [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
    }];
    
    
    self.noiseThreshold = STARTING_THRESHOLD;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.NoiseThresholdTextLabel setText:[NSString stringWithFormat:@"%.f", self.noiseThreshold]];
    });
    
    [NSTimer scheduledTimerWithTimeInterval:0.1
                                     target:self
                                   selector:@selector(update)
                                   userInfo:nil
                                    repeats:YES];
    
    [self.audioManager play];
}

-(void)update{
    float * data = calloc(sizeof(float), BUFFER_SIZE);
    float * fftMagnitude = calloc(sizeof(float), BUFFER_SIZE/2);
    
    [self.buffer fetchFreshData:data
                 withNumSamples:BUFFER_SIZE];
    
    [self.fftHelper performForwardFFTWithData:data
                   andCopydBMagnitudeToBuffer:fftMagnitude];
    
    if (fftMagnitude[0] > self.noiseThreshold) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.NoiseLevelTextLabel setText:[NSString stringWithFormat:@"%.f", fftMagnitude[0]]];
        });
    }
}



@end

