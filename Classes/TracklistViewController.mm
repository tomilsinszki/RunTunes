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
    NSEntityDescription *packageEntity = [NSEntityDescription entityForName:@"Package"
                                                     inManagedObjectContext:managedObjectContext];
    [request setEntity:packageEntity];
    NSArray *results = [managedObjectContext executeFetchRequest:request error:nil];
    
    NSEnumerator *enumerator = [results objectEnumerator];
    NSManagedObject *object;
    while (( object = [enumerator nextObject] )) {
        NSLog(@"Package name: %@", [object valueForKey:@"displayName"]);
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
