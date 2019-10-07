//
//  PCMListViewController.m
//  OpusTest
//
//  Created by 周全营 on 2019/7/29.
//  Copyright © 2019 周全营. All rights reserved.
//

#import "PCMListViewController.h"
#import "PCMFileManager.h"
#import "PCMPlayer.h"
#import "PCMListVCTableViewCell.h"
#import "Share.h"
#import "ZipArchive.h"
#import "MBProgressHUD.h"
#import "AppDelegate.h"
#import "PCMModel.h"

@interface PCMListViewController ()<UITableViewDelegate,UITableViewDataSource,PCMPlayerDelegate>

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *dataArray;
@property (nonatomic,strong) NSMutableArray *seletedArray;
@property (nonatomic,strong) PCMPlayer *player;
@property (nonatomic,strong) UIBarButtonItem *barBtn3;
@end

@implementation PCMListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"录音列表";
    
    [self createTableViewWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];

    UIBarButtonItem *barBtn1 = [[UIBarButtonItem alloc] initWithTitle:@"分享" style:UIBarButtonItemStylePlain target:self action:@selector(sharePCMFile)];
    UIBarButtonItem *barBtn2 = [[UIBarButtonItem alloc] initWithTitle:@"删除" style:UIBarButtonItemStylePlain target:self action:@selector(deletePCMFile)];
    self.barBtn3 = [[UIBarButtonItem alloc] initWithTitle:@"全选" style:UIBarButtonItemStylePlain target:self action:@selector(selectAllPCMFile)];

    self.navigationItem.rightBarButtonItems = @[barBtn1,barBtn2,_barBtn3];
    
    [self initSomeData];
}
- (void)createTableViewWithFrame:(CGRect)frame{
    self.tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    [_tableView registerNib:[UINib nibWithNibName:@"PCMListVCTableViewCell" bundle:nil] forCellReuseIdentifier:@"PCMListVCTableViewCellID"];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.tableFooterView = [UIView new];
    [self.view addSubview:_tableView];
}
- (void)initSomeData{
    self.player = [[PCMPlayer alloc] init];
    _player.delegate = self;
    self.dataArray = [[NSMutableArray alloc] init];
    self.seletedArray = [[NSMutableArray alloc] init];
    [self deleteDestinationPath];
    [self requestData];
}
- (void)deletePCMFile{
    [self.player stop];
    if (self.seletedArray.count <= 0) {
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"是否要删除选中的录音？" preferredStyle:UIAlertControllerStyleAlert];
    //2.1 确认按钮
    UIAlertAction *conform = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        for (PCMModel *model in self.seletedArray) {
            NSString *fileStr = [NSString stringWithFormat:@"%@/%@",[PCMFileManager getVoicDocumentPaths],model.nameStr];
            [PCMFileManager deleteFileWithStr:fileStr];
        }
        [self requestData];
    }];
    //2.2 取消按钮
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {

    }];
    //3.将动作按钮 添加到控制器中
    [alert addAction:conform];
    [alert addAction:cancel];
    //4.显示弹框
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)selectAllPCMFile{
    if ([self.barBtn3.title isEqualToString:@"全选"]) {
        for (PCMModel *model in self.dataArray) {
            model.isSeleted = YES;
        }
        [self.tableView reloadData];
        [self.seletedArray removeAllObjects];
        [self.seletedArray addObjectsFromArray:self.dataArray];
        self.barBtn3.title = @"取消全选";
    }else{
        [self requestData];
        self.barBtn3.title = @"全选";
    }
}
- (void)sharePCMFile{
    //压缩的zip路径
    NSString *destinationPath = [NSString stringWithFormat:@"%@/%@",[PCMFileManager getVoicDocumentPaths],@"opus.zip"];
    [PCMFileManager deleteFileWithStr:destinationPath];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.mode = MBProgressHUDModeAnnularDeterminate;
    if (self.seletedArray.count <= 0) {
        hud.label.text = @"暂无压缩内容";
        [hud hideAnimated:YES afterDelay:1];
        return;
    }
    hud.label.text = @"正在压缩";
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSMutableArray *mArray = [[NSMutableArray alloc] init];
        for (PCMModel *model in self.seletedArray) {
            NSString *fileStr = [NSString stringWithFormat:@"%@/%@",[PCMFileManager getVoicDocumentPaths],model.nameStr];
            [mArray addObject:fileStr];
        }
        if ([SSZipArchive createZipFileAtPath:destinationPath withFilesAtPaths:mArray]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                hud.label.text = @"压缩成功";
                [hud hideAnimated:YES afterDelay:1];
                //压缩完成分享
                UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:destinationPath]] applicationActivities:nil];
                activityVC.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
                    [PCMFileManager deleteFileWithStr:destinationPath];
                    if (completed) {
                        [self requestData];
                    }
                };
                [self presentViewController:activityVC animated:YES completion:nil];
            });
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                hud.label.text = @"压缩失败";
                [hud hideAnimated:YES afterDelay:1];
                [PCMFileManager deleteFileWithStr:destinationPath];
            });
        }
    });
}
- (void)deleteDestinationPath{
    NSString *destinationPath = [NSString stringWithFormat:@"%@/%@",[PCMFileManager getVoicDocumentPaths],@"opus.zip"];
    [PCMFileManager deleteFileWithStr:destinationPath];
}

- (void)requestData{
    [self.seletedArray removeAllObjects];
    [self.dataArray removeAllObjects];
    [self.tableView reloadData];
    for (NSString *str in [PCMFileManager getPCMFileList]) {
        PCMModel *model = [[PCMModel alloc] init];
        model.nameStr = str;
        [self.dataArray addObject:model];
        [self.tableView reloadData];
    }
}
#pragma mark -
#pragma mark - <UITableViewDelegate,UITableViewDataSource>
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    PCMListVCTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PCMListVCTableViewCellID" forIndexPath:indexPath];
    PCMModel *model = self.dataArray[self.dataArray.count - 1 - indexPath.row];
    cell.indexLabel.text = [NSString stringWithFormat:@"%ld",indexPath.row + 1];
    cell.titleLabel.text = model.nameStr;
    cell.model = model;
    if (model.isSeleted) {
        cell.selectedImageView.image = [UIImage imageNamed:@"Calendar_ico_cpmplete_on"];
    }else{
        cell.selectedImageView.image = [UIImage imageNamed:@"Setting_ico_check"];
    }
    
    __weak PCMListViewController *weakSelf = self;
    [cell setSendModelBlock:^(PCMModel * _Nonnull model) {
        if (model.isSeleted) {
            [self.seletedArray addObject:model];
        }else{
            [self.seletedArray removeObject:model];
        }
        [weakSelf.tableView reloadData];
        if (weakSelf.seletedArray.count == weakSelf.dataArray.count) {
            weakSelf.barBtn3.title = @"取消全选";
        }else{
            weakSelf.barBtn3.title = @"全选";
        }
    }];
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 55;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [_player stop];
    PCMModel *model = self.dataArray[self.dataArray.count - 1 - indexPath.row];
    NSString *fileStr = [NSString stringWithFormat:@"%@/%@",[PCMFileManager getVoicDocumentPaths],model.nameStr];
    [_player playWithUrlStr:fileStr];
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    editingStyle = UITableViewCellEditingStyleDelete;
}
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleDelete;
}
- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *action = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"删除" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [self.player stop];
        PCMModel *model = self.dataArray[self.dataArray.count - 1 - indexPath.row];
        NSString *fileStr = [NSString stringWithFormat:@"%@/%@",[PCMFileManager getVoicDocumentPaths],model.nameStr];
        if ([PCMFileManager deleteFileWithStr:fileStr]) {
            [self requestData];
        }
    }];
    return @[action];
}

#pragma mark -
#pragma mark -<PCMPlayerDelegate>
- (void)onPlayToEnd:(PCMPlayer *)player{
    player = nil;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
