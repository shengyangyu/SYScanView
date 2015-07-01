//
//  SY_BGView.m
//  u_shop
//
//  Created by yushengyang on 15/5/14.
//  Copyright (c) 2015年 yushengyang. All rights reserved.
//

#import "SY_BGView.h"

@interface SY_BGView ()
{
    /**
     *  可以绘制
     */
    BOOL canDraw;
    /**
     *  扫描框frame
     */
    CGRect clearFrame;
}
/**
 *  交互线
 */
@property (nonatomic, strong) UIImageView *mLine;

@end

@implementation SY_BGView

- (instancetype)initWithFrame:(CGRect)frame withClearFrame:(CGRect)cFrame {
    
    self = [super initWithFrame:frame];
    if (self) {
        canDraw = YES;
        clearFrame = cFrame;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    
    if (!canDraw) {
        return;
    }
    CGContextRef context = UIGraphicsGetCurrentContext();
    // 灰色框
    CGRect rect1 = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, clearFrame.origin.y);
    CGRect rect2 = CGRectMake(rect.origin.x, clearFrame.origin.y, clearFrame.origin.x, clearFrame.size.height);
    CGRect rect3 = CGRectMake(CGRectGetMaxX(clearFrame), clearFrame.origin.y, clearFrame.origin.x, clearFrame.size.height);
    CGRect rect4 = CGRectMake(rect.origin.x, CGRectGetMaxY(clearFrame), rect.size.width, rect.size.height-CGRectGetMaxY(clearFrame));
    CGContextSetRGBFillColor(context, 0.1, 0.1, 0.1,0.5);
    CGContextFillRect(context, rect1);
    CGContextSetRGBFillColor(context, 0.1, 0.1, 0.1,0.5);
    CGContextFillRect(context, rect2);
    CGContextSetRGBFillColor(context, 0.1, 0.1, 0.1,0.5);
    CGContextFillRect(context, rect3);
    CGContextSetRGBFillColor(context, 0.1, 0.1, 0.1,0.5);
    CGContextFillRect(context, rect4);
    // 添加扫瞄框
    UIImageView *img = [[UIImageView alloc] initWithFrame:clearFrame];
    img.image = [UIImage imageNamed:@"scan_bg"];
    [self addSubview:img];
    //画中间的基准线
    [self removeLine];
    _mLine = [[UIImageView alloc] initWithFrame:CGRectMake(clearFrame.origin.x, clearFrame.origin.y, ScreenWidth, 12.0f)];
    [_mLine setImage:[UIImage imageNamed:@"scan_line"]];
    [self addSubview:_mLine];
    [self startLineAnimation];
}

- (void)removeLine {
    if (_mLine) {
        [_mLine.layer removeAllAnimations];
        [_mLine removeFromSuperview];
        _mLine = nil;
    }
}

- (void)initLine {
    [self removeLine];
    //画中间的基准线
    _mLine = [[UIImageView alloc] initWithFrame:CGRectMake(clearFrame.origin.x, clearFrame.origin.y, ScreenWidth, 12.0f)];
    [_mLine setImage:[UIImage imageNamed:@"scan_line"]];
    [self addSubview:_mLine];
    [self startLineAnimation];
}

- (void)startLineAnimation {
    if (_mLine) {
        if ([self.mLine.layer animationForKey:@"translation"]) {
            return;
        }
        [_mLine setFrame:CGRectMake(clearFrame.origin.x, clearFrame.origin.y, ScreenWidth, 12.0f)];
        _mLine.hidden = NO;
        //添加图片的layer动画
        CABasicAnimation *translation = [CABasicAnimation animationWithKeyPath:@"position"];
        [translation setFromValue:[NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(clearFrame), CGRectGetMinY(clearFrame))]];
        [translation setToValue:[NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(clearFrame), CGRectGetMaxY(clearFrame))]];
        [translation setDuration:2];
        [translation setRepeatCount:HUGE_VALF];
        [translation setAutoreverses:YES];
        [self.mLine.layer addAnimation:translation forKey:@"translation"];
    }
}

- (void)stopLineAnimation {
    self.mLine.hidden = YES;
    [self.mLine.layer removeAllAnimations];
}


- (void)dealloc {
    /*
    if (_mLine) {
        [_mLine.layer removeAllAnimations];
        _mLine = nil;
    }
     */
}

@end
