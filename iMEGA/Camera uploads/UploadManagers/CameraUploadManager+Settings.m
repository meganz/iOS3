
#import "CameraUploadManager+Settings.h"

#import <Photos/PhotosTypes.h>
#import <CoreLocation/CoreLocation.h>

#import "MEGAConstants.h"
#import "NSFileManager+MNZCategory.h"
#import "MEGAReachabilityManager.h"

static NSString * const HasMigratedToCameraUploadsV2Key = @"HasMigratedToCameraUploadsV2";
static NSString * const BoardingScreenLastShowedDateKey = @"CameraUploadBoardingScreenLastShowedDate";

static NSString * const IsCameraUploadsEnabledKey = @"IsCameraUploadsEnabled";
static NSString * const IsVideoUploadsEnabledKey = @"IsUploadVideosEnabled";
static NSString * const IsCellularAllowedKey = @"IsUseCellularConnectionEnabled";
static NSString * const IsCellularForVideosAllowedKey = @"IsUseCellularConnectionForVideosEnabled";
static NSString * const ShouldConvertHEICPhotoKey = @"ShouldConvertHEICPhoto";
static NSString * const ShouldConvertHEVCVideoKey = @"ShouldConvertHEVCVideo";
static NSString * const HEVCToH264CompressionQualityKey = @"HEVCToH264CompressionQuality";
static NSString * const IsLocationBasedBackgroundUploadAllowedKey = @"IsLocationBasedBackgroundUploadAllowed";
static NSString * const UploadHiddenAlbumKey = @"UploadHiddenAlbum";
static NSString * const UploadAllBurstAssetsKey = @"UploadAllBurstAssets";
static NSString * const UploadVideosForLivePhotosKey = @"UploadVideosForLivePhotos";

static const NSTimeInterval BoardingScreenShowUpMinimumInterval = 30 * 24 * 3600;

@implementation CameraUploadManager (Settings)

#pragma mark - setting cleanups

+ (void)clearLocalSettings {
    [NSUserDefaults.standardUserDefaults removeObjectForKey:IsCameraUploadsEnabledKey];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:HasMigratedToCameraUploadsV2Key];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:BoardingScreenLastShowedDateKey];
    [self clearCameraSettings];
}

+ (void)clearCameraSettings {
    [NSUserDefaults.standardUserDefaults removeObjectForKey:IsCellularAllowedKey];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:ShouldConvertHEICPhotoKey];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:IsLocationBasedBackgroundUploadAllowedKey];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:IsVideoUploadsEnabledKey];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:UploadHiddenAlbumKey];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:UploadAllBurstAssetsKey];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:UploadVideosForLivePhotosKey];
    [self clearVideoSettings];
}

+ (void)clearVideoSettings {
    [NSUserDefaults.standardUserDefaults removeObjectForKey:ShouldConvertHEVCVideoKey];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:HEVCToH264CompressionQualityKey];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:IsCellularForVideosAllowedKey];
}

#pragma mark - camera settings

+ (BOOL)isCameraUploadEnabled {
    return [NSUserDefaults.standardUserDefaults boolForKey:IsCameraUploadsEnabledKey];
}

+ (void)setCameraUploadEnabled:(BOOL)cameraUploadEnabled {
    [self setMigratedToCameraUploadsV2:YES];
    [NSUserDefaults.standardUserDefaults setBool:cameraUploadEnabled forKey:IsCameraUploadsEnabledKey];
    [self configDefaultSettingsIfNeededForCameraUpload];
}

+ (void)configDefaultSettingsIfNeededForCameraUpload {
    if (![self isCameraUploadEnabled]) {
        return;
    }
    
    if ([NSUserDefaults.standardUserDefaults objectForKey:ShouldConvertHEICPhotoKey] == nil) {
        [self setConvertHEICPhoto:YES];
    }
    
    if ([NSUserDefaults.standardUserDefaults objectForKey:UploadVideosForLivePhotosKey] == nil) {
        [self setUploadVideosForLivePhotos:YES];
    }

    if ([NSUserDefaults.standardUserDefaults objectForKey:UploadAllBurstAssetsKey] == nil) {
        [self setUploadAllBurstPhotos:YES];
    }
}

+ (BOOL)isBackgroundUploadAllowed {
    return [NSUserDefaults.standardUserDefaults boolForKey:IsLocationBasedBackgroundUploadAllowedKey];
}

+ (void)setBackgroundUploadAllowed:(BOOL)backgroundUploadAllowed {
    [NSUserDefaults.standardUserDefaults setBool:backgroundUploadAllowed forKey:IsLocationBasedBackgroundUploadAllowedKey];
    if (backgroundUploadAllowed) {
        [CameraUploadManager.shared startBackgroundUploadIfPossible];
    } else {
        [CameraUploadManager.shared stopBackgroundUpload];
    }
}

+ (NSDate *)boardingScreenLastShowedDate {
    return [NSUserDefaults.standardUserDefaults objectForKey:BoardingScreenLastShowedDateKey];
}

+ (void)setBoardingScreenLastShowedDate:(NSDate *)boardingScreenLastShowedDate {
    [NSUserDefaults.standardUserDefaults setObject:boardingScreenLastShowedDate forKey:BoardingScreenLastShowedDateKey];
}

#pragma mark - photo settings

+ (BOOL)isCellularUploadAllowed {
    return [NSUserDefaults.standardUserDefaults boolForKey:IsCellularAllowedKey];
}

+ (void)setCellularUploadAllowed:(BOOL)cellularUploadAllowed {
    [NSUserDefaults.standardUserDefaults setBool:cellularUploadAllowed forKey:IsCellularAllowedKey];
}

+ (BOOL)shouldConvertHEICPhoto {
    return [NSUserDefaults.standardUserDefaults boolForKey:ShouldConvertHEICPhotoKey];
}

+ (void)setConvertHEICPhoto:(BOOL)convertHEICPhoto {
    if (![self isHEVCFormatSupported]) {
        return;
    }
    
    [NSUserDefaults.standardUserDefaults setBool:convertHEICPhoto forKey:ShouldConvertHEICPhotoKey];
}

#pragma mark - video settings

+ (BOOL)isVideoUploadEnabled {
    return [NSUserDefaults.standardUserDefaults boolForKey:IsVideoUploadsEnabledKey];
}

+ (void)setVideoUploadEnabled:(BOOL)videoUploadEnabled {
    [NSUserDefaults.standardUserDefaults setBool:videoUploadEnabled forKey:IsVideoUploadsEnabledKey];
    [self configDefaultSettingsIfNeededForVideoUpload];
}

+ (void)configDefaultSettingsIfNeededForVideoUpload {
    if (![self isVideoUploadEnabled]) {
        return;
    }
    
    if ([NSUserDefaults.standardUserDefaults objectForKey:ShouldConvertHEVCVideoKey] == nil) {
        [self setConvertHEVCVideo:YES];
    }
}

+ (BOOL)isCellularUploadForVideosAllowed {
    return [NSUserDefaults.standardUserDefaults boolForKey:IsCellularForVideosAllowedKey];
}

+ (void)setCellularUploadForVideosAllowed:(BOOL)cellularUploadForVideosAllowed {
    [NSUserDefaults.standardUserDefaults setBool:cellularUploadForVideosAllowed forKey:IsCellularForVideosAllowedKey];
}

+ (BOOL)shouldConvertHEVCVideo {
    return [NSUserDefaults.standardUserDefaults boolForKey:ShouldConvertHEVCVideoKey];
}

+ (void)setConvertHEVCVideo:(BOOL)convertHEVCVideo {
    if (![self isHEVCFormatSupported]) {
        return;
    }
    
    [NSUserDefaults.standardUserDefaults setBool:convertHEVCVideo forKey:ShouldConvertHEVCVideoKey];
    
    if (convertHEVCVideo && [NSUserDefaults.standardUserDefaults objectForKey:HEVCToH264CompressionQualityKey] == nil) {
        [self setHEVCToH264CompressionQuality:CameraUploadVideoQualityMedium];
    }
}

+ (CameraUploadVideoQuality)HEVCToH264CompressionQuality {
    return [NSUserDefaults.standardUserDefaults integerForKey:HEVCToH264CompressionQualityKey];
}

+ (void)setHEVCToH264CompressionQuality:(CameraUploadVideoQuality)HEVCToH264CompressionQuality {
    if (![self isHEVCFormatSupported]) {
        return;
    }
    
    [NSUserDefaults.standardUserDefaults setInteger:HEVCToH264CompressionQuality forKey:HEVCToH264CompressionQualityKey];
}

#pragma mark - advanced settings

+ (BOOL)shouldUploadVideosForLivePhotos {
    return [NSUserDefaults.standardUserDefaults boolForKey:UploadVideosForLivePhotosKey];
}

+ (void)setUploadVideosForLivePhotos:(BOOL)uploadVideosForLivePhotos {
    [NSUserDefaults.standardUserDefaults setBool:uploadVideosForLivePhotos forKey:UploadVideosForLivePhotosKey];
}

+ (BOOL)shouldUploadAllBurstPhotos {
    return [NSUserDefaults.standardUserDefaults boolForKey:UploadAllBurstAssetsKey];
}

+ (void)setUploadAllBurstPhotos:(BOOL)uploadAllBurstPhotos {
    [NSUserDefaults.standardUserDefaults setBool:uploadAllBurstPhotos forKey:UploadAllBurstAssetsKey];
}

+ (BOOL)shouldUploadHiddenAlbum {
    return [NSUserDefaults.standardUserDefaults boolForKey:UploadHiddenAlbumKey];
}

+ (void)setUploadHiddenAlbum:(BOOL)uploadHiddenAlbum {
    [NSUserDefaults.standardUserDefaults setBool:uploadHiddenAlbum forKey:UploadHiddenAlbumKey];
}


#pragma mark - readonly properties

+ (BOOL)isLivePhotoSupported {
    if (@available(iOS 9.1, *)) {
        return YES;
    } else {
        return NO;
    }
}

+ (BOOL)shouldScanLivePhotosForVideos {
    return [self isLivePhotoSupported] && [self shouldUploadVideosForLivePhotos];
}

+ (BOOL)shouldShowCameraUploadBoardingScreen {
    BOOL show = NO;
    if (!CameraUploadManager.isCameraUploadEnabled) {
        NSDate *lastShowedDate = CameraUploadManager.boardingScreenLastShowedDate;
        if (lastShowedDate == nil) {
            show = YES;
        } else {
            show = [NSDate.date timeIntervalSinceDate:lastShowedDate] > BoardingScreenShowUpMinimumInterval;
        }
    }
    
    return show;
}

+ (BOOL)isHEVCFormatSupported {
    if (@available(iOS 11.0, *)) {
        return YES;
    } else {
        return NO;
    }
}

+ (BOOL)canBackgroundUploadBeStarted {
    return CameraUploadManager.isBackgroundUploadAllowed && CLLocationManager.authorizationStatus == kCLAuthorizationStatusAuthorizedAlways && CLLocationManager.significantLocationChangeMonitoringAvailable;
}

+ (BOOL)canCameraUploadBeStarted {
    return [self isCameraUploadEnabled] && [self hasMigratedToCameraUploadsV2];
}

+ (NSArray<NSNumber *> *)enabledMediaTypes {
    NSMutableArray<NSNumber *> *mediaTypes = [NSMutableArray array];
    if (CameraUploadManager.isCameraUploadEnabled) {
        [mediaTypes addObject:@(PHAssetMediaTypeImage)];
        
        if (CameraUploadManager.isVideoUploadEnabled) {
            [mediaTypes addObject:@(PHAssetMediaTypeVideo)];
        }
    }
    
    return [mediaTypes copy];
}

+ (BOOL)isCameraUploadPausedBecauseOfNoWiFiConnection {
    return ![self isCellularUploadAllowed] && !MEGAReachabilityManager.isReachableViaWiFi;
}

#pragma mark - camera upload v2 migration

+ (BOOL)hasMigratedToCameraUploadsV2 {
    if (![self isHEVCFormatSupported]) {
        return YES;
    }
    
    return [NSUserDefaults.standardUserDefaults boolForKey:HasMigratedToCameraUploadsV2Key];
}

+ (void)setMigratedToCameraUploadsV2:(BOOL)migratedToCameraUploadsV2 {
    if (![self isHEVCFormatSupported]) {
        return;
    }
    
    [NSUserDefaults.standardUserDefaults setBool:migratedToCameraUploadsV2 forKey:HasMigratedToCameraUploadsV2Key];
}

+ (BOOL)shouldShowCameraUploadV2MigrationScreen {
    return [self isCameraUploadEnabled] && ![self hasMigratedToCameraUploadsV2];
}

+ (void)migrateCurrentSettingsToCameraUploadV2 {
    [self configDefaultSettingsIfNeededForCameraUpload];
    [self configDefaultSettingsIfNeededForVideoUpload];
}

@end