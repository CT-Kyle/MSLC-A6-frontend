//
//  RootViewController.m
//  AudioClassifier
//
//  Created by Luke Oglesbee on 11/10/16.
//  Copyright © 2016 LukeOglesbee. All rights reserved.
//

#import "RootViewController.h"
#import "AudioEventListener.h"
#import "HTTPConstants.h"

#define STARTING_THRESHOLD -35.0

@interface RootViewController () <NSURLSessionTaskDelegate>
@property (strong, nonatomic) AudioEventListener *audioEventListener;
@property (weak, nonatomic) IBOutlet UILabel *NoiseLevelTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *NoiseThresholdTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *KNNTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *RFCTextLabel;

@property (strong, nonatomic) NSURLSession *session;
@property (strong, nonatomic) NSTimer * predictionResetTimer;
@end


@implementation RootViewController

-(AudioEventListener*) audioEventListener {
    if (!_audioEventListener) {
        _audioEventListener = [AudioEventListener sharedInstance];
    }
    return _audioEventListener;
}

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
    
    //setup NSURLSession (ephemeral)
    NSURLSessionConfiguration *sessionConfig =
    [NSURLSessionConfiguration ephemeralSessionConfiguration];
    
    sessionConfig.timeoutIntervalForRequest = 5.0;
    sessionConfig.timeoutIntervalForResource = 8.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 1;
    
    self.session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                 delegate:self
                                            delegateQueue:nil];

    [self.audioEventListener setNoiseThreshold:STARTING_THRESHOLD];
    
//    [self.audioEventListener play];
}

-(void)viewWillAppear:(BOOL)animated {
    __block RootViewController * __weak  weakSelf = self;
    [self.audioEventListener setUpdateBlock:^(float *fftMagnitude, UInt32 length) {
        [weakSelf updateFFT:fftMagnitude withLength:length];
    }];
    [self.audioEventListener play];
}

-(void)viewWillDisappear:(BOOL)animated {
    [_audioEventListener pause];
}


-(void)updateFFT:(float *)fftMagnitude withLength:(UInt32)length {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.NoiseLevelTextLabel setText:[NSString stringWithFormat:@"%.f", fftMagnitude[0]]];
    });
    
    NSMutableArray *featureData = [[NSMutableArray alloc] init];
    for (int i = 0; i < length; ++i) {
        [featureData addObject:[[NSNumber alloc] initWithFloat:fftMagnitude[i]]];
    }
    
    [self predictFeature:[NSArray arrayWithArray:featureData]];
}

- (void)clearPredictionLables {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.KNNTextLabel setText:@"--"];
        [self.RFCTextLabel setText:@"--"];
        
    });
}

- (void)predictFeature:(NSArray*)data {
    // send the server new feature data and request back a prediction of the class
    
    // setup the url
    NSString *baseURL = [NSString stringWithFormat:@"%s/PredictOne",BASE_URL];
    NSURL *postUrl = [NSURL URLWithString:baseURL];
    
    
    // data to send in body of post request (send arguments as json)
    NSError *error = nil;
    NSDictionary *jsonUpload = @{@"feature":data};
    
    NSData *requestBody=[NSJSONSerialization dataWithJSONObject:jsonUpload options:NSJSONWritingPrettyPrinted error:&error];
    
    // create a custom HTTP POST request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:postUrl];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:requestBody];
    
    // start the request, print the responses etc.
    NSURLSessionDataTask *postTask = [self.session dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                NSLog(@"error: %@", error);
                return;
            }
            
            NSUInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
            
            if (statusCode != HTTP_OK) {
                NSLog(@"Predict One: %lu", (unsigned long)statusCode);
                return;
            }
            
            NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error: &error];
            NSString *labelKNN = [NSString stringWithFormat:@"%@",[responseData valueForKey:@"predictionKN"]];
            NSString *labelRFC = [NSString stringWithFormat:@"%@",[responseData valueForKey:@"predictionRF"]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.KNNTextLabel setText:labelKNN];
                [self.RFCTextLabel setText:labelRFC];
                if (_predictionResetTimer) {
                    [_predictionResetTimer invalidate];
                }
                _predictionResetTimer = [NSTimer scheduledTimerWithTimeInterval:1.2
                                                          target:self
                                                        selector:@selector(clearPredictionLables)
                                                        userInfo:nil
                                                         repeats:NO];
            });

            // TODO: Update UI with label
     }];
    [postTask resume];
}


@end

