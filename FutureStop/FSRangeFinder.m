//
//  FSRangeFinder.m
//  FutureStop
//
//  Created by Conrad Stoll on 3/9/13.
//  Copyright (c) 2013 Mutual Mobile SXSW Creatathon. All rights reserved.
//

#import "FSRangeFinder.h"


#define CONTROL_THRESHOLD -55
#define LEAVE_THRESHOLD -65
#define TIME_THRESHOLD 3

@interface FSPeripheral : NSObject

@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, copy)   NSString *address;
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
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
        _peripherals = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)receivedSignalStrengthRSSI:(NSNumber *)RSSI forPeripheral:(CBPeripheral *)peripheral {
    NSString *peripheralAddress = [NSString stringWithFormat:@"%p", peripheral];

    const NSInteger kFIFOLength = 20;
    
    FSPeripheral *myPeripheral = [self.peripherals objectForKey:peripheralAddress];
    
    if (myPeripheral == nil) {
        myPeripheral = [[FSPeripheral alloc] init];
    }

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
    
    NSLog(@"%@ RSSI: %d", peripheralAddress, averageRSSI);
    
    myPeripheral.peripheral = peripheral;
    myPeripheral.rawRSSIFIFO = rawRSSIFIFO;
    myPeripheral.averageRSSI = @(averageRSSI);
    myPeripheral.lastUpdateTime = @([NSDate timeIntervalSinceReferenceDate]);
    myPeripheral.markedAsOutOfDate = NO;
    myPeripheral.address = peripheralAddress;
    
    [self.peripherals setObject:myPeripheral forKey:peripheralAddress];
        
    if (peripheral.UUID) {
        myPeripheral.UUID = [CBUUID UUIDWithCFUUID:peripheral.UUID];
    }
}

- (void)releaseControl {
    NSLog(@"Releasing Control of Device: %@", self.controllingPeripheral.address);
    if (self.controllingPeripheral.peripheral) {
        [self.delegate rangeFinder:self didReleaseControlFromPeripheral:self.controllingPeripheral.peripheral];
    }

    self.controllingPeripheral = nil;
}

- (void)didUpdateTimer:(id)sender {
    NSMutableArray *nearbyPeripherals = [NSMutableArray array];
    NSMutableArray *nearAndRecentPeripherals = [NSMutableArray array];
    NSTimeInterval timeInterval = [NSDate timeIntervalSinceReferenceDate];

    if (self.controllingPeripheral) {
        if ([self.controllingPeripheral.averageRSSI intValue] < LEAVE_THRESHOLD) {
            [self releaseControl];
        }
        
        NSTimeInterval peripheralTimeDifference = timeInterval - [self.controllingPeripheral.lastUpdateTime intValue];

        if (peripheralTimeDifference > TIME_THRESHOLD) {
            [self releaseControl];
        }
    }
    
    NSArray *periphs = [self.peripherals allValues];
    
    for (FSPeripheral *peripheral in periphs) {
        if ([peripheral.averageRSSI intValue] > CONTROL_THRESHOLD) {
            [nearbyPeripherals addObject:peripheral];
        }
    }
    
    
    for (FSPeripheral *peripheral in nearbyPeripherals) {
        NSTimeInterval peripheralTimeDifference = timeInterval - [peripheral.lastUpdateTime intValue];
        
        NSLog(@"%@ Time: %f", peripheral.address, peripheralTimeDifference);
        
        if (peripheralTimeDifference > TIME_THRESHOLD) {
            peripheral.markedAsOutOfDate = YES;
        } else {
            [nearAndRecentPeripherals addObject:peripheral];
        }
    }
    
    [nearbyPeripherals sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"lastUpdateTime" ascending:YES]]];
    
    for (FSPeripheral *peripheral in nearbyPeripherals) {
        if (peripheral.markedAsOutOfDate == NO && self.controllingPeripheral.peripheral == nil) {
            self.controllingPeripheral = peripheral;
            NSLog(@"Establishing Control of Device: %@", peripheral.address);
            [self.delegate rangeFinder:self didUpdateToClosestPeripheral:peripheral.peripheral];
            return;
        }
    }
}

@end

@implementation FSPeripheral

@end
