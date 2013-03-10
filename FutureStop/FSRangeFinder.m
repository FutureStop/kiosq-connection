//
//  FSRangeFinder.m
//  FutureStop
//
//  Created by Conrad Stoll on 3/9/13.
//  Copyright (c) 2013 Mutual Mobile SXSW Creatathon. All rights reserved.
//

#import "FSRangeFinder.h"


#define CONTROL_THRESHOLD -60
#define LEAVE_THRESHOLD -75
#define TIME_THRESHOLD 3

@interface FSPeripheral : NSObject

@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSNumber *lastUpdateTime;
@property (nonatomic, strong) NSMutableArray *rawRSSIFIFO;
@property (nonatomic, strong) CBUUID *UUID;
@property (nonatomic, strong) NSNumber *averageRSSI;
@property (nonatomic) BOOL markedAsOutOfDate;

@end

@interface FSRangeFinder ()

@property (nonatomic, strong) NSTimer *timer;
@property (strong, nonatomic) NSMutableDictionary *peripherals;
@property (nonatomic, strong) FSPeripheral *controllingPeripheral;

@end

@implementation FSRangeFinder

- (id)init {
    if ((self = [super init])) {
        _timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(didUpdateTimer:) userInfo:nil repeats:YES];
        _peripherals = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)receivedSignalStrengthRSSI:(NSString *)RSSI forPeripheral:(CBPeripheral *)peripheral {
    NSString *peripheralAddress = [NSString stringWithFormat:@"%p", peripheral];

    const NSInteger kFIFOLength = 20;
    
    FSPeripheral *myPeripheral = [self.peripherals objectForKey:peripheralAddress];

    NSMutableArray *rawRSSIFIFO = myPeripheral.rawRSSIFIFO;
    
    if (rawRSSIFIFO == nil)
        rawRSSIFIFO = [NSMutableArray array];
    
    NSMutableArray *newRSSIFIFO = [NSMutableArray arrayWithObject:RSSI];
    [newRSSIFIFO addObjectsFromArray:rawRSSIFIFO];
    
    if (newRSSIFIFO.count > kFIFOLength)
        [newRSSIFIFO removeLastObject];
    
    rawRSSIFIFO = newRSSIFIFO;
    NSInteger totalRSSI = 0;
    for (NSNumber *rssi in rawRSSIFIFO) {
        totalRSSI += rssi.integerValue;
    }
    
    NSInteger averageRSSI = 0;
    if (rawRSSIFIFO.count > 1)
        averageRSSI = roundf(totalRSSI / (int)[rawRSSIFIFO count]);
    
    myPeripheral.rawRSSIFIFO = rawRSSIFIFO;
    myPeripheral.averageRSSI = @(averageRSSI);
    myPeripheral.lastUpdateTime = @([NSDate timeIntervalSinceReferenceDate]);
    myPeripheral.markedAsOutOfDate = NO;
        
    if (peripheral.UUID) {
        myPeripheral.UUID = [CBUUID UUIDWithCFUUID:peripheral.UUID];
    }
}

- (void)releaseControl {
    [self.delegate rangeFinder:self didReleaseControlFromPeripheral:self.controllingPeripheral.peripheral];
    self.controllingPeripheral = nil;
}

- (void)didUpdateTimer:(id)sender {
    NSMutableArray *nearbyPeripherals = [NSMutableArray array];
    NSMutableArray *nearAndRecentPeripherals = [NSMutableArray array];
    
    for (FSPeripheral *peripheral in self.peripherals) {
        if ([peripheral.averageRSSI intValue] > CONTROL_THRESHOLD) {
            [nearbyPeripherals addObject:peripheral];
        }
    }
    
    for (FSPeripheral *peripheral in nearbyPeripherals) {
        if ([peripheral.lastUpdateTime intValue] > TIME_THRESHOLD) {
            peripheral.markedAsOutOfDate = YES;
        } else {
            [nearAndRecentPeripherals addObject:peripheral];
        }
    }
    
    if ([nearAndRecentPeripherals count] == 0) {
        [self releaseControl];
        return;
    } 
    
    [nearbyPeripherals sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"lastUpdateTime" ascending:YES]]];
    
    for (FSPeripheral *peripheral in nearbyPeripherals) {
        if (peripheral.markedAsOutOfDate == NO && self.controllingPeripheral == nil) {
            [self.delegate rangeFinder:self didUpdateToClosestPeripheral:peripheral.peripheral];
            return;
        }
    }    
}

@end
