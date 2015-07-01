//
//  SY_BGView.h
//  u_shop
//
//  Created by yushengyang on 15/5/14.
//  Copyright (c) 2015年 yushengyang. All rights reserved.
//

#import <UIKit/UIKit.h>

#define ScreenWidth ([[UIScreen mainScreen] bounds].size.width)
#define ScreenHigh  ([[UIScreen mainScreen] bounds].size.height)
#define SCan_Offset_y (64.0)
#define SCan_Offset_x (50.0)
#define SCan_Size (ScreenWidth-SCan_Offset_x*2)
//设备屏幕大小
#define __MainScreenFrame   [[UIScreen mainScreen] bounds]
#define __MainScreen_Width  __MainScreenFrame.size.width
#define __MainScreen_Height_origin __MainScreenFrame.size.height
#define __MainScreen_Height __MainScreen_Height_origin - 20
#define __viewContent_hight1 __MainScreen_Height - 44 + 20 //-导航条

@interface SY_BGView : UIView

/**
 *  初始化 放置在扫描界面上的view
 *
 *  @param frame  扫描界面frame
 *  @param cFrame 扫描框frame
 *
 *  @return view
 */
- (instancetype)initWithFrame:(CGRect)frame withClearFrame:(CGRect)cFrame;
/**
 *  扫描线动画开始
 */
- (void)startLineAnimation;
/**
 *  扫描线动画结束
 */
- (void)stopLineAnimation;

/**
 *  初始化线
 */
- (void)initLine;

/**
 *  移除线
 */
- (void)removeLine;

@end
