
#import "MEGALogger.h"

#import "NSFileManager+MNZCategory.h"

@implementation MEGALogger

static MEGALogger *_megaLogger = nil;

+ (MEGALogger *)sharedLogger {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _megaLogger = [[MEGALogger alloc] init];
    });
    
    return _megaLogger;
}

- (void)startLogging {
    NSString *logFilePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"MEGAiOS.log"];
    [self startLoggingToFile:logFilePath];
}

- (void)startLoggingToFile:(NSString *)logFilePath {
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding],"a+", stdout);
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding],"a+", stderr);
    
    [MEGASdk setLogLevel:MEGALogLevelMax];
    [MEGAChatSdk setLogLevel:MEGAChatLogLevelMax];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"logging"];
    if (@available(iOS 12.0, *)) {} else {
        [NSUserDefaults.standardUserDefaults synchronize];
    }
    
    [[NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier] setBool:YES forKey:@"logging"];
    
    NSString *version = [NSString stringWithFormat:@"%@ (%@)", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    NSArray *languageArray = [NSLocale preferredLanguages];
    NSString *language = [NSLocale.currentLocale displayNameForKey:NSLocaleIdentifier value:languageArray.firstObject];
    
    MEGALogInfo(@"Device information:\nVersion: %@\nDevice: %@\niOS Version: %@\nLanguage: %@\nTimezone: %@", version, [[UIDevice currentDevice] deviceName], systemVersion, language, [NSTimeZone localTimeZone].name);
}

- (void)stopLogging {
    [self stopLoggingToFile:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"MEGAiOS.log"]];
    [self stopLoggingToFile:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"MEGAiOS.docExt.log"]];
    [self stopLoggingToFile:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"MEGAiOS.fileExt.log"]];
    [self stopLoggingToFile:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"MEGAiOS.shareExt.log"]];
    // Also remove logs in the shared sandbox:
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *logsPath = [[[fileManager containerURLForSecurityApplicationGroupIdentifier:MEGAGroupIdentifier] URLByAppendingPathComponent:MEGAExtensionLogsFolder] path];
    [self stopLoggingToFile:[logsPath stringByAppendingPathComponent:@"MEGAiOS.docExt.log"]];
    [self stopLoggingToFile:[logsPath stringByAppendingPathComponent:@"MEGAiOS.fileExt.log"]];
    [self stopLoggingToFile:[logsPath stringByAppendingPathComponent:@"MEGAiOS.shareExt.log"]];
    
#ifndef DEBUG
    [MEGASdk setLogLevel:MEGALogLevelFatal];
    [MEGAChatSdk setLogLevel:MEGAChatLogLevelFatal];
#endif
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"logging"];
    if (@available(iOS 12.0, *)) {} else {
        [NSUserDefaults.standardUserDefaults synchronize];
    }
    
    NSUserDefaults *sharedUserDefaults = [NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier];
    [sharedUserDefaults setBool:NO forKey:@"logging"];
}

- (void)stopLoggingToFile:(NSString *)logFilePath {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSFileManager.defaultManager mnz_removeItemAtPath:logFilePath];
    });
}

@end
