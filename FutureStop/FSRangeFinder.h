//
//  FSRangeFinder.h
//  FutureStop
//
//  Created by Conrad Stoll on 3/9/13.
//  Copyright (c) 2013 Mutual Mobile SXSW Creatathon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol FSRangeFinderDelegate;


@interface FSRangeFinder : NSObject

@property (nonatomic, weak) id<FSRangeFinderDelegate> delegate;

- (void)receivedSignalStrengthRSSI:(NSNumber *)RSSI forPeripheral:(CBPeripheral *)peripheral;

@end


@protocol FSRangeFinderDelegate <NSObject>

- (void)rangeFinder:(FSRangeFinder *)rangeFinder didUpdateToClosestPeripheral:(CBPeripheral *)peripheral;

- (void)rangeFinder:(FSRangeFinder *)rangeFinder didReleaseControlFromPeripheral:(CBPeripheral *)peripheral;

@end