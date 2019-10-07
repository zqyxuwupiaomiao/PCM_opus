//
//  PCMFileManager.m
//  OpusTest
//
//  Created by 周全营 on 2019/7/29.
//  Copyright © 2019 周全营. All rights reserved.
//

#import "PCMFileManager.h"
#include "noise_suppression.h"
#import <AVFoundation/AVFoundation.h>

#define VOICE_RATE_UNIT 160

#ifndef nullptr

#define nullptr 0

#endif

enum nsLevel {
    kLow,
    kModerate,
    kHigh,
    kVeryHigh
};

@implementation PCMFileManager

+ (NSArray *)getPCMFileList{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSString *voiceFileList = [self getVoicDocumentPaths];
    //fileList便是包含有该文件夹下所有文件的文件名及文件夹名的数组
    NSArray *fileList = [fileManager contentsOfDirectoryAtPath:voiceFileList error:&error];
    return fileList;
}

+ (NSString *)getVoicDocumentPaths{
    NSString * docsdir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString * rarFilePath = [docsdir stringByAppendingPathComponent:@"/voice"];//将需要创建的串拼接到后面
    return rarFilePath;
}

+ (BOOL)deleteFileWithStr:(NSString *)urlStr{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    return [fileManager removeItemAtPath:urlStr error:&error];
}

+ (NSData *)denoiseData:(NSData *)data{
    int16_t *buffer = (int16_t *)[data bytes];
    uint32_t sampleRate = kDefaultSampleRate;
    int samplesCount = (int)data.length / 2;
    int level = kVeryHigh;
    if (buffer == nullptr) return nil;
    if (samplesCount == 0) return nil;
    size_t samples = MIN(160, sampleRate / 100);
    if (samples == 0) return nil;
    uint32_t num_bands = 1;
    int16_t *input = buffer;
    size_t nTotal = (samplesCount / samples);
    NsHandle *nsHandle = WebRtcNs_Create();
    int status = WebRtcNs_Init(nsHandle, sampleRate);
    if (status != 0) {
//        printf("WebRtcNs_Init fail\n");
        return nil;
    }
    status = WebRtcNs_set_policy(nsHandle, level);
    if (status != 0) {
//        printf("WebRtcNs_set_policy fail\n");
        return nil;
    }
    for (int i = 0; i < nTotal; i++) {
        int16_t *nsIn[1] = {input};   //ns input[band][data]
        int16_t *nsOut[1] = {input};  //ns output[band][data]
        WebRtcNs_Analyze(nsHandle, nsIn[0]);
        WebRtcNs_Process(nsHandle, (const int16_t *const *) nsIn, num_bands, nsOut);
        input += samples;
    }
    WebRtcNs_Free(nsHandle);
    
    return [NSData dataWithBytes:buffer length:[data length]];
}

/**
 *   计算时长  NSData *data = [NSData dataWithContentsOfFile:urlStr];
 NSLog(@"%ld",[data length] / 16000 / 2);
 码率计算公式
 基本的算法是：【码率】（kbps)=【文件大小】（字节）X8/【时间】（秒）*1000
 音频文件专用算法：【比特率】（kbps)=【量化采样点】（kHz）×【位深】（bit/采样点）×【声道数量】（一般为2）
 */

@end
