//
//  FSIDFence.m
//  FutureStop
//
//  Created by Conrad Stoll on 3/9/13.
//  Copyright (c) 2013 Mutual Mobile SXSW Creatathon. All rights reserved.
//

#import "FSIDFence.h"

#import <CoreBluetooth/CoreBluetooth.h>

#import "FSRangeFinder.h"

typedef void (^FSIDFenceEntryBlock)(CBPeripheral *enteringPeripheral);
typedef void (^FSIDFenceLeavingBlock)(CBPeripheral *leavingPeripheral);

@interface FSIDFence () <CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDataSource, UITableViewDelegate, FSRangeFinderDelegate>

@property (strong, nonatomic) CBCentralManager      *centralManager;

@property (nonatomic, strong) CBUUID                *controlingUUID;
@property (nonatomic, strong) CBPeripheral          *controlingPeripheral;

@property (nonatomic, strong) FSRangeFinder         *rangeFinder;

@property (nonatomic, copy) FSIDFenceEntryBlock     entryBlock;
@property (nonatomic, copy) FSIDFenceLeavingBlock   leavingBlock;
@property (nonatomic, copy) NSString                *serviceUUID;
@property (nonatomic, copy) NSString                *characteristicUUID;

@end

@implementation FSIDFence

- (id)init {
    if ((self = [super init])) {
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        self.rangeFinder = [[FSRangeFinder alloc] init];
        self.rangeFinder.delegate = self;
    }
    return self;
}

- (void)startScanWithFenceServiceUUID:(NSString *)UUID
                      characteristicUUID:(NSString *)characteristicUUID
                      fenceEntryBlock:(void (^)(CBPeripheral *))entryBlock fenceLeavingBlock:(void (^)(CBPeripheral *))leavingBlock {
    self.entryBlock = entryBlock;
    self.leavingBlock = leavingBlock;
    self.serviceUUID = UUID;
    self.characteristicUUID = characteristicUUID;
    
    if (self.serviceUUID == nil) {
        self.serviceUUID = @"E20A39F4-73F5-4BC4-A12F-17D1AD07A961";
    }
    
    if (self.characteristicUUID == nil) {
        self.characteristicUUID = @"08590F7E-DB05-467E-8757-72F6FAEB13D4";
    }
    
    [self scan];
}

- (void)scan {
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:self.serviceUUID]]
                                                options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
    
    [self.centralManager retrieveConnectedPeripherals];
}

- (void)stopScanning {
    [self releaseControlFromPeripheral:self.controlingPeripheral];
    
    [self.centralManager stopScan];
}

- (void)establishControlForPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"%@ Controlling Screen", peripheral);

    self.controlingPeripheral = peripheral;
    self.controlingPeripheral.delegate = self;
    
    if (peripheral) {
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
    
    if (self.entryBlock) {
        self.entryBlock(peripheral);
    }
}

- (void)releaseControlFromPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"%@ Releasing Control", peripheral);

    if (peripheral) {
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
    self.controlingPeripheral = nil;
    self.controlingUUID = nil;
    
    if (self.leavingBlock) {
        self.leavingBlock(peripheral);
    }
}

#pragma mark Range

- (void)rangeFinder:(FSRangeFinder *)rangeFinder didUpdateToClosestPeripheral:(CBPeripheral *)peripheral {
    [self establishControlForPeripheral:peripheral];
}

- (void)rangeFinder:(FSRangeFinder *)rangeFinder didReleaseControlFromPeripheral:(CBPeripheral *)peripheral {
    [self releaseControlFromPeripheral:peripheral];
}


#pragma mark - Central Manager Delegate Methods

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    [self.centralManager retrieveConnectedPeripherals];
    
    [self.rangeFinder receivedSignalStrengthRSSI:RSSI forPeripheral:peripheral];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    peripheral.delegate = self;
    
    [peripheral discoverServices:@[[CBUUID UUIDWithString:self.serviceUUID]]];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [self releaseControlFromPeripheral:peripheral];
    [self scan];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state != CBCentralManagerStatePoweredOn) {
        return;
    }

    [self scan];
}


#pragma mark - Peripheral Delegate Methods

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        return;
    }
    
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:self.characteristicUUID]] forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        return;
    }
    
    // Again, we loop through the array, just in case.
    for (CBCharacteristic *characteristic in service.characteristics) {
        
        // And check if it's the right one
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:self.characteristicUUID]]) {
            
            // If it is, subscribe to it
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            
            [peripheral readValueForCharacteristic:characteristic];
        }
    }
    
    // Once this is complete, we just need to wait for the data to come in.
    [self.centralManager retrieveConnectedPeripherals];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        return;
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
    }
    
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:self.characteristicUUID]]) {
        return;
    }
    
    // Notification has started
    if (characteristic.isNotifying) {

    }
    
    // Notification has stopped
    else {

    }
}


@end
