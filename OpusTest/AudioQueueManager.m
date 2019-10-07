//
//  AudioQueueManager.m
//  OpusTest
//
//  Created by 周全营 on 2018/12/13.
//  Copyright © 2018 周全营. All rights reserved.
//

#import "AudioQueueManager.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "PCMFileManager.h"

#define QUEUE_BUFFER_SIZE 3      //输出音频队列缓冲个数
#define kDefaultBufferDurationSeconds 0.16      //调整这个值使得录音的缓冲区大小为5120,实际会小于或等于5120,需要处理小于5120的情况

static BOOL isRecording = NO;

@interface AudioQueueManager()<AVAudioRecorderDelegate>{
    AudioQueueRef _audioQueue;      //输出音频播放队列
    AudioStreamBasicDescription _recordFormat;// 声音格式设置
    AudioQueueBufferRef _audioBuffers[QUEUE_BUFFER_SIZE];      //输出音频缓存
}

@property (nonatomic,assign) RecordType currentTag;
@property (nonatomic,strong) AVAudioRecorder *voiceRecorder;
@property (nonatomic,strong) NSString *currentPath;

@end

@implementation AudioQueueManager

- (instancetype)initWithTage:(RecordType)tag{
    if (self = [super init]) {
        //如果录音时同时需要播放媒体，那么必须加上这两行代码
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        self.currentTag = tag;
        switch (_currentTag) {
            case RecordTypeAudioQueue:
                [self initWithAudioQueue];
                break;
            case RecordTypeAVAudioRecorder:
                [self initWithAVAudioRecorder];
                break;
            default:
                break;
        }
    }
    return self;
}

#pragma mark -
#pragma mark - <AudioQueue>
- (void)initWithAudioQueue{
    memset(&_recordFormat, 0, sizeof(_recordFormat));
    _recordFormat.mSampleRate = kDefaultSampleRate;
    _recordFormat.mChannelsPerFrame = 1;
    _recordFormat.mFormatID = kAudioFormatLinearPCM;
    _recordFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    _recordFormat.mBitsPerChannel = 16;
    _recordFormat.mBytesPerPacket = _recordFormat.mBytesPerFrame = (_recordFormat.mBitsPerChannel / 8) * _recordFormat.mChannelsPerFrame;
    _recordFormat.mFramesPerPacket = 1;
    //初始化音频输入队列
    AudioQueueNewInput(&_recordFormat, inputBufferHandler, (__bridge void *)(self), NULL, NULL, 0, &_audioQueue);
    //计算估算的缓存区大小
    int frames = (int)ceil(kDefaultBufferDurationSeconds * _recordFormat.mSampleRate);
    int bufferByteSize = frames * _recordFormat.mBytesPerFrame;
    
    //创建缓冲器
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++){
        AudioQueueAllocateBuffer(_audioQueue, bufferByteSize, &_audioBuffers[i]);
        AudioQueueEnqueueBuffer(_audioQueue, _audioBuffers[i], 0, NULL);
    }
}
void inputBufferHandler(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime,UInt32 inNumPackets, const AudioStreamPacketDescription *inPacketDesc){
    if (inNumPackets > 0) {
        AudioQueueManager *recorder = (__bridge AudioQueueManager*)inUserData;
        [recorder processAudioBuffer:inBuffer withQueue:inAQ];
    }
    if (isRecording) {
        AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    }
}

- (void)processAudioBuffer:(AudioQueueBufferRef)audioQueueBufferRef withQueue:(AudioQueueRef)audioQueueRef{
    NSMutableData *data = [NSMutableData dataWithBytes:audioQueueBufferRef->mAudioData length:audioQueueBufferRef->mAudioDataByteSize];
    if (data.length < 5120) { //处理长度小于定义长度问题的情况,此处是补00
        Byte byte[] = {0x00};
        NSData *zeroData = [[NSData alloc] initWithBytes:byte length:1];
        for (NSUInteger i = data.length; i < 5120; i++) {
            [data appendData:zeroData];
        }
    }
    if ([self.delegate respondsToSelector:@selector(returnData:)]) {
        [self.delegate returnData:data];
    }
}

#pragma mark -
#pragma mark - <AVAudioRecorder>
- (void)initWithAVAudioRecorder{
    NSMutableDictionary* recordSetting = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          [NSNumber numberWithFloat:16000], AVSampleRateKey,
                                          [NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,
                                          [NSNumber numberWithInt:1], AVNumberOfChannelsKey,
                                          [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
                                          [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                                          [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                          nil];
    self.currentPath = [NSString stringWithFormat:@"%@/%@",[PCMFileManager getVoicDocumentPaths],[NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"wav"]];
    NSURL *recordedTmpFile = [NSURL fileURLWithPath:_currentPath];
    self.voiceRecorder = [[AVAudioRecorder alloc] initWithURL:recordedTmpFile settings:recordSetting error:NULL];
    self.voiceRecorder.delegate = self;
    _voiceRecorder.meteringEnabled = YES;
    [_voiceRecorder prepareToRecord];
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    
}

#pragma mark -
#pragma mark - <开始录音>
- (void)startRecord{
    // 开始录音
    isRecording = YES;
    self.isRecording = YES;

    switch (_currentTag) {
        case RecordTypeAudioQueue:
            AudioQueueStart(_audioQueue, NULL);
            break;
        case RecordTypeAVAudioRecorder:
            [self.voiceRecorder record];
            break;
        default:
            break;
    }
}

#pragma mark -
#pragma mark - <停止录音>
- (void)stopRecord{
    if (isRecording){
        isRecording = NO;
        self.isRecording = NO;
        switch (_currentTag) {
            case RecordTypeAudioQueue:
            {
                //停止录音队列和移除缓冲区,以及关闭session，这里无需考虑成功与否
                AudioQueueStop(_audioQueue, true);
                //移除缓冲区,true代表立即结束录制，false代表将缓冲区处理完再结束
                AudioQueueDispose(_audioQueue, true);
            }
                break;
            case RecordTypeAVAudioRecorder:
            {
                [self.voiceRecorder stop];
                NSData *data = [NSData dataWithContentsOfFile:self.currentPath];
                if ([self.delegate respondsToSelector:@selector(returnData:)]) {
                    [self.delegate returnData:data];
                    [PCMFileManager deleteFileWithStr:self.currentPath];
                }
            }
                break;
            default:
                break;
        }
    }
}

- (void)dealloc {
    _audioQueue = nil;
    self.voiceRecorder.delegate = nil;
    self.voiceRecorder = nil;
}

@end
