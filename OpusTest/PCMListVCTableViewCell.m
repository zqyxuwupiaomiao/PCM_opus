//
//  PCMListVCTableViewCell.m
//  OpusTest
//
//  Created by 周全营 on 2019/7/31.
//  Copyright © 2019 周全营. All rights reserved.
//

#import "PCMListVCTableViewCell.h"
#import "PCMModel.h"

@implementation PCMListVCTableViewCell

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake( [[UIScreen mainScreen] bounds].size.width - 60, 0, 60, 55);
        [self.contentView addSubview:button];
        [button addTarget:self action:@selector(buttonClick) forControlEvents:UIControlEventTouchUpInside];
        button.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)buttonClick{
    self.model.isSeleted = !self.model.isSeleted;
    if (self.sendModelBlock) {
        self.sendModelBlock(self.model);
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
