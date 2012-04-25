//
//  RunningViewController.m
//  RunTunes
//
//  Created by Tamás Ilsinszki on 9/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RunningViewController.h"


@implementation RunningViewController

@synthesize analyzer;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc {
    [audioPlayer release];
	[analyzer release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    UIColor *backgroundImage = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"runningBackground.png"]];
    [[self view] setBackgroundColor:backgroundImage];
    [backgroundImage release];
    
    sampleSize = 512;
	sampleCount = 0;
	
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];                                                                                                          
    
	UIAccelerometer *accelerometer = [UIAccelerometer sharedAccelerometer];                                                                                                
	[accelerometer setDelegate:self];                                                                                                                                      
	[accelerometer setUpdateInterval:0.01];                                                                                                                                
    
	AccelerationAnalyzer *currentAnalyzer = [[AccelerationAnalyzer alloc] initWithNumberOfSamples:sampleSize];                                                             
	[self setAnalyzer:currentAnalyzer];      
    
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    
	audioPlayer = [[AudioPlayer alloc] init];
	[audioPlayer setUpPlayback];
	NSString *audioFilePath = [[NSBundle mainBundle] pathForResource:@"135bpm" ofType:@"mp4"];
	[audioPlayer setAudioFilePath:audioFilePath];
	[audioPlayer setUpAllBuffers];
    
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {                                                                          
	double sample = [AccelerationAnalyzer sampleFromAcceleration:acceleration];                                                                                            
	double sampleTime = [analyzer sampleTime];                                                                                                                             
	
	[analyzer addSample:sample atTime:sampleTime];                                                                                                                         
	
	if ( (sampleCount >= sampleSize) && (sampleCount % sampleSize == 0) ) {                                                                                                
		double frequency  = [analyzer dominantFrequencyForRecentSamples:sampleSize];                                                                                   
		double stepsPerMinute = frequency * 60.0;                                                                                                                      
		
		Float32 tempo = (Float32)stepsPerMinute / (Float32)135.0;                                                                                                
		tempo = ( tempo < 0.5 ) ? 0.5 : tempo;                                                                                                                         
		tempo = ( 2.0 < tempo ) ? 2.0 : tempo;                                                                                                                         
		
		if ( [audioPlayer isRunning] == FALSE ) {     
			[audioPlayer startPlayback];                                                                                                                           
			[audioPlayer setTempoImmediately:tempo];                                                                                                               
		}                                                                                                                                                              
		else {                                                                                                                                                         
			[audioPlayer setTempoSlowly:tempo];                                                                                                                    
		}                                                                                                                                                              
	}                                                                                                                                                                      
	
	++sampleCount;                                                                                                                                                         
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
