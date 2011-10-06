//
//  RunningViewController.h
//  RunTunes
//
//  Created by Tamás Ilsinszki on 9/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioPlayer.h"
#import "AccelerationAnalyzer.h"


@interface RunningViewController : UIViewController <UIAccelerometerDelegate> {
	NSInteger sampleSize;
	NSUInteger sampleCount;
	AccelerationAnalyzer *analyzer;
	AudioPlayer *audioPlayer;
}

@property (nonatomic, retain) AccelerationAnalyzer *analyzer;

@end
