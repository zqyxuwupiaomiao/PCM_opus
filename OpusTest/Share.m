//
//  Share.m
//  OpusTest
//
//  Created by 周全营 on 2019/8/22.
//  Copyright © 2019 周全营. All rights reserved.
//

#import "Share.h"

@implementation Share

-(instancetype)initWithData:(NSString *)title andFile:(NSURL *)file
{
    self = [super init];
    if (self) {
        _title = title;
        _path = file;
    }
    return self;
}

-(instancetype)init
{
    //不期望这种初始化方式，所以返回nil了。
    return nil;
}

#pragma mark - UIActivityItemSource
-(id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    return nil;
}

-(id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType
{
    return _path;
}

-(NSString*)activityViewController:(UIActivityViewController *)activityViewController subjectForActivityType:(NSString *)activityType
{

    return _title;
}
@end
