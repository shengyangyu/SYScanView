//
//  SY_ScannerVC.h
//  u_shop
//
//  Created by yushengyang on 15/5/14.
//  Copyright (c) 2015年 yushengyang. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SY_ScannerVC;
/*
 * 代理
 */
@protocol SYScannerVC_Delegate <NSObject>
@optional
/**
 *  扫描成功
 */
- (void)scannerSuccessVC:(SY_ScannerVC *)vc resultCode:(NSString *)result;
/**
 *  扫描取消(当非push切换 需要手动添加取消按钮)
 */
- (void)scannerCancleVC:(SY_ScannerVC *)vc;
/**
 *  扫描失败
 */
- (void)scannerFailedVC:(SY_ScannerVC *)vc;
@end

/**
 *  扫描方式
 */
typedef NS_ENUM(NSUInteger, SYScannerType){
    /**
     *  ZBar扫描
     */
    SYScannerTypeZbar,
    /**
     *  系统扫描
     */
    SYScannerTypeSystem
};

@interface SY_ScannerVC : UIViewController

/**
 *  扫描方式
 */
@property (nonatomic, assign) SYScannerType mType;

/**
 *  扫描结果
 */
@property (nonatomic, strong) NSString *resultString;

/**
 *  代理
 */
@property (nonatomic, assign) id <SYScannerVC_Delegate> m_delegate;

/**
 *  扫描结束
 */
- (void)resultMethod;

/**
 *  继续扫描
 */
- (void)scanVCContinue:(BOOL)animation;

/**
 *  暂停扫描
 */
- (void)scanVCStop:(BOOL)animation;

/**
 *  释放扫描器
 */
- (void)scanVCDealloc;

@end
