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

- (void)startScanWithFenceServiceUUID:(NSString *)serviceUUID
                   characteristicUUID:(NSString *)characteristicUUID
                      fenceEntryBlock:(void (^)(CBPeripheral *enteringPeripheral))entryBlock
                    fenceLeavingBlock:(void (^)(CBPeripheral *leavingPeripheral))leavingBlock;

- (void)stopScanning;

@end
