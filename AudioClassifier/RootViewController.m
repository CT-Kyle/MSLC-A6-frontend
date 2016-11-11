//
//  RootViewController.m
//  AudioClassifier
//
//  Created by Luke Oglesbee on 11/10/16.
//  Copyright © 2016 LukeOglesbee. All rights reserved.
//

#import "RootViewController.h"
#import "AudioEventListener.h"

#define BUFFER_SIZE 8192
#define STARTING_THRESHOLD -35

@interface RootViewController ()
@property float noiseThreshold;
@property (strong, nonatomic) AudioEventListener *audioEventListener;
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

-(void)viewDidLoad{
    [super viewDidLoad];
    
    self.noiseThreshold = STARTING_THRESHOLD;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.NoiseThresholdTextLabel setText:[NSString stringWithFormat:@"%.f", self.noiseThreshold]];
    });

    self.audioEventListener = [[AudioEventListener alloc] initWithUpdateBlock:^(float *fftMagnitude, UInt32 length) {
        [self updateFFT:fftMagnitude withLength:length];
    }];
    
    [self.audioEventListener play];
}

-(void)updateFFT:(float *)fftMagnitude withLength:(UInt32)length {
    NSLog(@"%.1f", fftMagnitude[0]);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.NoiseLevelTextLabel setText:[NSString stringWithFormat:@"%.f", fftMagnitude[0]]];
    });
}



@end

