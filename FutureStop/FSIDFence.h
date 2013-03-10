//
//  FSIDFence.h
//  FutureStop
//
//  Created by Conrad Stoll on 3/9/13.
//  Copyright (c) 2013 Mutual Mobile SXSW Creatathon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface FSIDFence : NSObject

/** 
 Starts scanning for devices entering the fenced area for a specified service and characteristic UUID.
 
 @param serviceUUID A service UUID for CoreBluetooth
 @param characteristicUUID A characteristic UUID for CoreBluetooth
 @param entryBlock A block to be called when a peripheral device enters the fence
 @param leavingBlock A block to be called when a peripheral device leaves the fenced area
 @discussion Pass nil for UUIDs for a default demo mode UUID.
 */
- (void)startScanWithFenceServiceUUID:(NSString *)serviceUUID
                   characteristicUUID:(NSString *)characteristicUUID
                      fenceEntryBlock:(void (^)(CBPeripheral *enteringPeripheral))entryBlock
                    fenceLeavingBlock:(void (^)(CBPeripheral *leavingPeripheral))leavingBlock;

- (void)stopScanning;

@end
