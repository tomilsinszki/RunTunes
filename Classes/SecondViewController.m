//
//  SecondViewController.m
//  RunTunes
//
//  Created by Tamás Ilsinszki on 2/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SecondViewController.h"
#import "ThirdViewController.h"

@implementation SecondViewController

@synthesize thirdViewController;

- (void)viewDidLoad {
	[self setTitle:@""];
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)dealloc {
    [super dealloc];
}

- (IBAction)switchToNextView {
	if ( thirdViewController == nil ) {
		ThirdViewController *thirdController = [[ThirdViewController alloc]
												initWithNibName:@"ThirdView"
												bundle:nil];
		[self setThirdViewController:thirdController];
		[thirdController release];
	}
	
	[[self navigationController] pushViewController:thirdViewController animated:YES];	
}


@end
