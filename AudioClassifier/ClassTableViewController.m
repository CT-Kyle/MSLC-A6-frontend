//
//  ClassTableViewController.m
//  AudioClassifier
//
//  Created by toor on 11/11/16.
//  Copyright © 2016 LukeOglesbee. All rights reserved.
//

#import "ClassTableViewController.h"
#import "HTTPConstants.h"

@interface ClassTableViewController ()
@property (weak, nonatomic) IBOutlet UIButton *addClassButton;

@end

@implementation ClassTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.classArray = [[NSMutableArray alloc] init];
    NSString *baseURL = [NSString stringWithFormat:@"%s/GetClasses",BASE_URL];
    self.classArray = [ClassTableViewController getDataFrom: baseURL];  //do it this way because its a class method

    
    UIBarButtonItem *addClassButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(manualSegueFunction:)];
    self.navigationItem.rightBarButtonItem = addClassButton;
}

// helper function to be called in view did load, performs the GET request for the classes
+ (NSMutableArray *)getDataFrom:(NSString *)baseURL{
    NSURL *getUrl = [NSURL URLWithString:baseURL];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:baseURL]];
    
    NSError *error = [[NSError alloc] init];
    NSHTTPURLResponse *responseCode = nil;
    
    NSData *oResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];
    
    if([responseCode statusCode] != 200){
        NSLog(@"Error getting %@, HTTP status code %li", baseURL, (long)[responseCode statusCode]);
        return nil;
    }
    
    //Now parse the data into JSON if connection was successful!
    NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:oResponseData options:0 error:&error];
    
    return [parsedObject valueForKey:@"classes"];
}


- (void)manualSegueFunction:(id)sender{
    [self performSegueWithIdentifier:@"NewClassSegue" sender:sender];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.classArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *simpleTableIdentifier = @"ClassLabel";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    cell.textLabel.text = [self.classArray objectAtIndex:indexPath.row];
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


// Override to support editing the table view.
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        // Delete the row from the data source
//        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
//        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
//    }   
//}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
