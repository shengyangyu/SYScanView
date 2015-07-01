//
//  SY_Scanner.m
//  u_shop
//
//  Created by yushengyang on 15/5/14.
//  Copyright (c) 2015年 yushengyang. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error file is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#import "SY_Scanner.h"
#import <QuartzCore/QuartzCore.h>

@interface SY_Scanner ()<AVCaptureMetadataOutputObjectsDelegate>

/**
 *  相机
 */
@property (strong, nonatomic) AVCaptureSession *session;

/**
 *  摄像头输出视频
 */
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *capturePreviewLayer;

/**
 *  支持的解码方式 默认当前系统支持的所有方式
 */
@property (strong, nonatomic) NSArray *metaDataObjectTypes;

/**
 *  显示扫码的父View
 */
@property (weak, nonatomic) UIView *previewView;

/**
 *  扫码结果
 */
@property (nonatomic, copy) void (^resultBlock)(NSArray *codes);

/**
 *  是否已经在扫码
 */
@property (nonatomic, assign) BOOL hasExistingSession;


@end

/**
 *  相机对焦
 */
CGFloat const kSYFocalPointOfInterestX = 0.5;
CGFloat const kSYFocalPointOfInterestY = 0.5;

@implementation SY_Scanner

#pragma mark - 初始化和释放
- (instancetype)init {
    NSAssert(NO, @"本方法不支持此初始化方式,请看文档.");
    return nil;
}

- (instancetype)initWithPreviewView:(UIView *)previewView {
    NSParameterAssert(previewView);
    self = [super init];
    if (self) {
        _previewView = previewView;
        _metaDataObjectTypes = [self defaultMetaDataObjectTypes];
        //[self addRotationObserver];
    }
    return self;
}

- (instancetype)initWithMetadataObjectTypes:(NSArray *)metaDataObjectTypes
                                previewView:(UIView *)previewView {
    NSParameterAssert(metaDataObjectTypes);
    NSParameterAssert(previewView);
    self = [super init];
    if (self) {
        NSAssert(!([metaDataObjectTypes indexOfObject:AVMetadataObjectTypeFace] != NSNotFound),
                 @"扫码不支持人脸识别%@.", AVMetadataObjectTypeFace);
        
        _metaDataObjectTypes = metaDataObjectTypes;
        _previewView = previewView;
        //[self addRotationObserver];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 扫码

+ (BOOL)cameraIsPresent {
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

+ (BOOL)scanningIsProhibited {
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            return YES;
            break;
            
        default:
            return NO;
            break;
    }
}

+ (void)requestCameraPermissionWithSuccess:(void (^)(BOOL success))successBlock {
    
    if (![self cameraIsPresent]) {
        successBlock(NO);
        return;
    }
    
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusAuthorized:
            successBlock(YES);
            break;
            
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            successBlock(NO);
            break;
            
        case AVAuthorizationStatusNotDetermined:
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                                     completionHandler:^(BOOL granted) {
                                         
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             successBlock(granted);
                                         });
                                         
                                     }];
            break;
    }
}

- (void)startScanningWithResultBlock:(void (^)(NSArray *codes))resultBlock {
    
    NSAssert([SY_Scanner cameraIsPresent], @"没有相机.");
    NSAssert(![SY_Scanner scanningIsProhibited], @"没有权限.");
    
    self.resultBlock = resultBlock;
    
    if (!self.hasExistingSession) {
        AVCaptureDevice *captureDevice = [self newCaptureDeviceWithCamera:self.camera];
        self.session = [self newSessionWithCaptureDevice:captureDevice];
        self.hasExistingSession = YES;
    }
    [self startSessionScann];
    
    self.capturePreviewLayer.cornerRadius = self.previewView.layer.cornerRadius;
    [self.previewView.layer insertSublayer:self.capturePreviewLayer atIndex:0];
    //动画显示
    self.capturePreviewLayer.opacity = 0.0;
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.toValue = [NSNumber numberWithFloat:1.0];
    animation.fromValue = [NSNumber numberWithFloat:self.capturePreviewLayer.opacity];
    animation.duration = 1.0;
    self.capturePreviewLayer.opacity = 1.0;
    [self.capturePreviewLayer addAnimation:animation forKey:@"animateOpacity"];
    [self refreshVideoOrientation];
}

- (void)stopScanning {
    if (self.hasExistingSession) {
        
        self.hasExistingSession = NO;
        [self.capturePreviewLayer removeFromSuperlayer];
        __weak __typeof(self)weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            for(AVCaptureInput *input in self.session.inputs) {
                [strongSelf.session removeInput:input];
            }
            for(AVCaptureOutput *output in self.session.outputs) {
                [strongSelf.session removeOutput:output];
            }
            [strongSelf stopSessionScann];
            strongSelf.session = nil;
            strongSelf.resultBlock = nil;
            strongSelf.capturePreviewLayer = nil;
        });
    }
}

- (BOOL)isScanning {
    return [self.session isRunning];
}

- (void)stopSessionScann {
    if (_session && _session.running) {
        self.isReading = YES;
        [self.session stopRunning];
    }
}

- (void)startSessionScann {
    if (_session && !_session.running) {
        self.isReading = NO;
        [self.session startRunning];
        // 调用加载完成
        if ([self.delegate respondsToSelector:@selector(scannerViewDidLoad)]) {
            [self.delegate scannerViewDidLoad];
        }
    }
}


- (void)flipCamera {
    if (self.isScanning) {
        if (self.camera == SYCameraFront) {
            self.camera = SYCameraBack;
        } else {
            self.camera = SYCameraFront;
        }
    }
}

- (BOOL)torchMode {
    if (self.isScanning) {
        AVCaptureDevice *captureDevice = [self newCaptureDeviceWithCamera:self.camera];
        if ([captureDevice hasTorch]) {
            if(self.isOpenTorch) {
                [captureDevice lockForConfiguration:nil];
                captureDevice.torchMode = AVCaptureTorchModeOff;
                [captureDevice unlockForConfiguration];
                self.isOpenTorch = NO;
            }
            else {
                [captureDevice lockForConfiguration:nil];
                captureDevice.torchMode = AVCaptureTorchModeOn;
                [captureDevice unlockForConfiguration];
                self.isOpenTorch = YES;
            }
            return YES;
        }
        else {
            return NO;
        }
    }
    else {
        return NO;
    }
}

#pragma mark - AVCaptureMetadataOutputObjects Delegate代理方法

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    
    if (self.isReading) return;
    
    NSMutableArray *codes = [[NSMutableArray alloc] init];
    
    for (AVMetadataObject *metaData in metadataObjects) {
        AVMetadataMachineReadableCodeObject *barCodeObject = (AVMetadataMachineReadableCodeObject *)[self.capturePreviewLayer transformedMetadataObjectForMetadataObject:(AVMetadataMachineReadableCodeObject *)metaData];
        if (barCodeObject) {
            [codes addObject:barCodeObject];
        }
    }
    
    if (self.resultBlock) {
        if (self.isReading) {
            return;
        }
        self.isReading = YES;
        self.resultBlock(codes);
    }
}

#pragma mark - 屏幕旋转

- (void)handleDeviceOrientationDidChangeNotification:(NSNotification *)notification {
    [self refreshVideoOrientation];
}

- (void)refreshVideoOrientation {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    self.capturePreviewLayer.frame = self.previewView.bounds;
    if ([self.capturePreviewLayer.connection isVideoOrientationSupported]) {
        self.capturePreviewLayer.connection.videoOrientation = [self captureOrientationForInterfaceOrientation:orientation];
    }
}

- (AVCaptureVideoOrientation)captureOrientationForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            return AVCaptureVideoOrientationPortrait;
        case UIInterfaceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
        case UIInterfaceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeLeft;
        case UIInterfaceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeRight;
        default:
            return AVCaptureVideoOrientationPortrait;
    }
}

#pragma mark - 扫码设置 视频输入输出流

- (AVCaptureSession *)newSessionWithCaptureDevice:(AVCaptureDevice *)captureDevice {
    
    AVCaptureSession *newSession = [[AVCaptureSession alloc] init];
    AVCaptureDeviceInput *input = [self deviceInputForCaptureDevice:captureDevice];
    
    // 读取质量，质量越高，可读取小尺寸的二维码
    if ([newSession canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
        [newSession setSessionPreset:AVCaptureSessionPreset1920x1080];
    }
    else if ([newSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        [newSession setSessionPreset:AVCaptureSessionPreset1280x720];
    }
    else {
        [newSession setSessionPreset:AVCaptureSessionPresetPhoto];
    }
    [newSession addInput:input];
    
    AVCaptureMetadataOutput *captureOutput = [[AVCaptureMetadataOutput alloc] init];
    [captureOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [captureOutput setRectOfInterest:[self getReaderViewBoundsWithSize:CGSizeMake(ScreenWidth, SCan_Size)]];
    
    [newSession addOutput:captureOutput];
    captureOutput.metadataObjectTypes = self.metaDataObjectTypes;
    
    self.capturePreviewLayer = nil;
    self.capturePreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:newSession];
    self.capturePreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.capturePreviewLayer.frame = self.previewView.bounds;
    
    [newSession commitConfiguration];
    
    return newSession;
}

- (CGRect)getReaderViewBoundsWithSize:(CGSize)asize {
    return CGRectMake(SCan_Offset_y / ScreenHigh, ((ScreenWidth - asize.width) / 2.0) / ScreenWidth, asize.height / ScreenHigh, asize.width / ScreenWidth);
}

- (AVCaptureDeviceInput *)deviceInputForCaptureDevice:(AVCaptureDevice *)captureDevice {
    NSError *inputError = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice
                                                                        error:&inputError];
    
    if (!input) {
        NSLog(@"视频加载错误: %@", inputError);
    }
    
    return input;
}

- (AVCaptureDevice *)newCaptureDeviceWithCamera:(SYCamera)camera {
    
    AVCaptureDevice *mNewCaptureDevice = nil;
    NSError *lockError = nil;
    
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevicePosition position = [self devicePositionForCamera:camera];
    for (AVCaptureDevice *device in videoDevices) {
        if (device.position == position) {
            mNewCaptureDevice = device;
            break;
        }
    }
    
    // 摄像头输出视频
    if (!mNewCaptureDevice) {
        mNewCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        // 默认是关闭灯
        [mNewCaptureDevice lockForConfiguration:nil];
        mNewCaptureDevice.torchMode = AVCaptureTorchModeOff;
        [mNewCaptureDevice unlockForConfiguration];
        self.isOpenTorch = NO;
    }
    
    if ([mNewCaptureDevice lockForConfiguration:&lockError] == YES) {
        
        // 自动对焦范围
        if ([mNewCaptureDevice respondsToSelector:@selector(isAutoFocusRangeRestrictionSupported)] &&
            mNewCaptureDevice.isAutoFocusRangeRestrictionSupported) {
            mNewCaptureDevice.autoFocusRangeRestriction = AVCaptureAutoFocusRangeRestrictionNear;
        }
        
        // 设置对焦在中间
        if ([mNewCaptureDevice respondsToSelector:@selector(isFocusPointOfInterestSupported)] &&
            mNewCaptureDevice.isFocusPointOfInterestSupported) {
            mNewCaptureDevice.focusPointOfInterest = CGPointMake(kSYFocalPointOfInterestX, kSYFocalPointOfInterestY);
        }
        
        [mNewCaptureDevice unlockForConfiguration];
    }
    
    return mNewCaptureDevice;
}

- (AVCaptureDevicePosition)devicePositionForCamera:(SYCamera)camera {
    switch (camera) {
        case SYCameraFront:
            return AVCaptureDevicePositionFront;
        case SYCameraBack:
            return AVCaptureDevicePositionBack;
        default:
            return AVCaptureDevicePositionUnspecified;
            break;
    }
}

#pragma mark - 默认值

- (NSArray *)defaultMetaDataObjectTypes {
    NSMutableArray *types = [@[AVMetadataObjectTypeQRCode,
                               AVMetadataObjectTypeUPCECode,
                               AVMetadataObjectTypeCode39Code,
                               AVMetadataObjectTypeCode39Mod43Code,
                               AVMetadataObjectTypeEAN13Code,
                               AVMetadataObjectTypeEAN8Code,
                               AVMetadataObjectTypeCode93Code,
                               AVMetadataObjectTypeCode128Code,
                               AVMetadataObjectTypePDF417Code,
                               AVMetadataObjectTypeAztecCode] mutableCopy];
    
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
        [types addObjectsFromArray:@[
                                     AVMetadataObjectTypeInterleaved2of5Code,
                                     AVMetadataObjectTypeITF14Code,
                                     AVMetadataObjectTypeDataMatrixCode
                                     ]];
    }
    
    return types;
}

#pragma mark - 屏幕旋转

- (void)addRotationObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDeviceOrientationDidChangeNotification:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

#pragma mark - 前后摄像头设置

- (void)setCamera:(SYCamera)camera {
    
    if (self.isScanning && camera != _camera) {
        
        for (AVCaptureInput *input in self.session.inputs) {
            [self.session removeInput:input];
        }
        
        AVCaptureDevice *captureDevice = [self newCaptureDeviceWithCamera:camera];
        AVCaptureDeviceInput *input = [self deviceInputForCaptureDevice:captureDevice];
        [self.session addInput:input];
    }
    _camera = camera;
}


@end
