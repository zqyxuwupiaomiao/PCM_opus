//
//  ViewController.m
//  OpusTest
//
//  Created by 周全营 on 2018/12/12.
//  Copyright © 2018 周全营. All rights reserved.
//

#import "ViewController.h"
#import "OpusManager.h"
#import "AudioQueueManager.h"
#import "PCMFileManager.h"
#import "PCMListViewController.h"
#import "AuthorizeManger.h"

@interface ViewController ()<AQCaptureDelegate>

@property (nonatomic,strong) NSURL *urlPlay;
@property (nonatomic,strong) AudioQueueManager *manager;
@property (nonatomic,strong) NSMutableData *mutableData;
@property (nonatomic,strong) UIButton *palyButton;
@property (nonatomic,strong) UISegmentedControl *segmentedControl;
@property (nonatomic,strong) UISegmentedControl *segmentedControl2;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"录音";
    self.mutableData = [[NSMutableData alloc] init];
    [[AuthorizeManger shareInstance] checkRecodAuthorize:^(int status) {
        if (status){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self createUI];
            });
        }
    }];
}

#pragma mark -
#pragma mark - <UI>
- (void)createUI{
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    
    self.palyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _palyButton.frame = CGRectMake(width / 2 - 50, 100, 100, 60);
    [_palyButton setTitle:@"录音" forState:UIControlStateNormal];
    [_palyButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [_palyButton addTarget:self action:@selector(playButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [_palyButton setBackgroundColor:[UIColor blueColor]];
    [self.view addSubview:_palyButton];
    _palyButton.layer.masksToBounds = YES;
    _palyButton.layer.cornerRadius = 8;
    
    UIButton *cancleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancleButton.frame = CGRectMake(width / 2 - 50, 300, 100, 60);
    [cancleButton setTitle:@"完成" forState:UIControlStateNormal];
    [cancleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [cancleButton addTarget:self action:@selector(cancleButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [cancleButton setBackgroundColor:[UIColor blackColor]];
    [self.view addSubview:cancleButton];
    cancleButton.layer.masksToBounds = YES;
    cancleButton.layer.cornerRadius = 8;
    
    UIBarButtonItem *barBtn1 = [[UIBarButtonItem alloc] initWithTitle:@"跳转分享" style:UIBarButtonItemStylePlain target:self action:@selector(shareButtonClick)];
    self.navigationItem.rightBarButtonItem = barBtn1;
    
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"不降燥",@"降噪"]];
    _segmentedControl.frame = CGRectMake(100, height - 60, width - 200, 30);
    _segmentedControl.tintColor = [UIColor redColor];
    [self.view addSubview:_segmentedControl];
    _segmentedControl.selectedSegmentIndex = 0;
    [_segmentedControl addTarget:self action:@selector(selectItem:) forControlEvents:UIControlEventValueChanged];// 添加响应方法
    
    self.segmentedControl2 = [[UISegmentedControl alloc] initWithItems:@[@"1",@"2"]];
    _segmentedControl2.frame = CGRectMake(100, height - 120, width - 200, 30);
    _segmentedControl2.tintColor = [UIColor redColor];
    [self.view addSubview:_segmentedControl2];
    _segmentedControl2.selectedSegmentIndex = 0;
    [_segmentedControl2 addTarget:self action:@selector(selectItem:) forControlEvents:UIControlEventValueChanged];// 添加响应方法
}
- (void)selectItem:(UISegmentedControl *)segmentedControl{

}

#pragma mark -
#pragma mark - <分享跳转>
- (void)shareButtonClick{
    PCMListViewController *vc = [[PCMListViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark -
#pragma mark - <停止录音>
- (void)cancleButtonClick{
    if (self.manager.isRecording) {
        
        [self.manager stopRecord];
        self.palyButton.selected = NO;
        [self.palyButton setTitle:@"录音" forState:UIControlStateNormal];
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"是否需要保存文件" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *str = alertController.textFields.firstObject.text;
            if (str.length <= 0) {
                str = [self getNowTimeTimestamp];
            }
            NSString * rarFilePath = [PCMFileManager getVoicDocumentPaths];//将需要创建的串拼接到后面
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if (![fileManager fileExistsAtPath:rarFilePath isDirectory:nil]) {
                //没有文件夹先创建文件夹
                [fileManager createDirectoryAtPath:rarFilePath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            
            NSString *filePathStr = [NSString stringWithFormat:@"%@/%@.pcm",rarFilePath,str];
            NSFileManager *fm = [NSFileManager defaultManager];            
            if ([fm createFileAtPath:filePathStr contents:self.mutableData attributes:nil]) {
                //保存语音文件
                //NSLog(@"保存成功");
            }
        }];
        [alertController addAction:cancelAction];
        [alertController addAction:okAction];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField){
            textField.placeholder = [NSString stringWithFormat:@"%@.pcm",[self getNowTimeTimestamp]];
        }];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

#pragma mark -
#pragma mark - <录音点击>
- (void)playButtonClick:(UIButton *)button{
    button.selected = !button.selected;
    if (button.selected) {
        [button setTitle:@"取消录音" forState:UIControlStateNormal];
        self.mutableData = [[NSMutableData alloc] init];
        self.manager = [[AudioQueueManager alloc] initWithTage:_segmentedControl2.selectedSegmentIndex];
        self.manager.delegate = self;
        [self.manager startRecord];
    }else{
        [button setTitle:@"录音" forState:UIControlStateNormal];
        self.mutableData = [[NSMutableData alloc] init];
        [self.manager stopRecord];
        self.manager = nil;
    }
}
#pragma mark -
#pragma mark -<AQCaptureDelegate>
- (void)returnData:(NSData *)data{
    //opus压缩
//    NSData *enData = [[OpusManager shareInstance] encodePCMData:data];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            [self.mutableData appendData:data];
        }else{
            [self.mutableData appendData:[PCMFileManager denoiseData:data]];
        }
    });
}

#pragma mark -
#pragma mark ---------------获取当前时间戳
//获取当前时间戳有两种方法(以毫秒为单位)
- (NSString *)getNowTimeTimestamp{
    NSDate *dat = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval a = [dat timeIntervalSince1970];
    NSString *timeString = [NSString stringWithFormat:@"%0.f", a * 1000];//转为字符型
    return timeString;
}

@end
