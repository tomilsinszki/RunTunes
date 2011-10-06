//
//  TracklistViewController.m
//  RunTunes
//
//  Created by Tamás Ilsinszki on 9/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TracklistViewController.h"
#import "RunTunesAppDelegate.h"


@implementation TracklistViewController

@synthesize listData;
@synthesize managedObjectContext;

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

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

- (void)viewDidLoad
{
    NSArray *array = [[NSArray alloc] initWithObjects:@"Sleepy", @"Sneezy", @"Bashful", @"Happy", @"Doc", @"Grumpy", @"Dopey", @"Thorin", @"Dorin", @"Nori", @"Ori", @"Balin", @"Dwalin", @"Fili", @"Kili", @"Oin", @"Gloin", @"Bifur", @"Bombur", nil];
    [self setListData:array];
    [array release];
    
    managedObjectContext = [(RunTunesAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *userSettingsDescription = [NSEntityDescription entityForName:@"UserSettings"
                                                                  inManagedObjectContext:managedObjectContext];
    
    [request setEntity:userSettingsDescription];
    NSArray *userSettingsResults = [managedObjectContext executeFetchRequest:request 
                                                                          error:nil];
    
    NSManagedObject *userSettings = [userSettingsResults objectAtIndex:0];
    NSManagedObject *selectedPackage = [userSettings valueForKey:@"selectedPackage"];
    
    NSLog(@"Selected package: %@", [selectedPackage valueForKey:@"displayName"]);
    
    NSArray *mixes = [selectedPackage valueForKey:@"mixOfPackage"];
    NSEnumerator *mixEnumerator = [mixes objectEnumerator];
    NSManagedObject *mix;
    while (( mix = [mixEnumerator nextObject] )) {
        NSLog(@"Mix name: %@", [mix valueForKey:@"displayName"]);
        
        NSArray *tracks = [mix valueForKey:@"trackOfMix"];
        NSEnumerator *trackEnumerator = [tracks objectEnumerator];
        NSManagedObject *track;
        while (( track = [trackEnumerator nextObject] )) {
            NSLog(@"Track: %@", [track valueForKey:@"title"]);
        }
    }
    
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [listData release];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark Table View Data Source Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self listData] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *TracklistTableIdentifier = @"TracklistTableIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TracklistTableIdentifier];
    
    if ( cell == nil ) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TracklistTableIdentifier] autorelease];
    }
    
    NSUInteger row = [indexPath row];
    [[cell textLabel] setText:[listData objectAtIndex:row]];
    return cell;
}

@end
