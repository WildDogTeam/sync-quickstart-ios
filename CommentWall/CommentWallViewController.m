//
//  CommentWallViewController.m
//  CommentWall
//
//  Created by Garin on 16/9/28.
//  Copyright © 2016年 www.wilddog.com. All rights reserved.
//

#import "CommentWallViewController.h"
#import "CommentWallCell.h"
#import "UIColor+Helper.h"

/* 引入 SDK 方式，二选一 */

//1、用 pod 的方式， 引入 Wilddog Sync SDK
#import "Wilddog.h"

//2、用 SDK 的方式，引入 Wilddog Sync SDK
//#import <WilddogCore/WilddogCore.h>
//#import <WilddogSync/WilddogSync.h>

static NSString *placeholderCommenter = @"评论者";
static NSString *placeholderContent = @"评论内容 ...";

@interface CommentWallViewController ()<UITextViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UITextView *commenterTextView;
@property (strong, nonatomic) IBOutlet UITextView *commentContentView;

@property (nonatomic, strong) NSMutableArray* dataArray;
@property (nonatomic, assign) BOOL newMessagesOnTop;
@property (nonatomic, assign) CGRect originFrame;

// WDGSyncReference 实例
@property (nonatomic, strong) WDGSyncReference *ref;

@end

@implementation CommentWallViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.originFrame = self.view.frame;

    // 数据源
    self.dataArray = [[NSMutableArray alloc] init];

    // 监听键盘出现
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(keyboardWillShow:)
                                                name:UIKeyboardWillShowNotification object:nil];
    
    // 监听键盘隐藏
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(keyboardWillHide:)
                                                name:UIKeyboardWillHideNotification object:nil];
    
    
    // 获取 WDGSyncReference 实例
    self.ref = [[WDGSync sync] referenceWithPath:@"messageboard"];
    
    self.newMessagesOnTop = YES;
    
    __block BOOL initialAdds = YES;
    
    // 初始化时触发，或者每次添加新数据时触发
    [self.ref observeEventType:WDGDataEventTypeChildAdded withBlock:^(WDGDataSnapshot *snapshot) {
        
        if (self.newMessagesOnTop) {
            if (snapshot.value) {
                [self.dataArray insertObject:snapshot.value atIndex:0];
            }
        }else{
            [self.dataArray addObject:snapshot.value];
        }
        
        if (!initialAdds) {
            [self.tableView reloadData];
        }
        
    }];
    
    // 单次监听
    // WDGDataEventTypeValue 是最后触发的
    [self.ref observeSingleEventOfType:WDGDataEventTypeValue withBlock:^(WDGDataSnapshot *snapshot) {
        
        [self.tableView reloadData];
        initialAdds = NO;
        
    }];
}

// 点击添加评论按钮
- (IBAction)addComentAction:(id)sender {
    
    if ([self.commenterTextView.text isEqualToString:placeholderCommenter] || [self.commentContentView.text isEqualToString:placeholderContent] || self.commenterTextView.text.length == 0 || self.commentContentView.text.length == 0) {
        NSLog(@"请用优雅的语言评论");
        return;
    }
    
    // 构造要写入 Wilddog Sync 的数据结构
    NSMutableDictionary *contentDic = [NSMutableDictionary new];
    [contentDic setValue:self.commenterTextView.text forKey:@"presenter"];
    [contentDic setValue:self.commentContentView.text forKey:@"content"];

    // 写入操作
    [[self.ref childByAutoId] setValue:contentDic withCompletionBlock:^(NSError * _Nullable error, WDGSyncReference * _Nonnull ref) {
        if (!error) {
            NSLog(@"评论成功!");
        }
    }];
    [self.view endEditing:YES];
    
    if(self.dataArray.count > 0)
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    
    self.commentContentView.text = @"";
    self.commenterTextView.text = @"";
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)keyboardWillShow:(NSNotification*)notification {
    
    CGRect endRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect convertRect=[self.view convertRect:endRect fromView:nil];
    float duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    [UIView animateWithDuration:duration animations:^{
        
        CGRect frame = self.view.frame;
        frame.origin.y = -  convertRect.size.height;
        self.view.frame = frame;
    }];
}

- (void)keyboardWillHide:(NSNotification*)notification {
    
    float duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    [UIView animateWithDuration:duration animations:^{
        
        CGRect frame = self.view.frame;
        frame.origin.y = self.originFrame.origin.y;
        self.view.frame = frame;
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [self.view endEditing:YES];
}

- (void)textViewDidBeginEditing:(UITextView *)textView{
    
    if ([textView.text isEqualToString:placeholderCommenter] || [textView.text isEqualToString:placeholderContent]) {
        textView.text = @"";
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return self.dataArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellID = @"CellID";
    CommentWallCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"CommentWallCell" owner:nil options:nil] lastObject];
        cell.cellBackView.layer.shadowColor = [UIColor colorFromString:@"e5e5e5"].CGColor;
        cell.cellBackView.layer.shadowOffset = CGSizeMake(1,1);
        cell.cellBackView.layer.shadowOpacity = .9; //阴影透明度，默认0
        cell.cellBackView.layer.shadowRadius = 1;   //阴影半径，默认3
        cell.cellBackView.layer.borderWidth = 1;
        cell.cellBackView.layer.borderColor = [UIColor colorFromString:@"e5e5e5"].CGColor;
        cell.cellBackView.layer.cornerRadius = 5;
    }
    id dataArrayMessage = [self.dataArray objectAtIndex:indexPath.section];
    cell.commentContentLabel.text = dataArrayMessage[@"content"];
    cell.commenterLabel.text = dataArrayMessage[@"presenter"];
    return cell;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = self.tableView.backgroundColor;
    return view;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = self.tableView.backgroundColor;
    return view;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    if (section == 0) {
        return 40;
    }
    return 20;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    
    if (section == self.dataArray.count-1) {
        return 40;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    id content = [self.dataArray objectAtIndex:indexPath.section];
    
    if (![content isKindOfClass:[NSDictionary class]]) {
        return 0;
    }
    
    NSString *text = content[@"content"];
    
    const CGFloat TEXT_LABEL_WIDTH = 240;
    CGSize constraint = CGSizeMake(TEXT_LABEL_WIDTH, 20000);
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:18]};

    
    CGSize size = [text boundingRectWithSize:constraint options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attributes context:nil].size;
    const CGFloat CELL_CONTENT_MARGIN = 20;
    CGFloat height = MAX(CELL_CONTENT_MARGIN + size.height, 44);
    
    return height;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
