//
//  ViewController.m
//  RunloopDetection
//
//  Created by 超级腕电商 on 2018/4/11.
//  Copyright © 2018年 超级腕电商. All rights reserved.
//

#import "ViewController.h"
#import "SemaphoreDetection.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[SemaphoreDetection sharedInstance] startDetection];//开始监听
    
    self.view.backgroundColor = [UIColor whiteColor];
    UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(100, 100, 100, 100)];
    button.backgroundColor = [UIColor redColor];
    [button setTitle:@"人为卡顿" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(runLongTime) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)runLongTime{
    for ( int i = 0 ; i < 10000 ; i ++ ){
        NSLog(@"%d",i);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
