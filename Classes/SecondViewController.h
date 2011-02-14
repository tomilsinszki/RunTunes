//
//  SecondViewController.h
//  RunTunes
//
//  Created by Tamás Ilsinszki on 2/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ThirdViewController;

@interface SecondViewController : UIViewController {
	IBOutlet ThirdViewController *thirdViewController;
}

@property (nonatomic, retain) ThirdViewController *thirdViewController;

- (IBAction)switchToNextView;

@end
