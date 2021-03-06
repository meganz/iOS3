
#import "FileManagementTableViewController.h"

#import "SVProgressHUD.h"

#import "Helper.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "MEGASdk+MNZCategory.h"
#import "MEGAStore.h"
#import "MEGA-Swift.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"

@interface FileManagementTableViewController () <MEGAGlobalDelegate, MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UILabel *clearOfflineFilesLabel;
@property (weak, nonatomic) IBOutlet UILabel *clearCacheLabel;

@property (weak, nonatomic) IBOutlet UILabel *rubbishBinLabel;

@property (weak, nonatomic) IBOutlet UILabel *fileVersioningLabel;
@property (weak, nonatomic) IBOutlet UISwitch *fileVersioningSwitch;

@property (weak, nonatomic) IBOutlet UILabel *fileVersionsLabel;
@property (weak, nonatomic) IBOutlet UILabel *fileVersionsDetailLabel;

@property (weak, nonatomic) IBOutlet UITableViewCell *deleteOldVersionCell;
@property (weak, nonatomic) IBOutlet UILabel *deleteOldVersionsLabel;

@property (nonatomic, copy) NSString *offlineSizeString;
@property (nonatomic, copy) NSString *cacheSizeString;

@property (nonatomic, getter=isFileVersioningEnabled) BOOL fileVersioningEnabled;

@end

@implementation FileManagementTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"File Management", @"A section header which contains the file management settings. These settings allow users to remove duplicate files etc.");
    
    _offlineSizeString = @"...";
    _cacheSizeString = @"...";
    
    [self updateAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.clearOfflineFilesLabel.text = NSLocalizedString(@"clearOfflineFiles", @"Section title where you can 'Clear Offline files' of your MEGA app");
    self.clearCacheLabel.text = NSLocalizedString(@"clearCache", @"Section title where you can 'Clear Cache' of your MEGA app");
    
    self.rubbishBinLabel.text = NSLocalizedString(@"rubbishBinLabel", @"Title of one of the Settings sections where you can see your MEGA 'Rubbish Bin'");
    
    self.fileVersioningLabel.text = NSLocalizedString(@"File versioning", @"Title of the option to enable or disable file versioning on Settings section");
    [[MEGASdkManager sharedMEGASdk] getFileVersionsOptionWithDelegate:self];
    
    self.fileVersionsLabel.text = NSLocalizedString(@"File Versions", @"Settings preference title to show file versions info of the account");
    long long totalNumberOfVersions = [[[MEGASdkManager sharedMEGASdk] mnz_accountDetails] numberOfVersionFilesForHandle:[[[MEGASdkManager sharedMEGASdk] rootNode] handle]];
    self.fileVersionsDetailLabel.text = [NSString stringWithFormat:@"%lld", totalNumberOfVersions];
    [MEGASdkManager.sharedMEGASdk getAccountDetailsWithDelegate:self];
    
    self.deleteOldVersionsLabel.text = NSLocalizedString(@"Delete Previous Versions", @"Text of a button which deletes all historical versions of files in the users entire account.");
    [self updateDeleteVersionsUIBy:[self totalNumberOfFileVersionsOfCurrentAccount]];
    
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    
    [self reloadUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[MEGASdkManager sharedMEGASdk] removeMEGAGlobalDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[TransfersWidgetViewController sharedTransferViewController].progressView showWidgetIfNeeded];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [TransfersWidgetViewController.sharedTransferViewController.progressView hideWidget];
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
    self.tableView.separatorColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    self.tableView.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];
    
    self.fileVersionsDetailLabel.textColor = UIColor.mnz_secondaryLabel;
    self.deleteOldVersionsLabel.textColor = [UIColor mnz_redForTraitCollection:self.traitCollection];
    
    [self.tableView reloadData];
}

- (void)reloadUI {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        unsigned long long offlineSize = [NSFileManager.defaultManager mnz_sizeOfFolderAtPath:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject];
        self.offlineSizeString = [Helper memoryStyleStringFromByteCount:offlineSize];
        self.offlineSizeString = [NSString mnz_formatStringFromByteCountFormatter:self.offlineSizeString];
        
        unsigned long long cachesFolderSize = [NSFileManager.defaultManager mnz_sizeOfFolderAtPath:[Helper pathForSharedSandboxCacheDirectory:@""]];

        unsigned long long temporaryDirectory = [NSFileManager.defaultManager mnz_sizeOfFolderAtPath:NSTemporaryDirectory()];
        unsigned long long groupDirectory = [NSFileManager.defaultManager mnz_groupSharedDirectorySize];
        unsigned long long cacheSize = cachesFolderSize + temporaryDirectory + groupDirectory;
        
        self.cacheSizeString = [Helper memoryStyleStringFromByteCount:cacheSize];
        self.cacheSizeString = [NSString mnz_formatStringFromByteCountFormatter:self.cacheSizeString];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self.tableView reloadData];
        });
    });
}

- (long long)totalNumberOfFileVersionsOfCurrentAccount {
    return [MEGASdkManager.sharedMEGASdk.mnz_accountDetails numberOfVersionFilesForHandle:MEGASdkManager.sharedMEGASdk.rootNode.handle];
}

- (void)updateDeleteVersionsUIBy:(long long)totalNumberOfVersions {
    self.fileVersionsDetailLabel.text = [NSString stringWithFormat:@"%lld", totalNumberOfVersions];
    BOOL shouldEnableDeleteVersionsCell = totalNumberOfVersions > 0;
    self.deleteOldVersionCell.userInteractionEnabled = shouldEnableDeleteVersionsCell;
    self.deleteOldVersionsLabel.enabled = shouldEnableDeleteVersionsCell;
}

- (void)removeGroupSharedDirectoryContents {
    //Remove only the contents of some folders located inside of the group shared directory. The 'GroupSupport' directory contents are not deleted because is where the SDK databases are located.
    NSString *groupSharedDirectoryPath = [NSFileManager.defaultManager containerURLForSecurityApplicationGroupIdentifier:MEGAGroupIdentifier].path;
    [NSFileManager.defaultManager mnz_removeFolderContentsAtPath:[groupSharedDirectoryPath stringByAppendingPathComponent:MEGAExtensionLogsFolder]];
    [NSFileManager.defaultManager mnz_removeFolderContentsAtPath:[groupSharedDirectoryPath stringByAppendingPathComponent:MEGAFileExtensionStorageFolder]];
    [NSFileManager.defaultManager mnz_removeFolderContentsAtPath:[groupSharedDirectoryPath stringByAppendingPathComponent:MEGAShareExtensionStorageFolder]];
}

#pragma mark - IBActions

- (IBAction)fileVersioningSwitchTouchUpInside:(UIButton *)sender {
    if (self.fileVersioningSwitch.isOn) {
        UIAlertController *enableOrDisableFileVersioningAlertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"When file versioning is disabled, the current version will be replaced with the new version once a file is updated (and your changes to the file will no longer be recorded). Are you sure you want to disable file versioning?", @"A confirmation message when the user chooses to disable file versioning.") message:nil preferredStyle:UIAlertControllerStyleAlert];
        [enableOrDisableFileVersioningAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"no", nil) style:UIAlertActionStyleCancel handler:nil]];
        [enableOrDisableFileVersioningAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"yes", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                [[MEGASdkManager sharedMEGASdk] setFileVersionsOption:YES delegate:self];
            }
        }]];
        
        [self presentViewController:enableOrDisableFileVersioningAlertController animated:YES completion:nil];
    } else {
        if ([MEGAReachabilityManager isReachableHUDIfNot]) {
            [[MEGASdkManager sharedMEGASdk] setFileVersionsOption:NO delegate:self];
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *titleHeader;
    switch (section) {
        case 0: //On your device
            titleHeader = NSLocalizedString(@"onYourDevice", @"Title header that refers to where do you do the actions 'Clear Offlines files' and 'Clear cache' inside 'Settings' -> 'Advanced' section");
            break;
            
        case 2: //On MEGA
            titleHeader = NSLocalizedString(@"onMEGA", @"Title header that refers to where do you do the action 'Empty Rubbish Bin' inside 'Settings' -> 'Advanced' section");
            break;
            
        case 3: //File Versioning
            titleHeader = NSLocalizedString(@"File versioning", @"Title of the option to enable or disable file versioning on Settings section");
            break;
            
        case 5: //Delete all my older versions of files
            titleHeader = NSLocalizedString(@"Delete all older versions of my files", @"The title of the section about deleting file versions in the settings.");
            break;
    }
    
    return titleHeader;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *titleFooter;
    switch (section) {
        case 0: { //On your device - Offline
            NSString *currentlyUsingString = NSLocalizedString(@"currentlyUsing", @"Footer text that explain what amount of space you will free up if 'Clear Offline data', 'Clear cache' or 'Clear Rubbish Bin' is tapped");
            currentlyUsingString = [currentlyUsingString stringByReplacingOccurrencesOfString:@"%s" withString:self.offlineSizeString];
            titleFooter = currentlyUsingString;
            break;
        }
            
        case 1: { //On your device - Clear cache
            NSString *currentlyUsingString = NSLocalizedString(@"currentlyUsing", @"Footer text that explain what amount of space you will free up if 'Clear Offline data', 'Clear cache' or 'Clear Rubbish Bin' is tapped");
            currentlyUsingString = [currentlyUsingString stringByReplacingOccurrencesOfString:@"%s" withString:self.cacheSizeString];
            titleFooter = currentlyUsingString;
            break;
        }
            
        case 2: { //On MEGA - Rubbish Bin
            NSNumber *rubbishBinSizeNumber = [[MEGASdkManager sharedMEGASdk] sizeForNode:[[MEGASdkManager sharedMEGASdk] rubbishNode]];
            NSString *stringFromByteCount = [Helper memoryStyleStringFromByteCount:rubbishBinSizeNumber.unsignedLongLongValue];
            stringFromByteCount = [NSString mnz_formatStringFromByteCountFormatter:stringFromByteCount];
            NSString *currentlyUsingString = NSLocalizedString(@"currentlyUsing", @"Footer text that explain what amount of space you will free up if 'Clear Offline data', 'Clear cache' or 'Clear Rubbish Bin' is tapped");
            currentlyUsingString = [currentlyUsingString stringByReplacingOccurrencesOfString:@"%s" withString:stringFromByteCount];
            titleFooter = currentlyUsingString;
            break;
        }
            
        case 3: { //File Versioning - File Versioning
            NSString *fileVersioningDescription = NSLocalizedString(@"Enable or disable file versioning for your entire account.[Br]You may still receive file versions from shared folders if your contacts have this enabled.", @"Subtitle of the option to enable or disable file versioning on Settings section");
            titleFooter = [fileVersioningDescription stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
            break;
        }
            
        case 4: { //File Versioning - File Versions
            long long totalNumberOfVersionsSize = [[[MEGASdkManager sharedMEGASdk] mnz_accountDetails] versionStorageUsedForHandle:[[[MEGASdkManager sharedMEGASdk] rootNode] handle]];
            NSString *stringFromByteCount = [Helper memoryStyleStringFromByteCount:totalNumberOfVersionsSize];
            stringFromByteCount = [NSString mnz_formatStringFromByteCountFormatter:stringFromByteCount];
            NSString *totalFileVersionsSize = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Total size taken up by file versions:", @"A title message in the user’s account settings for showing the storage used for file versions."), stringFromByteCount];
            titleFooter = totalFileVersionsSize;
            break;
        }
            
        case 5: { //File Versioning - Delete Old Versions
            titleFooter = NSLocalizedString(@"All current files will remain. Only historic versions of your files will be deleted.", @"A warning note about deleting all file versions in the settings section.");
            break;
        }
    }
    
    return titleFooter;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor mnz_secondaryBackgroundGrouped:self.traitCollection];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: { //On your device - Offline
            NSString *offlinePathString = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
            [SVProgressHUD show];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                [NSFileManager.defaultManager mnz_removeFolderContentsAtPath:offlinePathString];
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [SVProgressHUD dismiss];
                    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                    [[MEGAStore shareInstance] removeAllOfflineNodes];
                    if (@available(iOS 14.0, *)) {
                        [QuickAccessWidgetManager reloadWidgetContentOfKindWithKind:MEGAOfflineQuickAccessWidget];
                    }
                    [self reloadUI];
                });
            });
            break;
        }
            
        case 1: { //On your device - Clear cache
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
            [SVProgressHUD show];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                [NSFileManager.defaultManager mnz_removeFolderContentsAtPath:NSTemporaryDirectory()];
                [NSFileManager.defaultManager mnz_removeFolderContentsAtPath:[Helper pathForSharedSandboxCacheDirectory:@""]];
                [self removeGroupSharedDirectoryContents];
                
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [SVProgressHUD dismiss];
                    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                    [self reloadUI];
                });
            });
            break;
        }
            
        case 2: //On MEGA - Rubbish Bin
        case 3: //File Versioning - File Versioning
        case 4: //File Versioning - File Versions
            break;
            
        case 5: { //File Versioning - Delete all file versions
            NSString *alertMessage = NSLocalizedString(@"You are about to delete the version histories of all files. Any file version shared to you from a contact will need to be deleted by them.[Br][Br]Please note that the current files will not be deleted.", @"Text of the dialog to delete all the file versions of the account");
            alertMessage = [alertMessage stringByReplacingOccurrencesOfString:@"\n\n" withString:@"\n"];
            
            UIAlertController *deleteAllFileVersionsAlertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Delete all older versions of my files", @"The title of the section about deleting file versions in the settings.") message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
            [deleteAllFileVersionsAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"no", nil) style:UIAlertActionStyleCancel handler:nil]];
            [deleteAllFileVersionsAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"yes", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                    [MEGASdkManager.sharedMEGASdk removeVersionsWithDelegate:self];
                }
            }]];
            
            [self presentViewController:deleteAllFileVersionsAlertController animated:YES completion:nil];
            break;
        }
            
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    [self.tableView reloadData];
}

- (void)onUsersUpdate:(MEGASdk *)api userList:(MEGAUserList *)userList {
    NSInteger userListCount = userList.size.integerValue;
    for (NSInteger i = 0 ; i < userListCount; i++) {
        MEGAUser *user = [userList userAtIndex:i];
        
        if (user.handle == api.myUser.handle && [user hasChangedType:MEGAUserChangeTypeDisableVersions] && user.isOwnChange == 0) {
            [api getFileVersionsOptionWithDelegate:self];
        }
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ((request.type == MEGARequestTypeGetAttrUser) && (request.paramType == MEGAUserAttributeDisableVersions)) {
        if (!error.type || error.type == MEGAErrorTypeApiENoent) {
            self.fileVersioningSwitch.on = self.fileVersioningEnabled = !request.flag;
            
            [self.tableView reloadData];
        }
    }
    
    if (request.type == MEGARequestTypeRemoveVersions) {
        if (!error.type) {
            [MEGASdkManager.sharedMEGASdk getAccountDetailsWithDelegate:self];
        }
    }
    
    if (request.type == MEGARequestTypeAccountDetails) {
        if (!error.type) {
            [self updateDeleteVersionsUIBy:[self totalNumberOfFileVersionsOfCurrentAccount]];
            [self.tableView reloadData];
        }
    }
    
    if ((request.type == MEGARequestTypeSetAttrUser) && (request.paramType == MEGAUserAttributeDisableVersions)) {
        if (!error.type) {
            self.fileVersioningSwitch.on = self.fileVersioningEnabled = ![request.text isEqualToString:@"1"];
            
            [self.tableView reloadData];
        }
    }
}

@end
