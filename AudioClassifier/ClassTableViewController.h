//
//  ClassTableViewController.h
//  AudioClassifier
//
//  Created by toor on 11/11/16.
//  Copyright © 2016 LukeOglesbee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ClassTableViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource>
@property (atomic) NSMutableArray *classArray;
+ (NSMutableArray *)getDataFrom:(NSString *)baseURL;

@end
