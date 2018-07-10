
#import <Foundation/Foundation.h>

#import "ConfirmAccountViewController.h"
#import "URLType.h"

@interface MEGALinkManager : NSObject

#pragma mark - Utils to manage MEGA links

+ (NSURL *)linkURL;
+ (void)setLinkURL:(NSURL *)link;

+ (URLType)urlType;
+ (void)setUrlType:(URLType)urlType;

+ (void)resetLinkAndURLType;

+ (NSString *)emailOfNewSignUpLink;
+ (void)setEmailOfNewSignUpLink:(NSString *)emailOfNewSignUpLink;

#pragma mark - Utils to manage links when you are not logged

+ (void)processSelectedOptionOnLink;

#pragma mark - Spotlight

+ (NSString *)nodeToPresentBase64Handle;
+ (void)setNodeToPresentBase64Handle:(NSString *)base64Handle;

+ (void)presentNode;

#pragma mark - Manage MEGA links

+ (void)processLinkURL:(NSURL *)url;

+ (void)showLinkNotValid;

+ (void)presentConfirmViewControllerType:(ConfirmType)confirmType link:(NSString *)link email:(NSString *)email;

+ (void)showFileLinkView;

@end
