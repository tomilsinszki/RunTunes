#import "AccelerationAnalyzer.h"
#import "OouraFFT.h"

@implementation AccelerationAnalyzer

- (id)init {
	if (( self = [super init] )) {
		numberOfSamples = 100;
		
		accelerations = [[CyclicArray alloc] initWithSize:numberOfSamples];
		timestamps = [[CyclicArray alloc] initWithSize:numberOfSamples];
	}
	return self;
}

/**
 * Initialize with maximum number of samples that can be store.
 *
 * Last updated: April 2010
 *
 * @param numberOfSamples Maximum number of samples.
 * @return AccelerationAnalyzer instance.
 */

- (id)initWithNumberOfSamples: (NSUInteger)_numberOfSamples {
	if (( self = [super init] )) {
		numberOfSamples = _numberOfSamples;
		
		accelerations = [[CyclicArray alloc] initWithSize:numberOfSamples];
		timestamps = [[CyclicArray alloc] initWithSize:numberOfSamples];
	}
	return self;
}

/**
 * Store sample.
 *
 * Last updated: August 2010
 *
 * @param acceleration Acceleration value.
 */
- (void)addSample: (double)magnitude atTime: (double)timestamp {
	[timestamps addObject:[NSNumber numberWithDouble:timestamp]];
	[accelerations addObject:[NSNumber numberWithDouble:magnitude]];
}

/**
 * Calculates dominant frequency for recently added samples to the sample's array.
 *
 * Last updated: August 2010
 *
 * @param numberSamples Number of recently added samples to take into consideration.
 * @return Dominant frequency.
 */
- (double)dominantFrequencyForRecentSamples: (NSUInteger)numberSamples {
	NSArray * sampleTimes = [timestamps getRecentlyAddedObjects:numberSamples];
	NSArray * samples = [accelerations getRecentlyAddedObjects:numberSamples];
	
	return [AccelerationAnalyzer dominantFrequencyOfTimestamps:sampleTimes
													andSamples:samples
											forNumberOfSamples:numberSamples
											   withinFrequency:1.85
												  andFrequency:3.0];
}

/**
 * Calculates magnitude from acceleration.
 *
 * Last updated: August 2010
 * 
 * @return Magnitude calculated from acceleration.
 */
+ (double)sampleFromAcceleration:(UIAcceleration *)acceleration {
	double x = [acceleration x];
	double y = [acceleration y];
	double z = [acceleration z];
	
	return sqrt(x*x + y*y + z*z);
}

/**
 * Calculates current sample time.
 *
 * Last updated: August 2010
 *
 * @return Current sample time.
 */
- (double)sampleTime {
	if ( firstSampleTime == 0 ) {
		firstSampleTime = [NSDate timeIntervalSinceReferenceDate];
	}
	NSTimeInterval currentSampleTime = [NSDate timeIntervalSinceReferenceDate];
	
	return currentSampleTime-firstSampleTime;
}

/**
 * Calculates dominant frequency of timestamped samples.
 *
 * Last updated: August 2010
 *
 * @param sampleTimes Timestamps with matching indexes for the samples.
 * @param samples
 * @param numberSamples Number of samples to analyze from the beginning of the sample set.
 * @param minimumFrequency Lower bound of frequency range to check for dominant frequency.
 * @param maximumFrequency Upper bound of frequency range to check for dominant frequency.
 * @return Frequency of samples (only useful for signals with a periodic nature).
 */
+ (double)dominantFrequencyOfTimestamps: (NSArray *)sampleTimes
							 andSamples: (NSArray *)samples
					 forNumberOfSamples: (NSInteger)numberSamples
						withinFrequency: (double)minimumFrequency
						   andFrequency: (double)maximumFrequency
{	
	OouraFFT *fft = [[OouraFFT alloc] initForSignalsOfLength:numberSamples andNumWindows:10];
	
	double samplingFrequency = [AccelerationAnalyzer samplingFrequencyOfTimestamps:sampleTimes];
	
	double *samplesInputData = (double *)malloc(numberSamples * sizeof(double));
	for (NSUInteger sampleIndex=0; sampleIndex<numberSamples; ++sampleIndex) {
		samplesInputData[sampleIndex] = [[samples objectAtIndex:sampleIndex] doubleValue];
	}
	
	[fft setInputData:samplesInputData];
	[fft calculateWelchPeriodogramWithNewSignalSegment];
	
	double maximumMagnitude = 0.0;
	double dominantFrequency = 0.0;
	
	for (NSUInteger spectrumDataIndex=0; spectrumDataIndex<[fft numFrequencies]; ++spectrumDataIndex) {
		double frequency = ((double)spectrumDataIndex * samplingFrequency) / (2.0 * (double)[fft numFrequencies]);
		double magnitude = fft.spectrumData[spectrumDataIndex];
		
		if ( minimumFrequency<frequency && frequency<maximumFrequency && maximumMagnitude<magnitude ) {
			maximumMagnitude = magnitude;
			dominantFrequency = frequency;
		}
	}
	
	[fft release];
	free(samplesInputData);
	return dominantFrequency;
}

/**
 * Averages sampling frequency of timestamps.
 *
 * Last updated: August 2010
 *
 * @param sampleTimes Sampling timestamps to analyze.
 * @return Average sampling frequency.
 */
+ (double)samplingFrequencyOfTimestamps: (NSArray *)sampleTimes {
	for (NSUInteger timestampIndex=1; timestampIndex<[sampleTimes count]; ++timestampIndex) {
		double timestamp1 = [[sampleTimes objectAtIndex:(timestampIndex-1)] doubleValue];
		double timestamp2 = [[sampleTimes objectAtIndex:(timestampIndex)] doubleValue];
		
		if ( (timestamp2-timestamp1)<0 || timestamp1<0 || timestamp2<0 ) return kIncorrectSamplingFrequency;
	}
	
	double firstTimestamp = [[sampleTimes objectAtIndex:0] doubleValue];
	double lastTimestamp = [[sampleTimes objectAtIndex:([sampleTimes count]-1)] doubleValue];
	
	double samplingDuration = lastTimestamp-firstTimestamp;
	double numberOfVoidsBetweenSamples = (double)[sampleTimes count]-1.0;
	
	if ( numberOfVoidsBetweenSamples < 1 ) return kIncorrectSamplingFrequency; 
	
	double averageSamplingTime = samplingDuration/numberOfVoidsBetweenSamples;
	
	if (averageSamplingTime == 0) return 0.0;
	
	return 1.0/averageSamplingTime;
}

@end
