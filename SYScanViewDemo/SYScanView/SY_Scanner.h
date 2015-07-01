//
//  SY_Scanner.h
//  u_shop
//
//  Created by yushengyang on 15/5/14.
//  Copyright (c) 2015年 yushengyang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "SY_BGView.h"

@protocol SY_ScannerDelegate <NSObject>

@optional
/**
 *  页面刷新完成
 */
- (void)scannerViewDidLoad;

@end

/**
 *  摄像头枚举
 */
typedef NS_ENUM(NSUInteger, SYCamera){
    /**
     *  背面摄像头
     */
    SYCameraBack,
    /**
     *  前置摄像头
     */
    SYCameraFront
};

@interface SY_Scanner : NSObject
/**
 *  YES 正在读取
 */
@property (nonatomic, assign) BOOL isReading;
/**
 *  YES 既是使用前置摄像头
 */
@property (nonatomic, assign) SYCamera camera;

/**
 *  YES 既是使用LED灯
 */
@property (nonatomic, assign) BOOL isOpenTorch;

/**
 * delegate
 */
@property (nonatomic, assign) id <SY_ScannerDelegate> delegate;
/**
 *  初始化扫描器
 *
 *  @param previewView 扫描父View
 *
 *  @return 扫描器
 */
- (instancetype)initWithPreviewView:(UIView *)previewView;

/**
 *  初始化扫描器
 *
 *  @param metaDataObjectTypes 扫描支持的解码方式
 *  @param previewView         扫描父View
 *
 *  @return 扫描器
 */
- (instancetype)initWithMetadataObjectTypes:(NSArray *)metaDataObjectTypes
                                previewView:(UIView *)previewView;

/**
 *  摄像头是否存在
 *
 *  @return YES 既是存在
 */
+ (BOOL)cameraIsPresent;

/**
 *  扫描是否被禁止
 *
 *  @return YES 既是禁止
 */
+ (BOOL)scanningIsProhibited;

/**
 *  申请摄像头权限
 *
 *  @param successBlock 申请返回状态Block
 */
+ (void)requestCameraPermissionWithSuccess:(void (^)(BOOL success))successBlock;

/**
 *  开启扫码
 *
 *  @param resultBlock 扫码返回状态Block
 */
- (void)startScanningWithResultBlock:(void (^)(NSArray *codes))resultBlock;

/**
 *  停止扫描 移除扫描器
 */
- (void)stopScanning;

/**
 *  停止扫描
 */
- (void)stopSessionScann;

/**
 *  开始扫描
 */
- (void)startSessionScann;


/**
 *  检测是否正在扫描
 *
 *  @return YES 正在扫描
 */
- (BOOL)isScanning;

/**
 *  翻转摄像头
 */
- (void)flipCamera;

/**
 *  开启或关闭 灯
 */
- (BOOL)torchMode;

@end
