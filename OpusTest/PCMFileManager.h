//
//  PCMFileManager.h
//  OpusTest
//
//  Created by 周全营 on 2019/7/29.
//  Copyright © 2019 周全营. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PCMFileManager : NSObject

+ (NSArray *)getPCMFileList;

+ (NSString *)getVoicDocumentPaths;

+ (BOOL)deleteFileWithStr:(NSString *)urlStr;

+ (NSData *)denoiseData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
