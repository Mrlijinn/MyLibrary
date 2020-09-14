//
//  JDViewController.m
//  FBSnapshotTestCase
//
//  Created by 李晋 on 2020/9/8.
//

#import "JDViewController.h"

@interface JDViewController ()

@end

@implementation JDViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cashier_close_round_yellow"]];
    [self.view addSubview:imageView];
    imageView.center = self.view.center;
    [self.view setBackgroundColor:[UIColor whiteColor]];
}

@end
