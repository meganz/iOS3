
#import "CustomModalAlertViewController.h"

#import "AchievementsViewController.h"
#import "CopyableLabel.h"

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#elif MNZ_PICKER_EXTENSION
#import "MEGAPicker-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

#import "UIApplication+MNZCategory.h"
#import "UIImage+GKContact.h"

@interface CustomModalAlertViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;

@property (weak, nonatomic) IBOutlet UIButton *firstButton;
@property (weak, nonatomic) IBOutlet UIButton *secondButton;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;

@property (weak, nonatomic) IBOutlet UIView *mainView;

@property (weak, nonatomic) IBOutlet UIView *linkView;
@property (weak, nonatomic) IBOutlet CopyableLabel *linkLabel;

@property (nonatomic) MEGAPresentationManager *presentationManager;

@end

@implementation CustomModalAlertViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    self.presentationManager = MEGAPresentationManager.new;
    self.transitioningDelegate = self.presentationManager;
    self.modalPresentationStyle = UIModalPresentationCustom;
    return self;
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configUIAppearance];
    
    if (self.image) {
        self.imageView.image = self.image;
        if (self.shouldRoundImage) {
            self.imageView.layer.cornerRadius = (self.imageView.image.size.height / 4);
            self.imageView.clipsToBounds = YES;
        }
    }
    
    self.titleLabel.text = self.viewTitle;
    
    if (self.boldInDetail) {
        NSRange boldRange = [self.detail rangeOfString:self.boldInDetail];
        
        NSMutableAttributedString *detailAttributedString = [[NSMutableAttributedString alloc] initWithString:self.detail];
        
        [detailAttributedString beginEditing];
        [detailAttributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14.0f weight:UIFontWeightMedium] range:boldRange];
        
        [detailAttributedString endEditing];
        self.detailLabel.attributedText = detailAttributedString;
    } else {
        self.detailLabel.text = self.detail;
    }
    
    if (self.firstButtonTitle) {
        [self.firstButton setTitle:self.firstButtonTitle forState:UIControlStateNormal];
    } else {
        self.firstButton.hidden = YES;
    }
    
    if (self.dismissButtonTitle) {
        [self.dismissButton setTitle:self.dismissButtonTitle forState:UIControlStateNormal];
    } else {
        self.dismissButton.hidden = YES;
    }
    
    if (self.secondButtonTitle) {
        [self.secondButton setTitle:self.secondButtonTitle forState:UIControlStateNormal];
    } else {
        self.secondButton.hidden = YES;
    }
    
    if (self.link) {
        self.linkView.layer.borderColor = [[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1] CGColor];
        self.linkLabel.text = self.link;
    } else {
        self.linkView.hidden = YES;
    }
    
    [self updateAppearance];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self updateAppearance];
        }
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.mainView.backgroundColor = [UIColor mnz_backgroundElevated:self.traitCollection];
    
    self.linkView.backgroundColor = [UIColor mnz_tertiaryBackground:self.traitCollection];
    
    [self.firstButton mnz_setupPrimary:self.traitCollection];
    [self.secondButton mnz_setupDestructive:self.traitCollection];
    [self.dismissButton mnz_setupCancel:self.traitCollection];
}

- (void)configUIAppearance {
    self.mainView.layer.shadowColor = UIColor.blackColor.CGColor;
    self.mainView.layer.shadowOffset = CGSizeMake(0, 1);
    self.mainView.layer.shadowOpacity = 0.15;
    
    self.firstButton.titleLabel.numberOfLines = 2;
    self.firstButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.firstButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
}

#pragma mark - IBActions

- (IBAction)firstButtonTouchUpInside:(UIButton *)sender {
    if (self.firstCompletion) self.firstCompletion();
}

- (IBAction)dismissTouchUpInside:(UIButton *)sender {
    if (self.dismissCompletion) {
        self.dismissCompletion();
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)secondButtonTouchUpInside:(UIButton *)sender {
    if (self.secondCompletion) {
        self.secondCompletion();
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            AchievementsViewController *achievementsVC = [[UIStoryboard storyboardWithName:@"Achievements" bundle:nil] instantiateViewControllerWithIdentifier:@"AchievementsViewControllerID"];
            achievementsVC.enableCloseBarButton = YES;
            UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:achievementsVC];
            [UIApplication.mnz_presentingViewController presentViewController:navigation animated:YES completion:nil];
        }];
    }
}

@end