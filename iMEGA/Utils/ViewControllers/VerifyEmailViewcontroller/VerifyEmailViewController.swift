import UIKit

class VerifyEmailViewController: UIViewController {

    @IBOutlet weak var warningGradientView: UIView!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var topDescriptionLabel: UILabel!
    @IBOutlet weak var bottomDescriptionLabel: UILabel!
    @IBOutlet weak var hintLabel: UILabel!

    @IBOutlet weak var topSeparatorView: UIView!
    @IBOutlet weak var bottomSeparatorView: UIView!

    @IBOutlet weak var hintButton: UIButton!
    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!

    // MARK: Lifecyle

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(checkIfBlocked), name:
            UIApplication.willEnterForegroundNotification, object: nil)
        configureUI()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateAppearance()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        addGradientBackground()
    }

    // MARK: Private

    func configureUI() {
        localizeLabels()
        boldenText()
        updateAppearance()
    }
    
    func updateAppearance() {
        resendButton.mnz_setupBasic(traitCollection)

        topSeparatorView.backgroundColor = UIColor.mnz_separator(for: traitCollection)
        hintButton.setTitleColor(.mnz_turquoise(for: traitCollection), for: .normal)
        hintButton.backgroundColor = .mnz_tertiaryBackgroundElevated(traitCollection)
        bottomSeparatorView.backgroundColor = UIColor.mnz_separator(for: traitCollection)
        
        hintLabel.textColor = UIColor .mnz_subtitles(for: traitCollection)
    }

    func addGradientBackground () {
        let gradient = CAGradientLayer()
        gradient.frame = warningGradientView.bounds
        gradient.colors = [
            UIColor(red: 1, green: 0.39, blue: 0.39, alpha: 1).cgColor,
            UIColor(red: 0.81, green: 0.29, blue: 0.29, alpha: 1).cgColor
        ]
        gradient.locations = [0, 1]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)

        warningGradientView.layer.addSublayer(gradient)
    }

    func boldenText() {
        guard let bottomString = bottomDescriptionLabel.text?.replacingOccurrences(of: "[S]", with: "") else { return }

        let bottomStringComponents = bottomString.components(separatedBy: "[/S]")
        guard let textToBolden = bottomStringComponents.first, let textRegular = bottomStringComponents.last else { return }

        let attributtedString = NSMutableAttributedString(string: textToBolden, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .semibold)])
        let regularlString = NSAttributedString(string: textRegular, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .regular)])
        attributtedString.append(regularlString)

        bottomDescriptionLabel.attributedText = attributtedString
    }

    func showWhyIAmBlocked() {
        let customModal = CustomModalAlertViewController.init()

        customModal.image = UIImage(named: "lockedAccounts")
        customModal.viewTitle = NSLocalizedString("Locked Accounts", comment: "Title of a helping view about locked accounts")
        customModal.detail = NSLocalizedString("It is possible that you are using the same password for your MEGA account as for other services, and that at least one of these other services has suffered a data breach.", comment: "Locked accounts description text by an external data breach. This text is 1 of 2 paragraph of a description.") + "\n\n" + NSLocalizedString("Your password leaked and is now being used by bad actors to log into your accounts, including, but not limited to, your MEGA account.", comment: "Locked accounts description text by bad use of user password. This text is 2 of 2 paragraph of a description.")
        customModal.dismissButtonTitle = NSLocalizedString("close", comment: "A button label. The button allows the user to close the conversation.")

        present(customModal, animated: true, completion: nil)
    }

    func localizeLabels() {
        topDescriptionLabel.text = NSLocalizedString("Your account has been temporarily suspended for your safety.", comment: "Text describing account suspended state to the user")
        bottomDescriptionLabel.text = NSLocalizedString("[S]Please verify your email[/S] and follow its steps to unlock your account.", comment: "Text indicating the user next step to unlock suspended account. Please leave [S], [/S] as it is which is used to bolden the text.")
        resendButton.setTitle(NSLocalizedString("resend", comment: "A button to resend the email confirmation."), for: .normal)
        logoutButton.setTitle(NSLocalizedString("logoutLabel", comment: "Title of the button which logs out from your account."), for: .normal)
        hintButton.setTitle(NSLocalizedString("Why am I seeing this?", comment: "Text for button to open an helping view"), for: .normal)
        hintLabel.text = NSLocalizedString("Email sent", comment: "Text to notify user an email has been sent")
    }

    @objc func checkIfBlocked() {
        let whyAmIBlockedRequestDelegate = MEGAGenericRequestDelegate.init { (request, error) in
            if error.type == .apiOk && request.number == 0 {

                if MEGASdkManager.sharedMEGASdk().rootNode == nil {
                    guard let session = SAMKeychain.password(forService: "MEGA", account: "sessionV3") else { return }
                    let loginRequestDelegate = MEGALoginRequestDelegate.init()
                    MEGASdkManager.sharedMEGASdk().fastLogin(withSession: session, delegate: loginRequestDelegate)
                }

                self.presentedViewController?.dismiss(animated: true, completion: nil)
                self.dismiss(animated: true, completion: nil)
            }
        }
        MEGASdkManager.sharedMEGASdk().whyAmIBlocked(with: whyAmIBlockedRequestDelegate)
    }

    // MARK: Actions

    @IBAction func tapHintButton(_ sender: Any) {
        showWhyIAmBlocked()
    }

    @IBAction func tapResendButton(_ sender: Any) {
        if MEGAReachabilityManager.isReachableHUDIfNot() {
            SVProgressHUD.show()
            let resendVerificationEmailDelegate = MEGAGenericRequestDelegate.init { (_, error) in
                SVProgressHUD.dismiss()
                if error.type == .apiOk || error.type == .apiEArgs {
                    self.hintLabel.isHidden = false
                } else {
                    SVProgressHUD.showError(withStatus: NSLocalizedString("Email already sent. Please wait a few minutes before trying again.", comment: "Error text shown when requesting email for email verification within 10 minutes"))
                }
            }
            MEGASdkManager.sharedMEGASdk().resendVerificationEmail(with: resendVerificationEmailDelegate)
        }
    }

    @IBAction func tapLogoutButton(_ sender: Any) {
        MEGASdkManager.sharedMEGASdk().logout()
    }
}
