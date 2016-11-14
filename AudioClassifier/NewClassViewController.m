//
//  NewClassViewController.m
//  AudioClassifier
//
//  Created by toor on 11/12/16.
//  Copyright © 2016 LukeOglesbee. All rights reserved.
//

#import "NewClassViewController.h"
#import "AudioEventListener.h"
#import "HTTPConstants.h"
#import "ClassTableViewController.h"

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


@property (strong,nonatomic) NSURLSession *session;

@end

@implementation NewClassViewController


-(AudioEventListener*) audioEventListener {
    if (!_audioEventListener) {
        _audioEventListener = [AudioEventListener sharedInstance];
    }
    return _audioEventListener;
}

- (IBAction)NoiseThresholdSliderChange:(UISlider *)sender {
    [self.audioEventListener setNoiseThreshold:sender.value];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.thresholdSliderLabel setText:[NSString stringWithFormat:@"%.f", sender.value]];
    });
}
-(void)dismissKeyboard {
    [self.nameField resignFirstResponder];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _sampleArray = [[NSMutableArray alloc] init];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.thresholdSliderLabel setText:[NSString stringWithFormat:@"%.f", STARTING_THRESHOLD]];
    });
    
    //init event listener and send it the block
    NSLog(@"allocate event listener");
    
    
    [self.audioEventListener setNoiseThreshold:STARTING_THRESHOLD];
    
//    self.audioEventListener = [[AudioEventListener alloc]
//                               initWithNoiseThreshold:STARTING_THRESHOLD
//                               andUpdateBlock:^(float *fftMagnitude, UInt32 length) {
//                                   [self updateFFT:fftMagnitude withLength:length];
//                               }];

    
    _blockAccessed = true;
}

-(void)viewWillAppear:(BOOL)animated {
    __block NewClassViewController * __weak  weakSelf = self;
    [self.audioEventListener setUpdateBlock:^(float *fftMagnitude, UInt32 length) {
        [weakSelf updateFFT:fftMagnitude withLength:length];
    }];
    [self.audioEventListener play];
}

-(void)viewWillDisappear:(BOOL)animated {
    [self.audioEventListener pause];
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
    NSMutableArray *featureData = [[NSMutableArray alloc] init];
    for (int i = 0; i < length; ++i) {
        [featureData addObject:[[NSNumber alloc] initWithFloat:fftMagnitude[i]]];
    }
    [self.sampleArray addObject:featureData];
}

- (IBAction)recordSample:(id)sender{
    NSLog(@"blockAccessed = true (recordSample)");
    _blockAccessed = false; //set it to false before it plays, then set true again afterwards
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.NoiseLevelTextLabel setText:@"Ready"];
    });
}

- (IBAction)resetClass:(id)sender{
    NSLog(@"Resetting class... Somebody probably put in some crappy data.");
    [self.sampleArray removeAllObjects];
}

- (IBAction)sendSamples:(id)sender {
    //send the server the array of samples with the label to train a new class

    
    // setup the url - CHANGE THE ENDPOINT
    NSString *baseURL = [NSString stringWithFormat:@"%s/AddDataPoint",BASE_URL];
    NSURL *postUrl = [NSURL URLWithString:baseURL];
    
    // data to send in the post request (as JSON)
    NSError *error = nil;
    NSString *label = [self.nameField text];
    NSDictionary *jsonUpload = @{@"feature":self.sampleArray, @"label":label}; //set JSON dict
    
    NSData *requestBody=[NSJSONSerialization dataWithJSONObject:jsonUpload options:NSJSONWritingPrettyPrinted error:&error];
    
    // create a custom HTTP POST request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:postUrl];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:requestBody];
    
    //Still need to add error handling
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if(conn) {
        NSLog(@"Connection Successful");
    } else {
        NSLog(@"Connection could not be made");
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    NSString *baseURL2 = [NSString stringWithFormat:@"%s/UpdateModel",BASE_URL];
    [self updateModel:baseURL2];
    [self dismissModalViewControllerAnimated:YES];
}

// helper function to be called in view did load, performs the GET request for the classes
- (NSMutableArray *)updateModel:(NSString *)baseURL2{
    NSURL *getUrl = [NSURL URLWithString:baseURL2];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:baseURL2]];
    
    NSError *error = [[NSError alloc] init];
    NSHTTPURLResponse *responseCode = nil;
    
    NSData *oResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];
    
    if([responseCode statusCode] != 200){
        NSLog(@"Error getting %@, HTTP status code %li", baseURL2, (long)[responseCode statusCode]);
        return nil;
    }
    else {
        NSLog(@"Successfully Updated");
    }
    //Now parse the data into JSON if connection was successful!
    NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:oResponseData options:0 error:&error];
    
    return [parsedObject valueForKey:@"classes"];
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
