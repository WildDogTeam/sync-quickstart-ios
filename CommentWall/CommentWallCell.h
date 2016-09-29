//
//  CommentWallCell.h
//  CommentWall
//
//  Created by Garin on 16/9/29.
//  Copyright © 2016年 www.wilddog.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CommentWallCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UIView *cellBackView;
@property (strong, nonatomic) IBOutlet UILabel *commenterLabel;
@property (strong, nonatomic) IBOutlet UILabel *commentContentLabel;
@end
