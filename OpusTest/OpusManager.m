//
//  OpusManager.m
//  OpusTest
//
//  Created by 周全营 on 2018/12/12.
//  Copyright © 2018 周全营. All rights reserved.
//

#import "OpusManager.h"
#import "opus.h"

// 用于记录opus块大小的类型
typedef opus_int16 OPUS_DATA_SIZE_T;

@implementation OpusManager{
    OpusEncoder *enc;
    OpusDecoder *dec;
    unsigned char opus_data_encoder[40];
}

+ (instancetype)shareInstance{
    static OpusManager *_manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[OpusManager alloc] init];
    });
    return _manager;
}

- (instancetype)init{
    if (self = [super init]) {
        int error;
        enc = opus_encoder_create(kDefaultSampleRate, 1, OPUS_APPLICATION_VOIP, &error);//(采样率，声道数,,)
        dec = opus_decoder_create(kDefaultSampleRate, 1, &error);
        opus_encoder_ctl(enc, OPUS_SET_BITRATE(kDefaultSampleRate));//比特率
        opus_encoder_ctl(enc, OPUS_SET_BANDWIDTH(OPUS_AUTO));//OPUS_BANDWIDTH_NARROWBAND 宽带窄带
        opus_encoder_ctl(enc, OPUS_SET_VBR(0));
        opus_encoder_ctl(enc, OPUS_SET_VBR_CONSTRAINT(1));
        opus_encoder_ctl(enc, OPUS_SET_COMPLEXITY(8));//录制质量 1-10
        opus_encoder_ctl(enc, OPUS_SET_PACKET_LOSS_PERC(0));
        opus_encoder_ctl(enc, OPUS_SET_SIGNAL(OPUS_SIGNAL_VOICE));//信号
    }
    return self;
}

- (NSData *)encode:(short *)pcmBuffer length:(NSInteger)lengthOfShorts{
    opus_int16 *PCMPtr = pcmBuffer;
    int PCMSize = (int)lengthOfShorts / sizeof(opus_int16);
    opus_int16 *PCMEnd = PCMPtr + PCMSize;
    NSMutableData *mutData = [NSMutableData data];
    unsigned char encodedPacket[MAX_PACKET_BYTES];
    // 记录opus块大小
    OPUS_DATA_SIZE_T encodedBytes = 0;
    
    while (PCMPtr + WB_FRAME_SIZE < PCMEnd) {
        encodedBytes = opus_encode(enc, PCMPtr, WB_FRAME_SIZE, encodedPacket, MAX_PACKET_BYTES);
        if (encodedBytes <= 0) {

            return nil;
        }
        // 大端转小端 这个要根据解析要求是大段还是小段存储
//        encodedBytes = CFSwapInt32HostToBig(encodedBytes)
        
        // 保存opus块大小
        [mutData appendBytes:&encodedBytes length:sizeof(encodedBytes)];
        
//        char check_sum[] = "fake";
//        [mutData appendBytes:check_sum length:sizeof(check_sum)];
        // 保存opus数据
        [mutData appendBytes:encodedPacket length:encodedBytes];
        
        PCMPtr += WB_FRAME_SIZE;
    }
    return mutData.length > 0 ? mutData : nil;
}

- (NSData *)encodePCMData:(NSData*)data{
    
    return  [self encode:(short *)[data bytes] length:[data length]];
}

- (NSData *)decodeOpusData:(NSData*)data{
    unsigned char *opusPtr = (unsigned char *)data.bytes;
    int opusSize = (int)data.length;
    unsigned char *opusEnd = opusPtr + opusSize;
    NSMutableData *mutData = [[NSMutableData alloc] init];
    opus_int16 decodedPacket[MAX_PACKET_BYTES];
    int decodedSamples = 0;
    // 保存opus块大小的数据
    OPUS_DATA_SIZE_T nBytes = 0;
    
    while (opusPtr < opusEnd) {
        // 取出opus块大小的数据
        nBytes = *(OPUS_DATA_SIZE_T *)opusPtr;
        opusPtr += sizeof(nBytes);
        decodedSamples = opus_decode(dec, opusPtr, nBytes, decodedPacket, MAX_PACKET_BYTES, 0);
        if (decodedSamples <= 0) {
            return nil;
        }
        [mutData appendBytes:decodedPacket length:decodedSamples * sizeof(opus_int16)];
        opusPtr += nBytes;
    }
    return mutData.length > 0 ? mutData : nil;
}

- (void)destroy{
    opus_encoder_destroy(enc);
    opus_decoder_destroy(dec);
}
@end
