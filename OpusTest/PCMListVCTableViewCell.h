//
//  PCMListVCTableViewCell.h
//  OpusTest
//
//  Created by 周全营 on 2019/7/31.
//  Copyright © 2019 周全营. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PCMModel;

NS_ASSUME_NONNULL_BEGIN

@interface PCMListVCTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *indexLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *selectedImageView;
@property (nonatomic,weak) PCMModel *model;
@property (copy, nonatomic) void(^sendModelBlock)(PCMModel *model);

@end

NS_ASSUME_NONNULL_END
