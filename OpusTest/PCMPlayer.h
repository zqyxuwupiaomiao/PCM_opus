//
//  PCMPlayer.h
//  OpusTest
//
//  Created by 周全营 on 2019/7/29.
//  Copyright © 2019 周全营. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PCMPlayer;

NS_ASSUME_NONNULL_BEGIN

@protocol PCMPlayerDelegate <NSObject>

- (void)onPlayToEnd:(PCMPlayer *)player;

@end

@interface PCMPlayer : NSObject

@property (nonatomic, weak) id<PCMPlayerDelegate> delegate;

- (void)playWithUrlStr:(NSString *)urlStr;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
