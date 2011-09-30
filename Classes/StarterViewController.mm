//
//  StarterViewController.m
//  RunTunes
//
//  Created by Tamás Ilsinszki on 9/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StarterViewController.h"
#import "RunningViewController.h"
#import "TracklistViewController.h"

@implementation StarterViewController

@synthesize runningViewController;
@synthesize tracklistViewController;

- (IBAction)changeRunnningMixButtonPressed:(id)sender {
    UIAlertView *noOtherMixesNotice = [[UIAlertView alloc] 
                                       initWithTitle:@"Coming Soon" 
                                       message:@"More free and paid running mixes coming soon."
                                       delegate:self 
                                       cancelButtonTitle:@"I'll check back later."
                                       otherButtonTitles:nil];
    
    [noOtherMixesNotice show];
    [noOtherMixesNotice release];
}

- (IBAction)startRunningButtonPressed:(id)sender {
    if ( runningViewController == nil ) {
		RunningViewController *runningController = [[RunningViewController alloc]
                                                    initWithNibName:@"RunningView"
                                                    bundle:nil];
        [self setRunningViewController:runningController];
        [runningController release];
	}
    
    [[self navigationController] pushViewController:runningViewController animated:YES];
}

- (IBAction)tracklistButtonPressed:(id)sender {
    if ( tracklistViewController == nil ) {
		TracklistViewController *tracklistController = [[TracklistViewController alloc]
                                                        initWithNibName:@"TracklistView"
                                                        bundle:nil];
        [self setTracklistViewController:tracklistController];
        [tracklistController release];
	}
    
    [[self navigationController] pushViewController:tracklistViewController animated:YES];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [self setTitle:@"Running Mixes"];
    
    UIColor *backgroundImage = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"mainBackground.png"]];
    [[self view] setBackgroundColor:backgroundImage];
    [backgroundImage release];
    
    [[self navigationController] setNavigationBarHidden:YES];
    
    [super viewDidLoad];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
