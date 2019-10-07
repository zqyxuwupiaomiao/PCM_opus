//
//  AuthorizeManger.m
//  XiaoKa
//
//  Created by Aaron on 2018/4/2.
//  Copyright © 2018年 Aaron. All rights reserved.
//

#import "AuthorizeManger.h"
#import <CoreLocation/CoreLocation.h>
#import <UserNotifications/UserNotifications.h>
#import <Photos/Photos.h>

@interface AuthorizeManger ()<CLLocationManagerDelegate>

@property (nonatomic,strong) CLLocationManager *locationManager;

@end

@implementation AuthorizeManger

+ (instancetype)shareInstance{
    static AuthorizeManger *_manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[AuthorizeManger alloc] init];
    });
    return _manager;
}

#pragma mark -
#pragma mark ---------------录音权限
- (void)checkRecodAuthorize:(AuthorizeBlock)block
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if (session.recordPermission == AVAudioSessionRecordPermissionUndetermined) {

    }
    [session requestRecordPermission:^(BOOL granted) {
        if (granted){
            if (block) {
                block(true);
            }
        }else{
            if (block) {
                block(false);
            }
        }
    }];
}

#pragma mark -
#pragma mark ---------------相机权限
- (void)checkCaptureWithIsAlert:(BOOL)isAlert author:(AuthorizeBlock)blok{
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusRestricted || status == AVAuthorizationStatusDenied) {
        if (isAlert) {
            if (blok) {
                blok(0);
            }
        }else{
            if (blok) {
                blok(0);
            }
        }
    } else if (status == AVAuthorizationStatusNotDetermined) {
        //获取访问相机权限时，弹窗的点击事件获取
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (blok) {
                    blok(granted);
                }
            });
        }];
    }else{
        if (blok) {
            blok(1);
        }
    }
}
#pragma mark -
#pragma mark ---------------相册权限
/**
 检测相册权限
 
 @param isAlert 是否有提示框
 @param blok 验证状态
 */
- (void)checkPhotoAuthorizeWithIsAlert:(BOOL)isAlert author:(AuthorizeBlock)blok{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusDenied || status == PHAuthorizationStatusRestricted) {
        if (isAlert) {
            if (blok) {
                blok(0);
            }
        }else{
            if (blok) {
                blok(0);
            }
        }
    }else if (status == PHAuthorizationStatusNotDetermined){
        //请求权限
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (status == PHAuthorizationStatusAuthorized) {
                    if (blok) {
                        blok(1);
                    }
                }else{
                    if (blok) {
                        blok(0);
                    }
                }
            });
        }];
    }else{
        if (blok) {
            blok(1);
        }
    }
}

#pragma mark -
#pragma mark ---------------定位权限
- (void)checkLocationAuthorizeWithIsAlert:(BOOL)isAlert block:(AuthorizeBlock)block
{
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusNotDetermined:
        {//尚未作出选择
            self.locationManager = [[CLLocationManager alloc] init];
            self.locationManager.delegate = self;
            [self.locationManager requestWhenInUseAuthorization];
            if (block) {
                block(false);
            }
        }
            break;
        case kCLAuthorizationStatusDenied:
        {//权限未允许
            if (block) {
                block(false);
            }
            if (isAlert)
            {
                
            }
        }
            break;
        case kCLAuthorizationStatusRestricted:
        {// 无法使用定位服务，该状态用户无法改变
            self.locationManager = [[CLLocationManager alloc] init];
            self.locationManager.delegate = self;
            [self.locationManager requestWhenInUseAuthorization];
            if (block) {
                block(false);
            }
        }
            break;
        default:
            if (block) {
                block(true);
            }
            break;
    }
}
//代理
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    
}

+ (void)requetSettingForAuth{
    [[self alloc] requetSettingForAuth];
}

- (void)requetSettingForAuth{
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([ [UIApplication sharedApplication] canOpenURL:url]){
        [[UIApplication sharedApplication] openURL:url];
    }
}

@end
