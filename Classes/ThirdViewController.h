//
//  ThirdViewController.h
//  RunTunes
//
//  Created by Tamás Ilsinszki on 2/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "AudioPlayer.h"
#import "AccelerationAnalyzer.h"


@interface ThirdViewController : UIViewController <UIAccelerometerDelegate> {
	NSInteger sampleSize;
	NSUInteger sampleCount;
	AccelerationAnalyzer *analyzer;
	AudioPlayer *audioPlayer;
}

@property (nonatomic, retain) AccelerationAnalyzer *analyzer;

@end
