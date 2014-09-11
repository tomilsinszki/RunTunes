#define kNumberOfBufferLists 3
#define kMaximumTempoChangeAtOnce 0.006
#define kSecondsToAdjustTempo 0.5
#define INTEGER_SAMPLES 1
#define _WINDEF_ 1

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SoundTouch.h"
#import "CAStreamBasicDescription.h"
#import "AudioFileReader.h"

using namespace soundtouch;

typedef struct {
	AudioBufferList *bufferLists[kNumberOfBufferLists];
	AudioBufferList *currentBufferList;
	NSInteger currentFrameIndex;
	NSInteger numberOfFramesInCurrentBufferList;
} Buffer;

@interface AudioPlayer : NSObject {
	Buffer buffer;
	
	NSInteger lastPlayedBufferIndex;
	NSInteger lastPlayedFrameIndexInLastPlayedBuffer;
	NSInteger lastFilledBufferIndex;
	NSInteger filledBufferCount;
	
	AUGraph audioGraph;
	AUNode outputAudioNode;
	AudioUnit outputAudioUnit;
	AUNode mixerAudioNode;
	AudioUnit mixerAudioUnit;
	
	AudioFileReader *audioFileReader;
	NSInteger numberOfFramesRenderedAtOnce;
	
	SoundTouch *soundTouch;
	NSLock *fillLastFilledBufferLock;
	float pitch;
	float playbackRate;
	float normativeTempo;
}

@property (nonatomic) float pitch;

- (id)init;

- (void)setUpPitchCorrection;
- (void)setAudioFilePath: (NSString *)audioFilePath;
- (void)disposeAudioFileReader;

- (SInt64)getFilePacketIndex;
- (void)setFilePacketIndex: (SInt64)packetIndex;

- (void)resetAllBufferPositions;
- (void)setUpAllBuffers;
- (void)initializeBufferLists;
- (void)fillAllBuffersWithSubsequentPartsFromAudioFile;
- (void)setInitialBufferState;
- (void)releaseAllBuffers;
- (void)releaseLastFilledBuffer;
- (void)initializeLastFilledBufferWithByteSize: (NSInteger)bufferByteSize;
- (void)fillLastFilledBufferWithNextPartFromAudioFile;
- (void)triggerLastFilledBufferRefresh;
- (void)refreshLastFilledBuffer;
- (AudioBufferList *)bufferListPointerByIndex: (NSInteger)bufferListIndex;
- (NSInteger)frameCountForBufferListIndex: (NSInteger)bufferIndex;

- (void)startPlayback;
- (void)stopPlayback;
- (Boolean)isRunning;
- (void)setVolume:(Float32)volume;
- (void)setPlaybackRate:(Float32)rate;
- (void)setTempo:(Float32)tempo;
- (void)setTempoImmediately:(Float32)tempo;
- (void)setTempoSlowly:(Float32)tempo;
- (void)applySmallTempoChange;
- (void)setUpTempoChangerTimer;

- (void)setUpPlayback;
- (void)createAudioGraph;
- (void)addIOAudioUnitToAudioGraph;
- (void)addMixerAudioUnitToAudioGraph;
- (void)connectUnitsAndOpenAudioGraph;
- (void)setNumberOfBusesForMixerInput;
- (void)setRenderCallbackForMixerInput;
- (void)setAudioDescriptionForMixerInput;
- (void)setAudioDescriptionForMixerOutput;
- (void)setVolumeForMixerOutput;
- (void)initializeAudioGraph;

@end
