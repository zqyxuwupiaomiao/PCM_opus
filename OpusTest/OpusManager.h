//
//  OpusManager.h
//  OpusTest
//
//  Created by 周全营 on 2018/12/12.
//  Copyright © 2018 周全营. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OpusManager : NSObject

+ (instancetype)shareInstance;

//编码
- (NSData*)encodePCMData:(NSData*)data;

- (NSData*)decodeOpusData:(NSData*)data;

- (void)destroy;

@end

