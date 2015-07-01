//
//  DemoScanner.m
//  SYScanViewDemo
//
//  Created by yushengyang on 15/7/1.
//  Copyright (c) 2015年 yushengyang. All rights reserved.
//

#import "DemoScanner.h"

@interface DemoScanner ()

@end

@implementation DemoScanner

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)resultMethod {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"result" message:self.resultString delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alert show];
    [self.navigationController popViewControllerAnimated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
