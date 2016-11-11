//
//  RootViewController.m
//  AudioClassifier
//
//  Created by Luke Oglesbee on 11/10/16.
//  Copyright © 2016 LukeOglesbee. All rights reserved.
//

#import "RootViewController.h"
#import "AudioEventListener.h"

#define STARTING_THRESHOLD -35.0

@interface RootViewController ()
@property (strong, nonatomic) AudioEventListener *audioEventListener;
@property (weak, nonatomic) IBOutlet UILabel *NoiseLevelTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *NoiseThresholdTextLabel;
@end


@implementation RootViewController

#pragma mark UI Stuff
- (IBAction)NoiseThresholdSliderChange:(UISlider *)sender {
    [self.audioEventListener setNoiseThreshold:sender.value];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.NoiseThresholdTextLabel setText:[NSString stringWithFormat:@"%.f", sender.value]];
    });
}

-(void)viewDidLoad{
    [super viewDidLoad];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.NoiseThresholdTextLabel setText:[NSString stringWithFormat:@"%.f", STARTING_THRESHOLD]];
    });

    self.audioEventListener = [[AudioEventListener alloc]
                               initWithNoiseThreshold:STARTING_THRESHOLD
                               andUpdateBlock:^(float *fftMagnitude, UInt32 length) {
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

