//
//  MMNameTagReader.m
//  ReaderKit
//
//  Created by Conrad Stoll on 3/9/13.
//  Copyright (c) 2013 Mutual Mobile. All rights reserved.
//

#import "MMNameTagReader.h"

#import <CoreBluetooth/CoreBluetooth.h>

@interface MMNameTagReader ()<CBCentralManagerDelegate>

@end

@implementation MMNameTagReader

- (void)scanForNameTags {
    
    CBCentralManager *manager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_global_queue(0, 0)];
    
}

@end
