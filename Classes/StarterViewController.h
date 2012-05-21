//
//  StarterViewController.h
//  RunTunes
//
//  Created by Tamás Ilsinszki on 9/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RunningViewController;
@class TracklistViewController;

@interface StarterViewController : UIViewController {
    IBOutlet RunningViewController *runningViewController;
    IBOutlet TracklistViewController *tracklistViewController;
}

@property (nonatomic, retain) RunningViewController *runningViewController;
@property (nonatomic, retain) TracklistViewController *tracklistViewController;

- (IBAction)startRunningButtonPressed:(id)sender;
- (IBAction)changeRunnningMixButtonPressed:(id)sender;
- (IBAction)tracklistButtonPressed:(id)sender;

@end
