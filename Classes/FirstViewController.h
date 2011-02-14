//
//  FirstViewController.h
//  RunTunes
//
//  Created by Tamás Ilsinszki on 2/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SecondViewController;

@interface FirstViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	IBOutlet SecondViewController *secondViewController;
	NSArray *runningMixes;
}

@property (nonatomic, retain) SecondViewController *secondViewController;
@property (retain, nonatomic) NSArray *runningMixNames;

@end
