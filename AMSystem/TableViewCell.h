//
//  TableViewCell.h
//  AMSystem
//
//  Created by 徐晓斐 on 14-10-14.
//  Copyright (c) 2014年 GZDEU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PeoperData.h"
@interface TableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *right;
@property (weak, nonatomic) IBOutlet UILabel *unusual;
@property (strong,nonatomic) PeoperData *per;
@end
