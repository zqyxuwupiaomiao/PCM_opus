//
//  PCMPlayer.m
//  OpusTest
//
//  Created by 周全营 on 2019/7/29.
//  Copyright © 2019 周全营. All rights reserved.
//

#import "PCMPlayer.h"
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>
#import <assert.h>


#define INPUT_BUS 1
#define OUTPUT_BUS 0
#define CONST_BUFFER_SIZE 5120

@interface PCMPlayer()
{
    AudioUnit _audioUnit;
    AudioBufferList *_buffList;
    NSInputStream *_inputSteam;
}

@end

@implementation PCMPlayer

- (instancetype)init{
    if (self = [super init]) {
        OSStatus status = noErr;
        
        AudioComponentDescription audioDesc;
        audioDesc.componentType = kAudioUnitType_Output;
        audioDesc.componentSubType = kAudioUnitSubType_RemoteIO;
        audioDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
        audioDesc.componentFlags = 0;
        audioDesc.componentFlagsMask = 0;
        
        AudioComponent inputComponent = AudioComponentFindNext(NULL, &audioDesc);
        AudioComponentInstanceNew(inputComponent, &_audioUnit);
        
        // buffer
        _buffList = (AudioBufferList *)malloc(sizeof(AudioBufferList));
        _buffList->mNumberBuffers = 1;
        _buffList->mBuffers[0].mNumberChannels = 1;
        _buffList->mBuffers[0].mDataByteSize = CONST_BUFFER_SIZE;
        _buffList->mBuffers[0].mData = malloc(CONST_BUFFER_SIZE);
        
        //audio property
        UInt32 flag = 1;
        if (flag) {
            status = AudioUnitSetProperty(_audioUnit,
                                          kAudioOutputUnitProperty_EnableIO,
                                          kAudioUnitScope_Output,
                                          OUTPUT_BUS,
                                          &flag,
                                          sizeof(flag));
        }
        if (status) {
//            NSLog(@"AudioUnitSetProperty error with status:%d", status);
        }
        
        // format
        AudioStreamBasicDescription outputFormat;
        memset(&outputFormat, 0, sizeof(outputFormat));
        outputFormat.mSampleRate       = kDefaultSampleRate; // 采样率
        outputFormat.mFormatID         = kAudioFormatLinearPCM; // PCM格式
        outputFormat.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger; // 整形
        outputFormat.mFramesPerPacket  = 1; // 每帧只有1个packet
        outputFormat.mChannelsPerFrame = 1; // 声道数
        outputFormat.mBytesPerFrame    = 2; // 每帧只有2个byte 声道*位深*Packet数
        outputFormat.mBytesPerPacket   = 2; // 每个Packet只有2个byte
        outputFormat.mBitsPerChannel   = 16; // 位深
        //    [self printAudioStreamBasicDescription:outputFormat];
        
        status = AudioUnitSetProperty(_audioUnit,
                                      kAudioUnitProperty_StreamFormat,
                                      kAudioUnitScope_Input,
                                      OUTPUT_BUS,
                                      &outputFormat,
                                      sizeof(outputFormat));
        if (status) {
//            NSLog(@"AudioUnitSetProperty eror with status:%d", status);
        }
        
        // callback
        AURenderCallbackStruct playCallback1;
        playCallback1.inputProc = PlayCallback;
        playCallback1.inputProcRefCon = (__bridge void *)self;
        AudioUnitSetProperty(_audioUnit,
                             kAudioUnitProperty_SetRenderCallback,
                             kAudioUnitScope_Input,
                             OUTPUT_BUS,
                             &playCallback1,
                             sizeof(playCallback1));
        
        AudioUnitInitialize(_audioUnit);
    }
    return self;
}

- (void)playWithUrlStr:(NSString *)urlStr{
    // open pcm stream
    NSError *error = nil;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:&error];
    _inputSteam = [NSInputStream inputStreamWithFileAtPath:urlStr];
    if (!_inputSteam) {
//        NSLog(@"打开文件失败 %@", urlStr);
    }else {
        [_inputSteam open];
    }
    //kAudioFileStreamProperty_AudioDataByteCount
    AudioOutputUnitStart(_audioUnit);
}

static OSStatus PlayCallback(void *inRefCon,
                             AudioUnitRenderActionFlags *ioActionFlags,
                             const AudioTimeStamp *inTimeStamp,
                             UInt32 inBusNumber,
                             UInt32 inNumberFrames,
                             AudioBufferList *ioData) {
    PCMPlayer *player = (__bridge PCMPlayer *)inRefCon;
    
    ioData->mBuffers[0].mDataByteSize = (UInt32)[player->_inputSteam read:ioData->mBuffers[0].mData maxLength:(NSInteger)ioData->mBuffers[0].mDataByteSize];

    if (ioData->mBuffers[0].mDataByteSize <= 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [player stop];
        });
    }
    return noErr;
}


- (void)stop {
    AudioOutputUnitStop(_audioUnit);
    if (_buffList != NULL) {
        if (_buffList->mBuffers[0].mData) {
            free(_buffList->mBuffers[0].mData);
            _buffList->mBuffers[0].mData = NULL;
        }
        free(_buffList);
        _buffList = NULL;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayToEnd:)]) {
        __strong typeof (PCMPlayer) *player = self;
        [self.delegate onPlayToEnd:player];
    }
    
    [_inputSteam close];
}

- (void)printAudioStreamBasicDescription:(AudioStreamBasicDescription)asbd {
    char formatID[5];
    UInt32 mFormatID = CFSwapInt32HostToBig(asbd.mFormatID);
    bcopy (&mFormatID, formatID, 4);
    formatID[4] = '\0';
    printf("Sample Rate:         %10.0f\n",  asbd.mSampleRate);
    printf("Format ID:           %10s\n",    formatID);
    printf("Format Flags:        %10X\n",    (unsigned int)asbd.mFormatFlags);
    printf("Bytes per Packet:    %10d\n",    (unsigned int)asbd.mBytesPerPacket);
    printf("Frames per Packet:   %10d\n",    (unsigned int)asbd.mFramesPerPacket);
    printf("Bytes per Frame:     %10d\n",    (unsigned int)asbd.mBytesPerFrame);
    printf("Channels per Frame:  %10d\n",    (unsigned int)asbd.mChannelsPerFrame);
    printf("Bits per Channel:    %10d\n",    (unsigned int)asbd.mBitsPerChannel);
    printf("\n");
}

- (void)dealloc {
    AudioOutputUnitStop(_audioUnit);
    AudioUnitUninitialize(_audioUnit);
    AudioComponentInstanceDispose(_audioUnit);
    
    if (_buffList != NULL) {
        free(_buffList);
        _buffList = NULL;
    }
}

@end
