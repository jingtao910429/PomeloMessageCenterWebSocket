//
//  ViewController.h
//  Client
//
//  Created by xiaochuan on 13-9-23.
//  Copyright (c) 2013年 xiaochuan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PomeloClient.h"
@interface ViewController : UIViewController

- (IBAction)connect:(id)sender;
- (IBAction)routeInit:(id)sender;
- (IBAction)getNotify:(id)sender;
- (IBAction)send:(id)sender;
- (IBAction)getGroupInfo:(id)sender;
- (IBAction)notifyGroupList:(id)sender;

@end
