//
//  StarterViewController.h
//  RunTunes
//
//  Created by Tamás Ilsinszki on 9/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RunningViewController;

@interface StarterViewController : UIViewController {
    IBOutlet RunningViewController *runningViewController;
}

@property (nonatomic, retain) RunningViewController *runningViewController;

- (IBAction)startRunningButtonPressed:(id)sender;
- (IBAction)changeRunnningMixButtonPressed:(id)sender;

@end
