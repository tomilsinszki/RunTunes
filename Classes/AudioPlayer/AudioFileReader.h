#define kRenderInputBufferByteSize 100000

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioQueue.h>
#import <AudioToolbox/AudioFile.h>
#import <AudioToolbox/ExtendedAudioFile.h>
#import "CAStreamBasicDescription.h"

struct RendererState {
	AudioFileID audioFile;
	CAStreamBasicDescription audioFormat;
	AudioQueueRef audioQueue;
	AudioQueueBufferRef inputBuffer;
	SInt64 currentPacketIndex;
	UInt32 numberOfPacketsToReadAtOnce;
	AudioStreamPacketDescription *pPacketDescription;
	bool hasBeenFlushed;
	bool isDone;
};

@interface AudioFileReader : NSObject {
	RendererState rendererState;
	CFURLRef audioFileURL;
	UInt32 magicCookieSize;
	char *magicCookie;
	UInt32 channelLayoutSize;
	AudioChannelLayout *channelLayout;
	UInt32 renderInputBufferByteSize;
	UInt32 renderOutputBufferByteSize;
	CAStreamBasicDescription renderOutputFormat;
	AudioQueueBufferRef renderOutputBuffer;
	AudioBufferList renderOutputBufferList;
	AudioTimeStamp startNextRenderingFromTimeStamp;
}

- (id)init;

- (void)setUpWithAudioFileURL: (CFURLRef)fileURL;
- (void)openAudioFile;
- (void)determineAudioFileFormat;
- (void)createPlaybackAudioQueue;
- (void)determineMaximumFramesToRenderAtOnce;
- (bool)isFormatOfVariableBitrate;

- (void)tryToUseMagicCookie;
- (void)getMagicCookieSizeForFile;
- (void)getMagicCookieForFile;
- (void)setMagicCookieForAudioQueue;
- (void)deallocMagicCookie;

- (void)determineChannelLayout;
- (void)getChannelLayoutSizeForFile;
- (void)getChannelLayoutForFile;
- (void)setChannelLayoutForAudioQueue;

- (void)allocateRenderInputBuffer;
- (void)setOutputFormat;
- (void)allocateRenderOutputBuffer;
- (void)startAudioQueue;
- (void)disposeAudioQueue;

- (SInt64)getCurrentPacketIndex;
- (void)setCurrentPacketIndex: (SInt64)currentPacketIndex;

- (NSInteger)numberOfMaximumFramesRenderedAtOnce;
- (AudioBuffer)render;

@end
