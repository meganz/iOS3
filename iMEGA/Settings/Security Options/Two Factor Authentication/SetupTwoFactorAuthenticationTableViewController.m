
#import "SetupTwoFactorAuthenticationTableViewController.h"

#import "SVProgressHUD.h"

#import "UIApplication+MNZCategory.h"

#import "CustomModalAlertViewController.h"
#import "EnablingTwoFactorAuthenticationViewController.h"
#import "MEGASdkManager.h"
#import "MEGAMultiFactorAuthCheckRequestDelegate.h"
#import "TwoFactorAuthentication.h"
#import "TwoFactorAuthenticationViewController.h"

@interface SetupTwoFactorAuthenticationTableViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *twoFactorAuthenticationSwitch;

@property (weak, nonatomic) IBOutlet UILabel *twoFactorAuthenticationLabel;
@property (getter=isTwoFactorAuthenticationEnabled) BOOL twoFactorAuthenticationEnabled;

@end

@implementation SetupTwoFactorAuthenticationTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"twoFactorAuthentication", @"");
    
    self.twoFactorAuthenticationLabel.text = AMLocalizedString(@"twoFactorAuthentication", @"");
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    MEGAMultiFactorAuthCheckRequestDelegate *delegate = [[MEGAMultiFactorAuthCheckRequestDelegate alloc] initWithCompletion:^(MEGARequest *request, MEGAError *error) {
        self.twoFactorAuthenticationEnabled = request.flag;
        
        self.twoFactorAuthenticationSwitch.on = self.twoFactorAuthenticationEnabled;
    }];
    [[MEGASdkManager sharedMEGASdk] multiFactorAuthCheckWithEmail:[[MEGASdkManager sharedMEGASdk] myEmail] delegate:delegate];
}

#pragma mark - IBActions

- (IBAction)twoFactorAuthenticationTouchUpInside:(UIButton *)sender {
    if (self.twoFactorAuthenticationSwitch.isOn) {
        TwoFactorAuthenticationViewController *twoFactorAuthenticationVC = [[UIStoryboard storyboardWithName:@"TwoFactorAuthentication" bundle:nil] instantiateViewControllerWithIdentifier:@"TwoFactorAuthenticationViewControllerID"];
        twoFactorAuthenticationVC.twoFAMode = TwoFactorAuthenticationDisable;
        
        [self.navigationController pushViewController:twoFactorAuthenticationVC animated:YES];
    } else {
        CustomModalAlertViewController *customModalAlertVC = [[CustomModalAlertViewController alloc] init];
        [customModalAlertVC configureForTwoFactorAuthenticationRequestedByUser:YES];
        
        [UIApplication.mnz_presentingViewController presentViewController:customModalAlertVC animated:YES completion:nil];
    }
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return AMLocalizedString(@"whatIsTwoFactorAuthentication", @"Text shown as explanation of what is Two-Factor Authentication");
            break;
            
        default:
            return @"";
            break;
    }
}

@end
