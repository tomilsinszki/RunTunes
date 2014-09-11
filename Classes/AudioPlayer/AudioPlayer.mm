#import "AudioPlayer.h"

const Float64 kGraphSampleRate = 44100.0;

@implementation AudioPlayer

@synthesize pitch;

static OSStatus renderInput(void *inRefCon, 
							AudioUnitRenderActionFlags *ioActionFlags, 
							const AudioTimeStamp *inTimeStamp, 
							UInt32 inBusNumber, 
							UInt32 inNumberFrames, 
							AudioBufferList *ioData) 
{
	OSStatus result = noErr;
	
	AudioPlayer *audioPlayer = (AudioPlayer *)inRefCon;
	AudioSampleType *leftChannelBuffer = (AudioSampleType *)ioData->mBuffers[0].mData;
	AudioSampleType *rightChannelBuffer = (AudioSampleType *)ioData->mBuffers[1].mData;
	
	AudioBufferList *currentBufferList = audioPlayer->buffer.currentBufferList;
	
	NSInteger frameIndexLastReadFromBuffer	= audioPlayer->buffer.currentFrameIndex;
	NSInteger numberOfFramesInBuffer = audioPlayer->buffer.numberOfFramesInCurrentBufferList;
	
	NSInteger offsetFrameIndex=0;
	for (NSInteger i=0; i<(NSInteger)inNumberFrames; ++i) {
		int currentFrameIndex = frameIndexLastReadFromBuffer+offsetFrameIndex;
		
		if ( currentFrameIndex == numberOfFramesInBuffer ) {
			
			BOOL isNextBufferReady = ( 0 < (audioPlayer->filledBufferCount-1) );
			if ( isNextBufferReady ) {
				audioPlayer->filledBufferCount -= 1;
				NSInteger bufferListIndex = (audioPlayer->lastPlayedBufferIndex+1) % kNumberOfBufferLists;
				audioPlayer->buffer.currentBufferList = [audioPlayer bufferListPointerByIndex:bufferListIndex];
				audioPlayer->buffer.numberOfFramesInCurrentBufferList = [audioPlayer frameCountForBufferListIndex:bufferListIndex];
				numberOfFramesInBuffer = audioPlayer->buffer.numberOfFramesInCurrentBufferList;
				currentBufferList = audioPlayer->buffer.currentBufferList;
				audioPlayer->lastPlayedBufferIndex = (audioPlayer->lastPlayedBufferIndex+1) % kNumberOfBufferLists;
				[audioPlayer triggerLastFilledBufferRefresh];
			}
			
			frameIndexLastReadFromBuffer = 0;
			offsetFrameIndex = 0;
			currentFrameIndex = frameIndexLastReadFromBuffer + offsetFrameIndex;
			audioPlayer->buffer.currentFrameIndex = 0;
		}
		
		int leftSampleIndex = 2*currentFrameIndex;
		int rightSampleIndex = 2*currentFrameIndex+1;
        
		leftChannelBuffer[i] = ((AudioSampleType *)currentBufferList->mBuffers[0].mData)[leftSampleIndex];
		rightChannelBuffer[i] = ((AudioSampleType *)currentBufferList->mBuffers[0].mData)[rightSampleIndex];
		
		++offsetFrameIndex;
	}
	
	audioPlayer->buffer.currentFrameIndex += offsetFrameIndex;
	
	return result;
}

- (id)init {
	if (( self = [super init] )) {
        [self resetAllBufferPositions];
		[self setUpPitchCorrection];
	}
	return self;
}

- (void)setUpPitchCorrection {
    pitch = 1.0;
	soundTouch = new SoundTouch();
	(*soundTouch).setSampleRate((uint)kGraphSampleRate);
	(*soundTouch).setChannels((uint)2);
	(*soundTouch).setPitch(1.0);
	(*soundTouch).setSetting(SETTING_USE_QUICKSEEK, TRUE);
    (*soundTouch).setSetting(SETTING_USE_AA_FILTER, FALSE);
}

- (void)setAudioFilePath: (NSString *)audioFilePath {
	CFURLRef sourceURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
													   (CFStringRef)audioFilePath,
													   kCFURLPOSIXPathStyle,
													   false);
	audioFileReader = [[AudioFileReader alloc] init];
	[audioFileReader setUpWithAudioFileURL:sourceURL];
	numberOfFramesRenderedAtOnce = [audioFileReader numberOfMaximumFramesRenderedAtOnce];
}

- (void)disposeAudioFileReader {
    [self stopPlayback];
    [audioFileReader disposeAudioQueue];
    [audioFileReader release];
}

- (SInt64)getFilePacketIndex {
    return [audioFileReader getCurrentPacketIndex];
}

- (void)setFilePacketIndex: (SInt64)packetIndex {
    [audioFileReader setCurrentPacketIndex:packetIndex];
}

- (void)triggerLastFilledBufferRefresh {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSThread detachNewThreadSelector:@selector(refreshLastFilledBuffer) toTarget:self withObject:nil];
	[pool release];
}

- (void)refreshLastFilledBuffer {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	while( [fillLastFilledBufferLock tryLock] == FALSE ) {
		[NSThread sleepForTimeInterval:0.005];
	}
	
	[self releaseLastFilledBuffer];
	[self fillLastFilledBufferWithNextPartFromAudioFile];
	
	[fillLastFilledBufferLock unlock];
	
	[pool release];
}

- (AudioBufferList *)bufferListPointerByIndex: (NSInteger)bufferListIndex {
	return buffer.bufferLists[bufferListIndex];
}

- (NSInteger)frameCountForBufferListIndex: (NSInteger)bufferListIndex {
	AudioBufferList *pBufferList = [self bufferListPointerByIndex:bufferListIndex];
	
	NSInteger bufferByteSize = (*pBufferList).mBuffers[0].mDataByteSize;
	NSInteger frameByteSize = 2*sizeof(AudioSampleType);
	
	return (bufferByteSize / frameByteSize);
}


- (void)resetAllBufferPositions {
    lastFilledBufferIndex = 0;
    lastPlayedBufferIndex = 0;
    lastPlayedFrameIndexInLastPlayedBuffer = 0;
    fillLastFilledBufferLock = [[NSLock alloc] init];
    filledBufferCount = 0;
}

- (void)setUpAllBuffers {
	[self initializeBufferLists];
	[self fillAllBuffersWithSubsequentPartsFromAudioFile];
	[self setInitialBufferState];
}

- (void)initializeBufferLists {
	NSInteger numberOfBuffersInBufferList = 1;
	size_t bufferListByteSize = offsetof(AudioBufferList, mBuffers) + (numberOfBuffersInBufferList * sizeof(AudioBuffer));
	
	for (NSInteger listIndex=0; listIndex<kNumberOfBufferLists; ++listIndex) {
		buffer.bufferLists[listIndex] = static_cast<AudioBufferList *>(calloc(1, bufferListByteSize));
		AudioBufferList bufferList = *buffer.bufferLists[listIndex];
		bufferList.mNumberBuffers = numberOfBuffersInBufferList;
	}
}

- (void)fillAllBuffersWithSubsequentPartsFromAudioFile {
	for(NSInteger bufferIndex=0; bufferIndex<kNumberOfBufferLists; ++bufferIndex) {
		[self fillLastFilledBufferWithNextPartFromAudioFile];
	}
}

- (void)setInitialBufferState {
	lastFilledBufferIndex = 0;
	buffer.currentBufferList = [self bufferListPointerByIndex:0];
	buffer.numberOfFramesInCurrentBufferList = [self frameCountForBufferListIndex:0];
}

- (void)releaseAllBuffers {
	for (NSInteger bufferIndex=0; bufferIndex<kNumberOfBufferLists; ++bufferIndex) {
		[self releaseLastFilledBuffer];
	}
}

- (void)releaseLastFilledBuffer {
	AudioBufferList *pBufferList = [self bufferListPointerByIndex:lastFilledBufferIndex];
	
	free((*pBufferList).mBuffers[0].mData);
	(*pBufferList).mBuffers[0].mDataByteSize = 0;
	(*pBufferList).mBuffers[0].mNumberChannels = 0;
}

- (void)initializeLastFilledBufferWithByteSize: (NSInteger)bufferByteSize {
	AudioBufferList *pBufferList = [self bufferListPointerByIndex:lastFilledBufferIndex];
	
	(*pBufferList).mBuffers[0].mData = static_cast<void *>(malloc(bufferByteSize));
	(*pBufferList).mBuffers[0].mDataByteSize = bufferByteSize;
	(*pBufferList).mBuffers[0].mNumberChannels = 1;
}

- (void)fillLastFilledBufferWithNextPartFromAudioFile {
	(*soundTouch).setPitch(pitch);
    
    AudioBuffer audioFileDataBuffer;
    AudioSampleType *audioFileData;
    NSInteger frameByteSize = 0;
    NSInteger audioFileDataFrameCount = 0;
    NSInteger pitchCorrectedFrameCount = 0;
    
    while ( pitchCorrectedFrameCount == 0 ) {
        audioFileDataBuffer = [audioFileReader render];
        audioFileData = (AudioSampleType *)audioFileDataBuffer.mData;
        frameByteSize = 2*sizeof(AudioSampleType);
        audioFileDataFrameCount = (NSInteger)(audioFileDataBuffer.mDataByteSize / frameByteSize);
        
        (*soundTouch).putSamples(audioFileData, audioFileDataFrameCount);
        
        pitchCorrectedFrameCount = (*soundTouch).numSamples();
    }
    
	AudioSampleType *pitchCorrectedBuffer = (AudioSampleType *)malloc(pitchCorrectedFrameCount*frameByteSize);
	
	(*soundTouch).receiveSamples((SAMPLETYPE *)pitchCorrectedBuffer, pitchCorrectedFrameCount);
	
	NSInteger lastFilledBufferByteSize = (pitchCorrectedFrameCount*frameByteSize);
	[self initializeLastFilledBufferWithByteSize:lastFilledBufferByteSize];
	AudioBufferList *pBufferList = [self bufferListPointerByIndex:lastFilledBufferIndex];
	AudioSampleType *pLastFilledBuffer = (AudioSampleType *)((*pBufferList).mBuffers[0].mData);
	memcpy(pLastFilledBuffer, pitchCorrectedBuffer, lastFilledBufferByteSize);
	lastFilledBufferIndex = (lastFilledBufferIndex+1)%kNumberOfBufferLists;
	
	++filledBufferCount;
	
	free(pitchCorrectedBuffer);
	free(audioFileDataBuffer.mData);
}

- (void)startPlayback {
	OSStatus errorStatus = noErr;
	errorStatus = AUGraphStart(audioGraph);
	NSAssert(errorStatus == noErr, @"Could not start audio graph.");
	[self setUpTempoChangerTimer];
}

- (void)setUpTempoChangerTimer {
	[NSTimer scheduledTimerWithTimeInterval:kSecondsToAdjustTempo
									 target:self
								   selector:@selector(applySmallTempoChange)
								   userInfo:nil
									repeats:YES];
}

- (void)stopPlayback {
	OSStatus errorStatus = noErr;
	Boolean isRunning = FALSE;
	
	errorStatus = AUGraphIsRunning(audioGraph, &isRunning);
	NSAssert(errorStatus == noErr, @"Could not verify if audio graph is running.");
	
	if ( isRunning == TRUE ) {
		errorStatus = AUGraphStop(audioGraph);
		NSAssert(errorStatus == noErr, @"Could not stop audio graph.");
	}
}

- (Boolean)isRunning {
	OSStatus errorStatus = noErr;
	Boolean isRunning = FALSE;
	
	errorStatus = AUGraphIsRunning(audioGraph, &isRunning);
	NSAssert(errorStatus == noErr, @"Could not verify if audio graph is running.");
	
	return isRunning;
}

- (void)setVolume:(Float32)volume {
	OSStatus errorStatus = noErr;
	
	errorStatus = AudioUnitSetParameter(mixerAudioUnit,
										k3DMixerParam_Gain,
										kAudioUnitScope_Output,
										0,
										volume,
										0);
	NSAssert(errorStatus == noErr, @"Could not set volume for mixer output.");
}

- (void)setPlaybackRate:(Float32)rate {
	OSStatus errorStatus = noErr;
	
	errorStatus = AudioUnitSetParameter(mixerAudioUnit,
										k3DMixerParam_PlaybackRate,
										kAudioUnitScope_Input,
										0,
										rate,
										0);
	NSAssert(errorStatus == noErr, @"Could not set playback rate for mixer output.");
	
	playbackRate = rate;
}

- (void)setTempo:(Float32)tempo {
	[self setPlaybackRate:tempo];
	pitch = (float)((Float32)1.0)/(tempo);
	[self setPitch:pitch];
}

- (void)setTempoImmediately:(Float32)tempo {
	if ( 0.0 < tempo ) {
		normativeTempo = tempo;
		[self setTempo:tempo];
	}
}

- (void)setTempoSlowly:(Float32)tempo {
	normativeTempo = tempo;
}

- (void)applySmallTempoChange {
	float currentTempo = playbackRate;
	float tempoChangeNeeded = normativeTempo - currentTempo;
		
	if ( 0 == fabsf(tempoChangeNeeded) )
		return;
	
	Float32 currentTempoChange;
	Float32 sign = ( 0.0 <= tempoChangeNeeded ) ? 1.0 : -1.0;
	
	if ( kMaximumTempoChangeAtOnce < fabsf(tempoChangeNeeded) )
		currentTempoChange = sign*kMaximumTempoChangeAtOnce;
	else
		currentTempoChange = tempoChangeNeeded;
	
	Float32 tempo = currentTempo+currentTempoChange;
	if ( 0.0 < tempo ) {
		[self setTempo:tempo];
	}
}

- (void)setUpPlayback {
	[self createAudioGraph];
	[self addIOAudioUnitToAudioGraph];
	[self addMixerAudioUnitToAudioGraph];
	[self connectUnitsAndOpenAudioGraph];
	[self setNumberOfBusesForMixerInput];
	[self setRenderCallbackForMixerInput];
	[self setAudioDescriptionForMixerInput];
	[self setAudioDescriptionForMixerOutput];
	[self setVolumeForMixerOutput];
	[self setPlaybackRate:1.0];
	normativeTempo = 1.0;
	[self initializeAudioGraph];
}

- (void)createAudioGraph {
	OSStatus errorStatus = noErr;
	errorStatus = NewAUGraph(&audioGraph);
	NSAssert(errorStatus == noErr, @"Could not create audio processing graph.");
}

- (void)addIOAudioUnitToAudioGraph {
	OSStatus errorStatus = noErr;
	
	AudioComponentDescription ioAudioNodeDescription;
	ioAudioNodeDescription.componentType = kAudioUnitType_Output;
	ioAudioNodeDescription.componentSubType = kAudioUnitSubType_RemoteIO;
	ioAudioNodeDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	ioAudioNodeDescription.componentFlags = 0;
	ioAudioNodeDescription.componentFlagsMask = 0;
	
	errorStatus = AUGraphAddNode(audioGraph, &ioAudioNodeDescription, &outputAudioNode);
	NSAssert(errorStatus == noErr, @"Could not add IO unit to audio graph.");
}

- (void)addMixerAudioUnitToAudioGraph {
	OSStatus errorStatus = noErr;
	
	AudioComponentDescription mixerAudioNodeDescription;
	mixerAudioNodeDescription.componentType = kAudioUnitType_Mixer;
	mixerAudioNodeDescription.componentSubType = kAudioUnitSubType_AU3DMixerEmbedded;
	mixerAudioNodeDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	mixerAudioNodeDescription.componentFlags = 0;
	mixerAudioNodeDescription.componentFlagsMask = 0;
	
	errorStatus = AUGraphAddNode(audioGraph, &mixerAudioNodeDescription, &mixerAudioNode);
	NSAssert(errorStatus == noErr, @"Could not add mixer unit to audio graph.");	
}

- (void)connectUnitsAndOpenAudioGraph {
	OSStatus errorStatus = noErr;
	
	errorStatus = AUGraphConnectNodeInput(audioGraph, mixerAudioNode, 0, outputAudioNode, 0);
	NSAssert(errorStatus == noErr, @"Could not connect mixer node and IO node.");
	
	errorStatus = AUGraphOpen(audioGraph);
	NSAssert(errorStatus == noErr, @"Could not open audio graph.");
	
	errorStatus = AUGraphNodeInfo(audioGraph, mixerAudioNode, NULL, &mixerAudioUnit);
	NSAssert(errorStatus == noErr, @"Could not set mixer unit.");
	
	errorStatus = AUGraphNodeInfo(audioGraph, outputAudioNode, NULL, &outputAudioUnit);
	NSAssert(errorStatus == noErr, @"Could not set output unit.");
}

- (void)setNumberOfBusesForMixerInput {
	OSStatus errorStatus = noErr;
	
	UInt32 numberOfBuses = 1;
	UInt32 numberOfBusesSize = sizeof(numberOfBuses);
	errorStatus = AudioUnitSetProperty(mixerAudioUnit,
									   kAudioUnitProperty_ElementCount,
									   kAudioUnitScope_Input,
									   0,
									   &numberOfBuses,
									   numberOfBusesSize);
	NSAssert(errorStatus == noErr, @"Could not set number of buses for mixer unit.");
}

- (void)setRenderCallbackForMixerInput {
	OSStatus errorStatus = noErr;
	
	AURenderCallbackStruct renderCallbackStruct;
	renderCallbackStruct.inputProc = &renderInput;
	renderCallbackStruct.inputProcRefCon = self;
	
	errorStatus = AUGraphSetNodeInputCallback(audioGraph, mixerAudioNode, 0, &renderCallbackStruct);
	NSAssert(errorStatus == noErr, @"Could not set mixer input callback function.");
}

- (void)setAudioDescriptionForMixerInput {
	OSStatus errorStatus = noErr;
	
	CAStreamBasicDescription audioDescription;
	UInt32 audioDescriptionSize = sizeof(audioDescription);
	errorStatus = AudioUnitGetProperty(mixerAudioUnit,
									   kAudioUnitProperty_StreamFormat,
									   kAudioUnitScope_Input,
									   0,
									   &audioDescription,
									   &audioDescriptionSize);
	NSAssert(errorStatus == noErr, @"Could not get audio format.");
	
	memset(&audioDescription, 0, sizeof(audioDescription));
	
	audioDescription.mSampleRate = kGraphSampleRate;
	audioDescription.mFormatID = kAudioFormatLinearPCM;
	audioDescription.mFormatFlags = kAudioFormatFlagIsSignedInteger | 
									kAudioFormatFlagsNativeEndian | 
									kLinearPCMFormatFlagIsNonInterleaved;
	audioDescription.mBitsPerChannel = sizeof(AudioSampleType) * 8;
	audioDescription.mChannelsPerFrame = 1;
	audioDescription.mFramesPerPacket = 1;
	audioDescription.mBytesPerFrame = (audioDescription.mBitsPerChannel/8) * audioDescription.mChannelsPerFrame;
	audioDescription.mBytesPerPacket = audioDescription.mBytesPerFrame * audioDescription.mFramesPerPacket;
	audioDescription.ChangeNumberChannels(2, FALSE);
	
	errorStatus = AudioUnitSetProperty(mixerAudioUnit,
									   kAudioUnitProperty_StreamFormat,
									   kAudioUnitScope_Input,
									   0,
									   &audioDescription,
									   sizeof(audioDescription));
	NSAssert(errorStatus == noErr, @"Could not set audio format for mixer input.");
}

- (void)setAudioDescriptionForMixerOutput {
	OSStatus errorStatus = noErr;
	
	CAStreamBasicDescription audioDescriptionMixerOutput;
	UInt32 audioDescriptionMixerOutputSize = sizeof(audioDescriptionMixerOutput);
	errorStatus = AudioUnitGetProperty(mixerAudioUnit,
									   kAudioUnitProperty_StreamFormat,
									   kAudioUnitScope_Output,
									   0,
									   &audioDescriptionMixerOutput,
									   &audioDescriptionMixerOutputSize);
	NSAssert(errorStatus == noErr, @"Could not get audio format for mixer output.");
	
	audioDescriptionMixerOutput.mSampleRate = kGraphSampleRate;
	
	errorStatus = AudioUnitSetProperty(mixerAudioUnit,
									   kAudioUnitProperty_StreamFormat,
									   kAudioUnitScope_Output,
									   0,
									   &audioDescriptionMixerOutput,
									   audioDescriptionMixerOutputSize);
	NSAssert(errorStatus == noErr, @"Could not set audio format for mixer output.");	
}

- (void)setVolumeForMixerOutput {
	OSStatus errorStatus = noErr;
	
	Float32 volume = 0.0;
	errorStatus = AudioUnitSetParameter(mixerAudioUnit,
										k3DMixerParam_Gain,
										kAudioUnitScope_Output,
										0,
										volume,
										0);
	NSAssert(errorStatus == noErr, @"Could not set volume for mixer output.");	
}

- (void)initializeAudioGraph {
	OSStatus errorStatus = noErr;
	
	errorStatus = AUGraphInitialize(audioGraph);
	NSAssert(errorStatus == noErr, @"Could not initialize audio graph.");	
}

- (void)dealloc {
	DisposeAUGraph(audioGraph);
	[super dealloc];
}

@end
