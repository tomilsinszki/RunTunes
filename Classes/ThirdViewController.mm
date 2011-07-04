//
//  ThirdViewController.m
//  RunTunes
//
//  Created by Tamás Ilsinszki on 2/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ThirdViewController.h"


@implementation ThirdViewController

@synthesize analyzer;

- (void)viewDidLoad {                                                                                                                                                          
	[[self navigationController] setNavigationBarHidden:YES];
	
	sampleSize = 512;                                                                                                                                                      
	sampleCount = 0;                                                                                                                                                       
	
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];                                                                                                          
																																										
	UIAccelerometer *accelerometer = [UIAccelerometer sharedAccelerometer];                                                                                                
	[accelerometer setDelegate:self];                                                                                                                                      
	[accelerometer setUpdateInterval:0.01];                                                                                                                                
																																										
	AccelerationAnalyzer *currentAnalyzer = [[AccelerationAnalyzer alloc] initWithNumberOfSamples:sampleSize];                                                             
	[self setAnalyzer:currentAnalyzer];                                                                                                                                    
																																										
	audioPlayer = [[AudioPlayer alloc] init];                                                                                                                              
	[audioPlayer setUpPlayback];                                                                                                                                           
	NSString *audioFilePath = [[NSBundle mainBundle] pathForResource:@"140bpm (range 135-150)" ofType:@"mp4"];                                                                        
	[audioPlayer setAudioFilePath:audioFilePath];                                                                                                                          
	[audioPlayer setUpAllBuffers];                                                                                                                                         
	
    [super viewDidLoad];                                                                                                                                                       
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {                                                                          
	double sample = [AccelerationAnalyzer sampleFromAcceleration:acceleration];                                                                                            
	double sampleTime = [analyzer sampleTime];                                                                                                                             
	
	[analyzer addSample:sample atTime:sampleTime];                                                                                                                         
	
	if ( (sampleCount >= sampleSize) && (sampleCount % sampleSize == 0) ) {                                                                                                
		double frequency  = [analyzer dominantFrequencyForRecentSamples:sampleSize];                                                                                   
		double stepsPerMinute = frequency * 60.0;                                                                                                                      
		
		Float32 tempo = (Float32)stepsPerMinute / (Float32)140.0;                                                                                                
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

- (void)dealloc {
	[audioPlayer release];
	[analyzer release];
    [super dealloc];
}

@end
