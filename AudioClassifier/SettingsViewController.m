//
//  SettingsViewController.m
//  AudioClassifier
//
//  Created by Luke Oglesbee on 11/14/16.
//  Copyright © 2016 LukeOglesbee. All rights reserved.
//

#import "SettingsViewController.h"
#import "SettingsModel.h"

@interface SettingsViewController ()
@property (weak, nonatomic) IBOutlet UILabel *KNNeighborsTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *RFTreesTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *NoiseThresholdTextLabel;

@property (weak, nonatomic) IBOutlet UISegmentedControl *KNAlgorithmSegmentedControl;
@property (weak, nonatomic) IBOutlet UIStepper *KNNeighborsStepper;
@property (weak, nonatomic) IBOutlet UIStepper *RFTreesStepper;
@property (weak, nonatomic) IBOutlet UIStepper *NoiseThresholdStepper;

@property (strong, nonatomic) SettingsModel *settingsModel;
@property BOOL loading;
@end

@implementation SettingsViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    _loading = NO;
    
    [self.settingsModel getRemote:^{
        _loading = YES;
        [self.KNNeighborsStepper setValue:self.settingsModel.KNNeighbors];
        [self.RFTreesStepper setValue:self.settingsModel.RFTrees];
        [self.NoiseThresholdStepper setValue:self.settingsModel.noiseThreshold];
    
        NSDictionary *algEncode = @{
                                    @"auto":@0,
                                    @"brute":@1,
                                    @"kd_tree":@2,
                                    @"ball_tree":@3};
        [self.KNAlgorithmSegmentedControl setSelectedSegmentIndex:[algEncode[self.settingsModel.KNAlgorithm] intValue]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.KNNeighborsTextLabel setText:[NSString stringWithFormat:@"%d",self.settingsModel.KNNeighbors]];
            [self.RFTreesTextLabel setText:[NSString stringWithFormat:@"%d",self.settingsModel.RFTrees]];
            [self.NoiseThresholdTextLabel setText:[NSString stringWithFormat:@"%d",self.settingsModel.noiseThreshold]];
        });
    }];
}

-(SettingsModel*)settingsModel {
    if(!_settingsModel) {
        _settingsModel = [SettingsModel sharedInstance];
    }
    return _settingsModel;
}

#pragma mark UI Event Handlers
-(IBAction)savePress:(id)sender {
    if (!_loading) return;
    _loading = YES;
    [self.settingsModel postRemote:^{
        _loading = NO;
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

-(IBAction)cancelPress:(id)sender {
    if (!_loading) return;
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)KNAlgorithmChange:(UISegmentedControl *)sender {
    if (!_loading) return;
    NSArray *algDecode = @[@"auto", @"brute", @"kd_tree", @"ball_tree"];
    self.settingsModel.KNAlgorithm = algDecode[sender.selectedSegmentIndex];
}

-(IBAction)KNNeighborsChange:(UIStepper *)sender {
    if (!_loading) return;
    int value = sender.value;
    self.settingsModel.KNNeighbors = value;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.KNNeighborsTextLabel setText:[NSString stringWithFormat:@"%d", value]];
    });
}

-(IBAction)RFTreesChange:(UIStepper *)sender {
    if (!_loading) return;
    int value = sender.value;
    self.settingsModel.RFTrees = value;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.RFTreesTextLabel setText:[NSString stringWithFormat:@"%d", value]];
    });
}

-(IBAction)thresholdChange:(UIStepper *)sender {
    if (!_loading) return;
    int value = sender.value;
    self.settingsModel.noiseThreshold = value;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.NoiseThresholdTextLabel setText:[NSString stringWithFormat:@"%d", value]];
    });
}

@end
