//
//  NewClassViewController.m
//  AudioClassifier
//
//  Created by toor on 11/12/16.
//  Copyright © 2016 LukeOglesbee. All rights reserved.
//

#import "NewClassViewController.h"
#import "AudioEventListener.h"

#define STARTING_THRESHOLD -35.0

@interface NewClassViewController ()
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UIButton *sampleButton;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;
@property (weak, nonatomic) IBOutlet UISlider *thresholdSlider;
@property (weak, nonatomic) IBOutlet UILabel *thresholdSliderLabel;
@property (weak, nonatomic) IBOutlet UILabel *NoiseLevelTextLabel;
@property (weak, nonatomic) IBOutlet UIButton *sendSamplesButton;

@property (strong, nonatomic) AudioEventListener *audioEventListener;
@property (atomic) BOOL blockAccessed;

@end

@implementation NewClassViewController

- (IBAction)NoiseThresholdSliderChange:(UISlider *)sender {
    [self.audioEventListener setNoiseThreshold:sender.value];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.thresholdSliderLabel setText:[NSString stringWithFormat:@"%.f", sender.value]];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.thresholdSliderLabel setText:[NSString stringWithFormat:@"%.f", STARTING_THRESHOLD]];
    });
    
    //init event listener and send it the block
    NSLog(@"allocate event listener");
    self.audioEventListener = [[AudioEventListener alloc]
                               initWithNoiseThreshold:STARTING_THRESHOLD
                               andUpdateBlock:^(float *fftMagnitude, UInt32 length) {
                                   [self updateFFT:fftMagnitude withLength:length];
                               }];

    
    _blockAccessed = true;
    [self.audioEventListener play];
}

-(void)updateFFT:(float *)fftMagnitude withLength:(UInt32)length {
    if (_blockAccessed) {
        return;
    }
    _blockAccessed = true;
    NSLog(@"lev: %.1f", fftMagnitude[0]);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.NoiseLevelTextLabel setText:[NSString stringWithFormat:@"%.f", fftMagnitude[0]]];
    });
}

- (IBAction)recordSample:(id)sender{
    NSLog(@"blockAccessed = true (recordSample)");
    _blockAccessed = false; //set it to false before it plays, then set true again afterwards
}


- (IBAction)sendSamples:(id)sender {
    //Have to make HTTP request here eventually!
    [self dismissModalViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
