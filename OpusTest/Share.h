//
//  Share.h
//  OpusTest
//
//  Created by 周全营 on 2019/8/22.
//  Copyright © 2019 周全营. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Share : NSObject<UIActivityItemSource>

-(instancetype)initWithData:(NSString *)title andFile:(NSURL *)file;

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSURL *path;
@property (nonatomic, strong) NSData *data;
@end

NS_ASSUME_NONNULL_END
