//
//  FSFenceViewController.m
//  FutureStop
//
//  Created by Conrad Stoll on 3/9/13.
//  Copyright (c) 2013 Mutual Mobile SXSW Creatathon. All rights reserved.
//

#import "FSFenceViewController.h"

#import "FSIDFence.h"

@interface FSFenceViewController ()

@property (nonatomic, weak) IBOutlet UILabel *label;
@property (nonatomic, strong) FSIDFence *fence;

@end

@implementation FSFenceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
    self.fence = [[FSIDFence alloc] init];
    [self.fence startScanWithFenceServiceUUID:nil characteristicUUID:nil fenceEntryBlock:^(CBPeripheral *enteringPeripheral) {
        self.label.text = [NSString stringWithFormat:@"%p", enteringPeripheral];
    } fenceLeavingBlock:^(CBPeripheral *leavingPeripheral) {
        self.label.text = @"";
    }];
}

@end
