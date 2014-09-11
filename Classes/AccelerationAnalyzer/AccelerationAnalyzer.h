#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "CyclicArray.h"

#define kIncorrectSamplingFrequency -1.0

@interface AccelerationAnalyzer : NSObject {
	NSUInteger numberOfSamples;			// Maximum number of samples stored
	CyclicArray * accelerations;		// Acceleration values
	CyclicArray * timestamps;			// Time of sample in milliseconds since first time sample added
	NSTimeInterval firstSampleTime;		// Time of first sample in milliseconds
}

- (id)init;

- (id)initWithNumberOfSamples: (NSUInteger)_numberOfSamples;

- (void)addSample: (double)magnitude atTime: (double)timestamp;

- (double)dominantFrequencyForRecentSamples: (NSUInteger)numberSamples;

+ (double)sampleFromAcceleration:(UIAcceleration *)acceleration;

- (double)sampleTime;

+ (double)dominantFrequencyOfTimestamps: (NSArray *)sampleTimes
							 andSamples: (NSArray *)samples
					 forNumberOfSamples: (NSInteger)numberSamples
							withinFrequency: (double)minimumFrequency
						   andFrequency: (double)maximumFrequency;

+ (double)samplingFrequencyOfTimestamps: (NSArray *)sampleTimes;

@end
