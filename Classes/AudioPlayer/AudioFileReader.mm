#import "AudioFileReader.h"

@implementation AudioFileReader

static void renderInputCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inCompleteAQBuffer) {
	OSStatus errorStatus = noErr;
	RendererState *pRendererState = (RendererState *)inUserData;
	if ( (*pRendererState).isDone ) return;
	
	UInt32 numberOfBytesReturned;
	UInt32 numberOfPacketsToReadAtOnce = (*pRendererState).numberOfPacketsToReadAtOnce;
	errorStatus = AudioFileReadPackets((*pRendererState).audioFile,
									   false,
									   &numberOfBytesReturned,
									   (*pRendererState).pPacketDescription,
									   (*pRendererState).currentPacketIndex,
									   &numberOfPacketsToReadAtOnce,
									   (*inCompleteAQBuffer).mAudioData);
	
	if ( errorStatus != noErr ) {
		DebugMessageN1 ("Error reading from file: %d\n", (int)errorStatus);
		exit(1);
	}
    
	if ( 0 < numberOfPacketsToReadAtOnce ) {
		inCompleteAQBuffer->mAudioDataByteSize = numberOfBytesReturned;
        
		errorStatus = AudioQueueEnqueueBuffer(inAQ,
                                         inCompleteAQBuffer,
                                         ( (*pRendererState).pPacketDescription ? numberOfPacketsToReadAtOnce : 0 ),
                                         (*pRendererState).pPacketDescription);
		if ( errorStatus != noErr ) {
			DebugMessageN1 ("Error enqueuing buffer: %d\n", (int)errorStatus);
			exit(1);
		}
        
		(*pRendererState).currentPacketIndex += numberOfPacketsToReadAtOnce;
        
	} else {
		if ( !(*pRendererState).hasBeenFlushed ) {
			errorStatus = AudioQueueFlush((*pRendererState).audioQueue);
			
            if ( errorStatus != noErr ) {
				DebugMessageN1("AudioQueue could not be flushed: %d", (int)errorStatus);
				exit(1);
			}
            
			(*pRendererState).hasBeenFlushed = true;
		}
		
		errorStatus = AudioQueueStop((*pRendererState).audioQueue, false);
		if ( errorStatus != noErr ) {
			DebugMessageN1("AudioQueueStop(false) failed: %d", (int)errorStatus);
			exit(1);
		}
        
		(*pRendererState).isDone = true;
	}	
}

- (id)init {
	if (( self = [super init] )) {
		rendererState.isDone = false;
		rendererState.hasBeenFlushed = false;
		rendererState.currentPacketIndex= 0;
		channelLayout = NULL;
	}
	return self;	
}

- (void)setUpWithAudioFileURL: (CFURLRef)fileURL {
	audioFileURL = fileURL;
	[self openAudioFile];
	[self determineAudioFileFormat];
	[self createPlaybackAudioQueue];
	[self determineMaximumFramesToRenderAtOnce];
	[self tryToUseMagicCookie];
	[self determineChannelLayout];
	[self allocateRenderInputBuffer];
	[self setOutputFormat];
	[self allocateRenderOutputBuffer];
	[self startAudioQueue];
}

- (void)openAudioFile {
	OSStatus errorStatus = noErr;
	
	errorStatus = AudioFileOpenURL(audioFileURL,
								   kAudioFileReadPermission,
								   0,
								   &rendererState.audioFile);
	NSAssert(errorStatus == noErr, @"Could not open audio file.");
}

- (void)determineAudioFileFormat {
	OSStatus errorStatus = noErr;
	
	UInt32 propertySize = sizeof(rendererState.audioFormat);
	errorStatus = AudioFileGetProperty(rendererState.audioFile,
									   kAudioFilePropertyDataFormat,
									   &propertySize,
									   &rendererState.audioFormat);
	NSAssert(errorStatus == noErr, @"Could not get audio file format.");
}

- (void)createPlaybackAudioQueue {
	OSStatus errorStatus = noErr;
	
	errorStatus = AudioQueueNewOutput(&rendererState.audioFormat,
									  renderInputCallback,
									  &rendererState,
									  CFRunLoopGetCurrent(),
									  kCFRunLoopCommonModes,
									  0,
									  &rendererState.audioQueue);
	NSAssert(errorStatus == noErr, @"Could not create playback audio queue.");
}

- (void)determineMaximumFramesToRenderAtOnce {
	OSStatus errorStatus = noErr;
	
	UInt32 maxPacketSize;
	UInt32 size = sizeof(maxPacketSize);
	errorStatus = AudioFileGetProperty(rendererState.audioFile,
									   kAudioFilePropertyPacketSizeUpperBound,
									   &size,
									   &maxPacketSize);
	NSAssert(errorStatus == noErr, @"Could not get maximum packet size from audio file.");
	
	renderInputBufferByteSize = kRenderInputBufferByteSize;
	rendererState.numberOfPacketsToReadAtOnce = renderInputBufferByteSize / maxPacketSize;
	
	if ( [self isFormatOfVariableBitrate] ) {
		rendererState.pPacketDescription = new AudioStreamPacketDescription[rendererState.numberOfPacketsToReadAtOnce];
	} else {
		rendererState.pPacketDescription = NULL;
	}
}

- (bool)isFormatOfVariableBitrate {
	bool isZeroBytesPerPacket = ( rendererState.audioFormat.mBytesPerPacket == 0 );
	bool isZeroFramesPerPacket = ( rendererState.audioFormat.mFramesPerPacket == 0 );
	return ( isZeroBytesPerPacket || isZeroFramesPerPacket );
}

- (void)tryToUseMagicCookie { 
	[self getMagicCookieSizeForFile];
	if ( 0 < magicCookieSize ) {
		[self getMagicCookieForFile];
		[self setMagicCookieForAudioQueue];
		[self deallocMagicCookie];
	}
}

- (void)getMagicCookieSizeForFile {
	UInt32 size = sizeof(UInt32);
	OSStatus result = AudioFileGetPropertyInfo(rendererState.audioFile,
											   kAudioFilePropertyMagicCookieData,
											   &size,
											   NULL);
	if ( !result && size ) {
		magicCookieSize = size;
	}
	else {
		magicCookie = 0;
	}
}

- (void)getMagicCookieForFile {
	OSStatus errorStatus = noErr;
	
	magicCookie = new char[magicCookieSize];
	errorStatus = AudioFileGetProperty (rendererState.audioFile,
										kAudioFilePropertyMagicCookieData,
										&magicCookieSize,
										magicCookie);
	NSAssert(errorStatus == noErr, @"Could not get magic cookie from audio file.");
}

- (void)setMagicCookieForAudioQueue {
	OSStatus errorStatus = noErr;
	
	errorStatus = AudioQueueSetProperty(rendererState.audioQueue,
										kAudioQueueProperty_MagicCookie,
										magicCookie,
										magicCookieSize);
	NSAssert(errorStatus == noErr, @"Could not set magic cookie for audio queue.");	
}

- (void)deallocMagicCookie {
	delete[] magicCookie;
}

- (void)determineChannelLayout {
	[self getChannelLayoutSizeForFile];
	if ( 0 < channelLayoutSize ) {
		[self getChannelLayoutForFile];
		[self setChannelLayoutForAudioQueue];
	}
}

- (void)getChannelLayoutSizeForFile {
	UInt32 size = sizeof(UInt32);
	
	OSStatus result = AudioFileGetPropertyInfo(rendererState.audioFile,
											   kAudioFilePropertyChannelLayout,
											   &size,
											   NULL);
	
	if ( !result && size > 0) {
		channelLayoutSize = size;
	}
	else {
		channelLayout = 0;
	}
}

- (void)getChannelLayoutForFile {
	OSStatus errorStatus = noErr;
	channelLayout = (AudioChannelLayout *)malloc(channelLayoutSize);
	
	errorStatus = AudioFileGetProperty(rendererState.audioFile,
									   kAudioFilePropertyChannelLayout,
									   &channelLayoutSize,
									   channelLayout);
	NSAssert(errorStatus == noErr, @"Could not get channel layout from audio file.");	
}

- (void)setChannelLayoutForAudioQueue {
	OSStatus errorStatus = noErr;
	errorStatus = AudioQueueSetProperty(rendererState.audioQueue,
										kAudioQueueProperty_ChannelLayout,
										channelLayout,
										channelLayoutSize);
	NSAssert(errorStatus == noErr, @"Could not set channel layout for audio queue.");
}

- (void)allocateRenderInputBuffer {
	OSStatus errorStatus = noErr;
	
	errorStatus = AudioQueueAllocateBuffer(rendererState.audioQueue,
										   renderInputBufferByteSize,
										   &rendererState.inputBuffer);
	NSAssert(errorStatus == noErr, @"Could not allocate bufer for the audio queue.");
}

- (void)setOutputFormat {
	renderOutputFormat.mSampleRate = rendererState.audioFormat.mSampleRate;
	renderOutputFormat.SetCanonical(rendererState.audioFormat.mChannelsPerFrame, true);
	
	OSStatus errorStatus = noErr;		
	errorStatus = AudioQueueSetOfflineRenderFormat(rendererState.audioQueue,
												   &renderOutputFormat,
												   channelLayout);
	NSAssert(errorStatus == noErr, @"Could not set offline render format for audio queue.");	
}

- (void)allocateRenderOutputBuffer {
	renderOutputBufferByteSize = renderInputBufferByteSize / 2;
	
	OSStatus errorStatus = noErr;
	errorStatus = AudioQueueAllocateBuffer(rendererState.audioQueue,
										   renderOutputBufferByteSize,
										   &renderOutputBuffer);
	NSAssert(errorStatus == noErr, @"Audio queue could not allocate capture buffer.");
	
	renderOutputBufferList.mNumberBuffers = 1;
	renderOutputBufferList.mBuffers[0].mData = (*renderOutputBuffer).mAudioData;
	renderOutputBufferList.mBuffers[0].mNumberChannels = renderOutputFormat.mChannelsPerFrame;
}

- (void)startAudioQueue {
	OSStatus errorStatus = noErr;
	
	errorStatus = AudioQueueStart(rendererState.audioQueue,
								  NULL);
	NSAssert(errorStatus == noErr, @"Could not start audio queue.");
	
	startNextRenderingFromTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
	startNextRenderingFromTimeStamp.mSampleTime = 0;
	
	errorStatus = AudioQueueOfflineRender(rendererState.audioQueue,
										  &startNextRenderingFromTimeStamp,
										  renderOutputBuffer,
										  0);
	NSAssert(errorStatus == noErr, @"Could not call first time rendering with 0 frames.");
	
	renderInputCallback(&rendererState, rendererState.audioQueue, rendererState.inputBuffer);
}

- (void)disposeAudioQueue {
    AudioQueueStop(rendererState.audioQueue, TRUE);
    AudioQueueDispose(rendererState.audioQueue, TRUE);
    free(channelLayout);
}

- (NSInteger)numberOfMaximumFramesRenderedAtOnce {
	return (NSInteger)(renderOutputBufferByteSize / renderOutputFormat.mBytesPerFrame);
}

- (AudioBuffer)render {
	OSStatus errorStatus = noErr;
	AudioBuffer renderedBuffer;
	
	UInt32 requestedFrameCount = (UInt32)[self numberOfMaximumFramesRenderedAtOnce];
	
	errorStatus = AudioQueueOfflineRender(rendererState.audioQueue,
										  &startNextRenderingFromTimeStamp,
										  renderOutputBuffer,
										  requestedFrameCount);
	NSAssert(errorStatus == noErr, @"Audio queue could not render audio buffer.");
    
	renderOutputBufferList.mBuffers[0].mData = renderOutputBuffer->mAudioData;
	renderOutputBufferList.mBuffers[0].mDataByteSize = renderOutputBuffer->mAudioDataByteSize;
	
	renderedBuffer.mDataByteSize = renderOutputBuffer->mAudioDataByteSize;
	renderedBuffer.mData = (void *)malloc(renderedBuffer.mDataByteSize);
	memcpy(renderedBuffer.mData, renderOutputBuffer->mAudioData, renderedBuffer.mDataByteSize);
	
	UInt32 renderedFrameCount = renderOutputBufferList.mBuffers[0].mDataByteSize / renderOutputFormat.mBytesPerFrame;
	startNextRenderingFromTimeStamp.mSampleTime += renderedFrameCount;
    
	return renderedBuffer;
}

- (SInt64)getCurrentPacketIndex {
    return rendererState.currentPacketIndex;
}

- (void)setCurrentPacketIndex: (SInt64)currentPacketIndex {
    rendererState.currentPacketIndex = currentPacketIndex;
}

@end
