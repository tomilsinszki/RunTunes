//
//  FirstViewController.m
//  RunTunes
//
//  Created by Tamás Ilsinszki on 2/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FirstViewController.h"
#import "SecondViewController.h"


@implementation FirstViewController

@synthesize runningMixNames;
@synthesize secondViewController;

- (void)viewDidLoad {
	[self setTitle:@"Running Mixes"];
	NSArray *mixNames = [[NSArray alloc] initWithObjects:@"RunTunes", nil];
	[self setRunningMixNames:mixNames];
	[mixNames release];
	[super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)dealloc {
	[runningMixNames release];
    [super dealloc];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[self runningMixNames] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *SimpleTableIdentifier = @"SimpleTableIdentifier";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SimpleTableIdentifier];
	
	if ( cell == nil ) {
		cell = [[[UITableViewCell alloc]
				 initWithStyle:UITableViewCellStyleDefault
				 reuseIdentifier:SimpleTableIdentifier] 
				autorelease];
	}
	
	UIImage *image = [UIImage imageNamed:@"mix.png"];
	[[cell imageView] setImage:image];
	
	NSUInteger row = [indexPath row];
	[[cell textLabel] setText:[runningMixNames objectAtIndex:row]];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if ( secondViewController == nil ) {
		SecondViewController *secondController = [[SecondViewController alloc]
												  initWithNibName:@"SecondView"
												  bundle:nil];
		[self setSecondViewController:secondController];
		[secondController release];
	}
	
	[[self navigationController] pushViewController:secondViewController animated:YES];
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
