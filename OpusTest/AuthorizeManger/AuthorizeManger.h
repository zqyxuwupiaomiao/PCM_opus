//
//  AuthorizeManger.h
//  XiaoKa
//
//  Created by Aaron on 2018/4/2.
//  Copyright © 2018年 Aaron. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^AuthorizeBlock)(int status);

@interface AuthorizeManger : NSObject

+ (instancetype)shareInstance;

#pragma mark -
#pragma mark ---------------录音权限
- (void)checkRecodAuthorize:(AuthorizeBlock)block;

#pragma mark -
#pragma mark ---------------相机权限
/**
 检测相机权限
 
 @param isAlert 是否有提示框
 @param blok 验证状态
 */
- (void)checkCaptureWithIsAlert:(BOOL)isAlert author:(AuthorizeBlock)blok;

#pragma mark -
#pragma mark ---------------相册权限
/**
 检测相册权限
 
 @param isAlert 是否有提示框
 @param blok 验证状态
 */
- (void)checkPhotoAuthorizeWithIsAlert:(BOOL)isAlert author:(AuthorizeBlock)blok;

#pragma mark -
#pragma mark ---------------定位权限
- (void)checkLocationAuthorizeWithIsAlert:(BOOL)isAlert block:(AuthorizeBlock)block;

/**
 跳转Setting
 */
+ (void)requetSettingForAuth;


@end
