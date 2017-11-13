
#import "CallViewController.h"
#import "MEGARemoteImageView.h"
#import "MEGALocalImageView.h"

#import "UIImageView+MNZCategory.h"

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "MEGAChatAnswerCallRequestDelegate.h"
#import "MEGAChatEnableDisableAudioRequestDelegate.h"
#import "MEGAChatEnableDisableVideoRequestDelegate.h"
#import "MEGAChatStartCallRequestDelegate.h"

@interface CallViewController () <MEGAChatRequestDelegate, MEGAChatCallDelegate, MEGAChatVideoDelegate>

@property (nonatomic, strong) MEGAChatCall *chatCall;
@property (weak, nonatomic) IBOutlet MEGARemoteImageView *remoteVideoImageView;
@property (weak, nonatomic) IBOutlet MEGALocalImageView *localVideoImageView;
@property (weak, nonatomic) IBOutlet UIImageView *remoteAvatarImageView;

@property (weak, nonatomic) IBOutlet UIButton *enableDisableVideoButton;
@property (weak, nonatomic) IBOutlet UIButton *muteUnmuteMicrophone;

@property (weak, nonatomic) IBOutlet UIView *outgoingCallView;
@property (weak, nonatomic) IBOutlet UIView *incomingCallView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusCallLabel;

@property BOOL loudSpeakerEnabled;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSDate *baseDate;

@end

@implementation CallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _chatCall = [[MEGASdkManager sharedMEGAChatSdk] chatCallForChatId:self.chatRoom.chatId];
    
    self.enableDisableVideoButton.selected = self.videoCall;
    self.loudSpeakerEnabled = self.videoCall;
    
    [self.remoteAvatarImageView mnz_setImageForUserHandle:[self.chatRoom peerHandleAtIndex:0]];
    
    self.statusCallLabel.text = AMLocalizedString(@"calling...", @"Label shown when you receive an incoming call, before start the call.");
    
    if (self.callType == CallTypeIncoming) {
        self.outgoingCallView.hidden = YES;
    } else {
        MEGAChatStartCallRequestDelegate *startCallRequestDelegate = [[MEGAChatStartCallRequestDelegate alloc] initWithCompletion:^(MEGAChatError *error) {
            if (error.type) {
                [self dismissViewControllerAnimated:YES completion:nil];
            } else {
                self.incomingCallView.hidden = YES;
                
                [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
                
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSessionRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sensorStateMonitor:) name:@"UIDeviceProximityStateDidChangeNotification" object:nil];
            }
        }];
        
        [[MEGASdkManager sharedMEGAChatSdk] startChatCall:self.chatRoom.chatId enableVideo:self.videoCall delegate:startCallRequestDelegate];
    }
    
    self.nameLabel.text = [self.chatRoom peerFullnameAtIndex:0];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[MEGASdkManager sharedMEGAChatSdk] addChatCallDelegate:self];
    if (self.videoCall) {
        [[MEGASdkManager sharedMEGAChatSdk] addChatRemoteVideoDelegate:self.remoteVideoImageView];
        [[MEGASdkManager sharedMEGAChatSdk] addChatLocalVideoDelegate:self.localVideoImageView];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[MEGASdkManager sharedMEGAChatSdk] removeChatCallDelegate:self];
    [[MEGASdkManager sharedMEGAChatSdk] removeChatRemoteVideoDelegate:self.remoteVideoImageView];
    [[MEGASdkManager sharedMEGAChatSdk] removeChatLocalVideoDelegate:self.localVideoImageView];
    
    [[NSNotificationCenter defaultCenter] removeObserver:AVAudioSessionRouteChangeNotification];
    [[NSNotificationCenter defaultCenter] removeObserver:@"UIDeviceProximityStateDidChangeNotification"];
    
    [self.timer invalidate];
}

#pragma mark - Private

- (void)sensorStateMonitor:(NSNotificationCenter *)notification {
    if (!self.videoCall) {
        return;
    }
    
    if ([[UIDevice currentDevice] proximityState] == YES) {
        [self disableLoudspeaker];
    } else {
        [self enableLoudspeaker];
    }
}

- (void)didSessionRouteChange:(NSNotification *)notification
{
    NSDictionary *interuptionDict = notification.userInfo;
    const NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    if (routeChangeReason == AVAudioSessionRouteChangeReasonRouteConfigurationChange) {
        if (self.loudSpeakerEnabled) {
            [self enableLoudspeaker];
        }
        else {
            [self disableLoudspeaker];
        }
    }
}

- (void)enableLoudspeaker {
    self.loudSpeakerEnabled = TRUE;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    AVAudioSessionCategoryOptions options = audioSession.categoryOptions;
    if (options & AVAudioSessionCategoryOptionDefaultToSpeaker) return;
    options |= AVAudioSessionCategoryOptionDefaultToSpeaker;
    [audioSession setActive:YES error:nil];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:options error:nil];
}

- (void)disableLoudspeaker {
    self.loudSpeakerEnabled = FALSE;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    AVAudioSessionCategoryOptions options = audioSession.categoryOptions;
    if (options & AVAudioSessionCategoryOptionDefaultToSpeaker) {
        options &= ~AVAudioSessionCategoryOptionDefaultToSpeaker;
        [audioSession setActive:YES error:nil];
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:options error:nil];
    }
}

- (void)updateLabel {
    NSTimeInterval interval = [self.baseDate timeIntervalSinceNow];
    NSUInteger seconds = ABS((int)interval);
    NSUInteger minutes = seconds/60;
    NSUInteger hours = minutes/60;
    self.statusCallLabel.text = [NSString stringWithFormat:@"%02lu:%02lu:%02lu", (unsigned long)hours, (unsigned long)minutes%60, (unsigned long)seconds%60];
}


#pragma mark - IBActions

- (IBAction)acceptCallWithVideo:(UIButton *)sender {
    MEGAChatAnswerCallRequestDelegate *answerCallRequestDelegate = [[MEGAChatAnswerCallRequestDelegate alloc] initWithCompletion:^(MEGAChatError *error) {
        if (error.type == MEGAChatErrorTypeOk) {
            [[MEGASdkManager sharedMEGAChatSdk] addChatLocalVideoDelegate:self.localVideoImageView];            
            self.enableDisableVideoButton.selected = YES;
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
    [[MEGASdkManager sharedMEGAChatSdk] answerChatCall:self.chatRoom.chatId enableVideo:YES delegate:answerCallRequestDelegate];
}

- (IBAction)acceptCall:(UIButton *)sender {
    MEGAChatAnswerCallRequestDelegate *answerCallRequestDelegate = [[MEGAChatAnswerCallRequestDelegate alloc] initWithCompletion:^(MEGAChatError *error) {
        if (error.type != MEGAChatErrorTypeOk) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
    [[MEGASdkManager sharedMEGAChatSdk] answerChatCall:self.chatRoom.chatId enableVideo:NO delegate:answerCallRequestDelegate];
}

- (IBAction)hangCall:(UIButton *)sender {
    [[MEGASdkManager sharedMEGAChatSdk] hangChatCall:self.chatRoom.chatId];
}

- (IBAction)muteOrUnmuteCall:(UIButton *)sender {
    MEGAChatEnableDisableAudioRequestDelegate *enableDisableAudioRequestDelegate = [[MEGAChatEnableDisableAudioRequestDelegate alloc] initWithCompletion:^(MEGAChatError *error) {
        if (error.type == MEGAChatErrorTypeOk) {
            sender.selected = !sender.selected;
        }
    }];
    
    if (sender.selected) {
        [[MEGASdkManager sharedMEGAChatSdk] enableAudioForChat:self.chatRoom.chatId delegate:enableDisableAudioRequestDelegate];
    } else {
        [[MEGASdkManager sharedMEGAChatSdk] disableAudioForChat:self.chatRoom.chatId delegate:enableDisableAudioRequestDelegate];
    }
}

- (IBAction)enableDisableVideo:(UIButton *)sender {
    MEGAChatEnableDisableVideoRequestDelegate *enableDisableVideoRequestDelegate = [[MEGAChatEnableDisableVideoRequestDelegate alloc] initWithCompletion:^(MEGAChatError *error) {
        if (error.type == MEGAChatErrorTypeOk) {
            if (sender.selected) {
                self.localVideoImageView.hidden = YES;
                [[MEGASdkManager sharedMEGAChatSdk] removeChatLocalVideoDelegate:self.localVideoImageView];
            } else {
                self.localVideoImageView.hidden = NO;
                [[MEGASdkManager sharedMEGAChatSdk] addChatLocalVideoDelegate:self.localVideoImageView];
            }
            sender.selected = !sender.selected;
        }
    }];
    if (sender.selected) {
        [[MEGASdkManager sharedMEGAChatSdk] disableVideoForChat:self.chatRoom.chatId delegate:enableDisableVideoRequestDelegate];
    } else {
        [[MEGASdkManager sharedMEGAChatSdk] enableVideoForChat:self.chatRoom.chatId delegate:enableDisableVideoRequestDelegate];
    }
}

#pragma mark - MEGAChatCallDelegate

- (void)onChatCallUpdate:(MEGAChatSdk *)api call:(MEGAChatCall *)call {
    MEGALogDebug(@"onChatCallUpdate %@", call);
    
    switch (call.status) {
        case MEGAChatCallStatusInitial:
            break;
            
        case MEGAChatCallStatusHasLocalStream:
            break;
            
        case MEGAChatCallStatusRequestSent:
            break;
            
        case MEGAChatCallStatusRingIn:
            break;
            
        case MEGAChatCallStatusJoining:
            break;
            
        case MEGAChatCallStatusInProgress: {
            if (!self.timer.isValid) {
                _timer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(updateLabel) userInfo:nil repeats:YES];
                [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
                _baseDate = [NSDate date];
            }
            self.outgoingCallView.hidden = NO;
            self.incomingCallView.hidden = YES;
            
            if ([call hasChangedForType:MEGAChatCallChangeTypeRemoteAVFlags]) {
                if (call.hasRemoteVideo) {
                    self.remoteVideoImageView.hidden = NO;
                    [[MEGASdkManager sharedMEGAChatSdk] addChatRemoteVideoDelegate:self.remoteVideoImageView];
                    self.remoteAvatarImageView.hidden = YES;
                } else {
                    [[MEGASdkManager sharedMEGAChatSdk] removeChatRemoteVideoDelegate:self.remoteVideoImageView];
                    self.remoteVideoImageView.hidden = YES;
                    self.remoteAvatarImageView.hidden = NO;
                    [self.remoteAvatarImageView mnz_setImageForUserHandle:[self.chatRoom peerHandleAtIndex:0]];
                }
            }
            break;
        }
        case MEGAChatCallStatusTerminating:
        case MEGAChatCallStatusDestroyed:
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
            
        default:
            break;
    }
}

@end
