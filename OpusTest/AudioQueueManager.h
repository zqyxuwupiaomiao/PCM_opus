//
//  AudioQueueManager.h
//  OpusTest
//
//  Created by 周全营 on 2018/12/13.
//  Copyright © 2018 周全营. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, RecordType) {
    RecordTypeAudioQueue = 0,//用RecordTypeAudioQueue录音
    RecordTypeAVAudioRecorder,//用AVAudioRecorder录音
};

@protocol AQCaptureDelegate <NSObject>

- (void)returnData:(NSData *)data;

@end

@interface AudioQueueManager : NSObject

@property (nonatomic, weak) id<AQCaptureDelegate>delegate;

@property (nonatomic, assign) BOOL isRecording;

- (instancetype)initWithTage:(RecordType)type;

- (void)startRecord;
- (void)stopRecord;

@end

