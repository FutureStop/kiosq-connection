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

// Should be called every time a central manager scans and sees and update on a peripheral's signal strength
- (void)receivedSignalStrengthRSSI:(NSNumber *)RSSI forPeripheral:(CBPeripheral *)peripheral;

@end


@protocol FSRangeFinderDelegate <NSObject>

// Called when a peripheral is within appropriate range of the central manager device
- (void)rangeFinder:(FSRangeFinder *)rangeFinder didUpdateToClosestPeripheral:(CBPeripheral *)peripheral;

// Called when the controlling peripheral goes out of range or stops updating it's position relative to the manager
- (void)rangeFinder:(FSRangeFinder *)rangeFinder didReleaseControlFromPeripheral:(CBPeripheral *)peripheral;

@end