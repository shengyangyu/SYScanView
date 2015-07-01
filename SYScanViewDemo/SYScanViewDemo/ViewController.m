//
//  ViewController.m
//  SYScanViewDemo
//
//  Created by yushengyang on 15/7/1.
//  Copyright (c) 2015年 yushengyang. All rights reserved.
//

#import "ViewController.h"
#import "DemoScanner.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)sacn:(UIButton *)sender {
    DemoScanner *scan = [[DemoScanner alloc] init];
    [self.navigationController pushViewController:scan animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
