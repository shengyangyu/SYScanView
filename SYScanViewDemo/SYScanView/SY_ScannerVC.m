//
//  SY_ScannerVC.m
//  u_shop
//
//  Created by yushengyang on 15/5/14.
//  Copyright (c) 2015年 yushengyang. All rights reserved.
//
//#if ! __has_feature(objc_arc)
//#error file is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
//#endif

#import "SY_ScannerVC.h"
#import "SY_Scanner.h"
#import "SY_BGView.h"
#import "MBProgressHUD.h"

@interface SY_ScannerVC ()<SY_ScannerDelegate>
{
    MBProgressHUD *m_HUD;
}
/**
 *  系统扫描器
 */
@property (strong, nonatomic) SY_Scanner *mScanner;
/**
 *  扫描器滚动动画View 为Zbar添加
 */
@property (strong, nonatomic) SY_BGView *mOtherView;
/**
 *  CustomerUI View 自定义按钮
 */
@property (strong, nonatomic) UIView *mCustomerUI;

@end

@implementation SY_ScannerVC

- (void)becomeActiveMethod:(NSNotification *)notification {
   [self.mOtherView initLine];
}

- (void)WillEnterForegroundMethod:(NSNotification *)notification {
    [self.mOtherView removeLine];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"扫描条形码";
    self.view.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0];
    if (1) {//IOS7_OR_LATER
        self.mType = SYScannerTypeSystem;
    }
    //加载UI
    [self customerUI];
    // 进入后台返回
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(becomeActiveMethod:) name:UIApplicationDidBecomeActiveNotification object:nil];
    // 进入后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WillEnterForegroundMethod:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [self.mOtherView startLineAnimation];
    // zbar 初始化
    if (self.mType == SYScannerTypeZbar) {
        [self scanVCContinue:YES];
    }
    // 系统的初始化在viewDidAppear
    else {
        [self HUDShow:@"加载中"];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self scanVCContinue:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    [self scanVCStop:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self scanVCDealloc];
}

// 自定义页面UI
- (void)customerUI {
    CGFloat offset_y = 44.0f;
    // 扫描背景
    self.mOtherView = [[SY_BGView alloc] initWithFrame:CGRectMake(0, offset_y, __MainScreen_Width, __viewContent_hight1) withClearFrame:CGRectMake(SCan_Offset_x, offset_y+SCan_Offset_y, SCan_Size, SCan_Size)];
    [self.view addSubview:self.mOtherView];
    // 自定义UI
    self.mCustomerUI = [[UIView alloc] initWithFrame:CGRectMake(0, offset_y, __MainScreen_Width, __viewContent_hight1)];
    self.mCustomerUI.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.mCustomerUI];
    // 提示文字
    ({
        UILabel *lab = [[UILabel alloc] init];
        lab.backgroundColor = [UIColor clearColor];
        lab.frame = CGRectMake(0, offset_y, ScreenWidth, SCan_Offset_y);
        lab.textAlignment = NSTextAlignmentCenter;
        lab.font = [UIFont systemFontOfSize:16.0];
        lab.textColor = [UIColor whiteColor];
        lab.text = @"将条码置于框内,即可自动扫描";
        [self.mCustomerUI addSubview:lab];
    });
    CGFloat BottomBtnSize_h = 82.0f;
    // 阴影
    ({
        UIView *backView = [[UIView alloc] initWithFrame:CGRectMake(0, __viewContent_hight1-BottomBtnSize_h,__MainScreen_Width,BottomBtnSize_h)];
        backView.alpha = 0.3;
        backView.backgroundColor = [UIColor blackColor];
        [self.mCustomerUI addSubview:backView];
    });
    // 底部两个按钮
    ({
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setFrame:CGRectMake(0, __viewContent_hight1-BottomBtnSize_h, __MainScreen_Width/2, BottomBtnSize_h)];
        [btn setTitle:@"结束扫描" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn.titleLabel setFont:[UIFont systemFontOfSize:11]];
        [btn setImage:[UIImage imageNamed:@"scan_cancel"] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(cancelMethod) forControlEvents:UIControlEventTouchUpInside];
        [self.mCustomerUI addSubview:btn];
        [self setButtonEdge:btn withSize:BottomBtnSize_h];
        
    });
    ({
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setFrame:CGRectMake(__MainScreen_Width/2, __viewContent_hight1-BottomBtnSize_h, __MainScreen_Width/2, BottomBtnSize_h)];
        [btn setTitle:@"打开闪光灯" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn.titleLabel setFont:[UIFont systemFontOfSize:11]];
        [btn setImage:[UIImage imageNamed:@"scan_torch"] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(torchMethod:) forControlEvents:UIControlEventTouchUpInside];
        [self.mCustomerUI addSubview:btn];
        [self setButtonEdge:btn withSize:BottomBtnSize_h];
    });
}

- (void)setButtonEdge:(UIButton *)btn withSize:(CGFloat)BottomBtnSize_h {
    // 设置图片和标题的位置
    CGPoint btnBoundsCenter = CGPointMake(CGRectGetMidX(btn.bounds), CGRectGetMidY(btn.bounds));
    // 找出imageView最终的center
    CGPoint endImageViewCenter = CGPointMake(btnBoundsCenter.x, CGRectGetMidY(btn.imageView.bounds));
    // 找出titleLabel最终的center
    CGPoint endTitleLabelCenter = CGPointMake(btnBoundsCenter.x, CGRectGetHeight(btn.bounds)-CGRectGetMidY(btn.titleLabel.bounds));
    // 取得imageView最初的center
    CGPoint startImageViewCenter = btn.imageView.center;
    // 取得titleLabel最初的center
    CGPoint startTitleLabelCenter = btn.titleLabel.center;
    // 设置imageEdgeInsets
    CGFloat imageEdgeInsetsTop = endImageViewCenter.y - startImageViewCenter.y;
    CGFloat imageEdgeInsetsLeft = endImageViewCenter.x - startImageViewCenter.x;
    CGFloat imageEdgeInsetsBottom = -imageEdgeInsetsTop;
    CGFloat imageEdgeInsetsRight = -imageEdgeInsetsLeft;
    btn.imageEdgeInsets = UIEdgeInsetsMake(imageEdgeInsetsTop+BottomBtnSize_h*0.30, imageEdgeInsetsLeft, imageEdgeInsetsBottom-BottomBtnSize_h*0.10, imageEdgeInsetsRight);
    // 设置titleEdgeInsets
    CGFloat titleEdgeInsetsTop = endTitleLabelCenter.y-startTitleLabelCenter.y;
    CGFloat titleEdgeInsetsLeft = endTitleLabelCenter.x - startTitleLabelCenter.x;
    CGFloat titleEdgeInsetsBottom = -titleEdgeInsetsTop;
    CGFloat titleEdgeInsetsRight = -titleEdgeInsetsLeft;
    btn.titleEdgeInsets = UIEdgeInsetsMake(titleEdgeInsetsTop-BottomBtnSize_h*0.10, titleEdgeInsetsLeft, titleEdgeInsetsBottom-BottomBtnSize_h*0.10, titleEdgeInsetsRight);
}

- (void)cancelMethod {
    if ([self.m_delegate respondsToSelector:@selector(scannerCancleVC:)]) {
        [self.m_delegate scannerCancleVC:self];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)torchMethod:(UIButton *)sender {
    
    if (self.mType == SYScannerTypeSystem && [self.mScanner torchMode]) {
        if (self.mScanner.isOpenTorch) {
            [sender setTitle:@"关闭闪光灯" forState:UIControlStateNormal];
        }
        else {
            [sender setTitle:@"打开闪光灯" forState:UIControlStateNormal];
        }
    }
}

#pragma mark - 系统扫描iOS7
#pragma mark -Scanner
- (SY_Scanner *)mScanner {
    
    if (!_mScanner) {
        _mScanner = [[SY_Scanner alloc] initWithPreviewView:self.view];
        _mScanner.delegate = self;
        [self startScanning];
    }
    return _mScanner;
}

#pragma mark -Scanning
- (void)startScanning {
    
    [self.mScanner startScanningWithResultBlock:^(NSArray *codes) {
        if (codes.count > 0) {
            // 结果
            self.resultString = nil;
            AVMetadataMachineReadableCodeObject *obj = codes[0];
            if (obj.stringValue &&
                ![obj.stringValue isEqualToString:@""] &&
                obj.stringValue.length > 0) {
                AudioServicesPlaySystemSound(1106);
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                NSLog(@"Found unique code: %@", obj.stringValue);
                // 结果
                self.resultString = [NSString stringWithFormat:@"%@",obj.stringValue];
                if ([self.m_delegate respondsToSelector:@selector(scannerSuccessVC:resultCode:)]) {
                    [self.m_delegate scannerSuccessVC:self resultCode:obj.stringValue];
                }
            }
            else {
                if ([self.m_delegate respondsToSelector:@selector(scannerFailedVC:)]) {
                    [self.m_delegate scannerFailedVC:self];
                }
            }
        } else {
            if ([self.m_delegate respondsToSelector:@selector(scannerFailedVC:)]) {
                [self.m_delegate scannerFailedVC:self];
            }
        }
        [self scanVCStop:NO];
        [self resultMethod];
    }];
}

- (void)scanVCContinue:(BOOL)animation {
    if (self.mType == SYScannerTypeSystem) {
        // 开始扫描
        [self.mScanner startSessionScann];
    }
    // 开始扫描动画
    [self.mOtherView startLineAnimation];
}

- (void)scanVCStop:(BOOL)animation {
    if (self.mType == SYScannerTypeSystem) {
        if (self.mScanner.isOpenTorch) {
            [self.mScanner torchMode];
        }
        [self.mScanner stopSessionScann];
    }
    // 结束扫描动画
    [self.mOtherView stopLineAnimation];
}

- (void)scanVCDealloc {
    
    if (self.mType == SYScannerTypeSystem) {
        if (_mScanner) {
            [_mScanner stopScanning];
            _mScanner = nil;
        }
    }
}

- (void)resultMethod {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -SY_ScannerDelegate
- (void)scannerViewDidLoad {
    // 隐藏加载view
    [m_HUD hide:YES];
}

#pragma mark - MBProgressHUD Delegate
- (void)initHUD {
    if (!m_HUD) {
        m_HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:m_HUD];
        //HUD.delegate = self;
    }
}
- (void)HUDShow:(NSString*)text {
    [self initHUD];
    m_HUD.labelText = text;
    m_HUD.mode = MBProgressHUDModeIndeterminate;
    [m_HUD show:YES];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
