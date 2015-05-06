/**
 * @file CameraUploads.h
 * @brief Uploads assets from device to your mega account
 *
 * (c) 2013-2015 by Mega Limited, Auckland, New Zealand
 *
 * This file is part of the MEGA SDK - Client Access Engine.
 *
 * Applications using the MEGA API must present a valid application key
 * and comply with the the rules set forth in the Terms of Service.
 *
 * The MEGA SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * @copyright Simplified (2-clause) BSD License.
 *
 * You should have received a copy of the license along with this
 * program.
 */

#import <Foundation/Foundation.h>
#import "MEGASdkManager.h"

#define kIsCameraUploadsEnabled @"IsCameraUploadsEnabled"
#define kIsUploadVideosEnabled @"IsUploadVideosEnabled"
#define kIsUseCellularConnectionEnabled @"IsUseCellularConnectionEnabled"
#define kIsOnlyWhenChargingEnabled @"IsOnlyWhenChargingEnabled"

@interface CameraUploads : NSObject <NSFileManagerDelegate, MEGAGlobalDelegate, MEGARequestDelegate, MEGATransferDelegate, UITabBarControllerDelegate>

@property (nonatomic, strong) NSMutableArray *assetUploadArray;

@property (nonatomic, weak) UITabBarController *tabBarController;

@property BOOL isCameraUploadsEnabled;
@property BOOL isUploadVideosEnabled;
@property BOOL isUseCellularConnectionEnabled;
@property BOOL isOnlyWhenChargingEnabled;

@property (nonatomic, strong) NSDate *lastUploadPhotoDate;
@property (nonatomic, strong) NSDate *lastUploadVideoDate;

+ (CameraUploads *)syncManager;
- (void)getAllAssetsForUpload;

@end
