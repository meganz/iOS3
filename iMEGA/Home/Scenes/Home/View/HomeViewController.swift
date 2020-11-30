import UIKit

@objc(HomeRouting)
protocol HomeRouting: NSObjectProtocol {

    func showAchievements()

    func showOfflines()
}

final class HomeViewController: UIViewController {

    // MARK: - View Model
    
    var accountViewModel: HomeAccountViewModelType!

    var uploadViewModel: HomeUploadingViewModelType!
    
    var startConversationViewModel: StartConversationViewModel!

    var recentsViewModel: HomeRecentActionViewModelType!

    // MARK: - Router

    var router: HomeRouter!

    // MARK: - IBOutlets

    @IBOutlet private weak var topStackView: UIStackView!

    @IBOutlet private weak var exploreView: ExploreViewStack!

    @IBOutlet private weak var bannerCollectionView: MEGABannerView!

    @IBOutlet private weak var slidePanelView: SlidePanelView!

    @IBOutlet weak var searchBarView: MEGASearchBarView!

    private weak var startConversationItem: UIBarButtonItem!

    private weak var startUploadBarButtonItem: UIBarButtonItem!

    private weak var badgeButton: BadgeButton!

    private var searchResultContainerView: UIView!

    // MARK: - SlidePanel Related Properties
    
    /// A layout constraint that make `SlidePanel` docking to `bottom` position.
    @IBOutlet var constraintToBottomPosition: NSLayoutConstraint!

    /// A layout constraint that make `SlidePanel` docking to `top` position.
    @IBOutlet var constraintToTopPosition: NSLayoutConstraint! {
        didSet {
            constraintToTopPosition.isActive = false
        }
    }
    
    // MARK: - Slide Panel

    private lazy var slidePanelAnimator: SlidePanelAnimationController = SlidePanelAnimationController(
        delegate: self
    )

    /// ContentViewController that has the content of `SlidePanel`
    private lazy var contentViewController: RecentsViewController = {
        let recentsViewController = UIStoryboard(name: "Recents", bundle: nil)
            .instantiateViewController(withIdentifier: "RecentsViewControllerID") as! RecentsViewController
        recentsViewController.delegate = self
        return recentsViewController
    }()

    private lazy var offlineViewController: OfflineViewController = {
        let offlineVC = UIStoryboard(name: "Offline", bundle: nil)
            .instantiateViewController(withIdentifier: "OfflineViewControllerID") as! OfflineViewController
        offlineVC.flavor = .HomeScreen
        return offlineVC
    }()

    var searchResultViewController: HomeSearchResultViewController!

    // MARK: - ViewController Lifecycles

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        refreshView(with: traitCollection)
        setupViewModelEventListening()
    }

    private func setupViewModelEventListening() {
        accountViewModel.notifyUpdate = { [weak self] output in
            guard let self = self else { return }
            let resizedImage = output.avatarImage

            if let badgeButton = self.badgeButton {
                badgeButton.setBadgeText(output.notificationNumber)
                badgeButton.setBackgroundImage(resizedImage, for: .normal)
            } else {
                let badgeButton = BadgeButton()
                badgeButton.setBadgeText(output.notificationNumber)
                badgeButton.setBackgroundImage(resizedImage, for: .normal)
                badgeButton.addTarget(self, action: .didTapAvatar, for: .touchUpInside)
                self.badgeButton = badgeButton

                let avatarButtonItem = UIBarButtonItem(customView: badgeButton)
                self.navigationItem.leftBarButtonItems = [avatarButtonItem]
            }
        }
        accountViewModel.inputs.viewIsReady()

        recentsViewModel.notifyUpdate = { [weak self] recentsViewModel in
            if let error = recentsViewModel.error {
                self?.handle(error)
            }
        }
        
        startConversationViewModel.dispatch(.viewDidLoad)
        startConversationViewModel.invokeCommand = { [weak self] command in
            switch command {
            case .networkAvailablityUpdate(let networkAvailable):
                self?.startConversationItem.isEnabled = networkAvailable
            }
        }

        uploadViewModel.notifyUpdate = { [weak self] homeUploadingViewModel in
            asyncOnMain {
                guard let self = self else { return }
                self.startUploadBarButtonItem?.isEnabled = homeUploadingViewModel.networkReachable

                switch homeUploadingViewModel.state {
                case .permissionDenied(let error): self.handle(error)
                case .normal: break
                }
            }
        }
        uploadViewModel.inputs.didLoadView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupSlidePanelVerticalOffset()
    }

    private func setupSlidePanelVerticalOffset() {
        guard slidePanelAnimator.animationOffsetY == nil else { return }
        // Will only be executed once - the first time, and tell the `SlidePanelAnimator` that the **Vertical Offset**
        // between the top of slide panel and the top of `searchBarView`.
        slidePanelAnimator.animationOffsetY = (slidePanelView.frame.minY - searchBarView.frame.minY) + Constant.slidePanelRoundCornerHeight
    }

    private enum Constant {
        static let slidePanelRoundCornerHeight: CGFloat = 20 // This value need to be same as `constraintToTopPosition`
    }

    // MARK: - View Setup

    private func setupView() {
        setTitle(with: "MEGA")
        setupRightItems()
        setupSearchBarView(searchBarView)
        setupSearchResultExtendedLayout()

        // For this release, banner is hidden, hide the banner until when it's ready.
        bannerCollectionView.isHidden = true

        slidePanelView.delegate = self
        exploreView.delegate = self

        addContentViewController()
        addOfflineViewController()
    }


    private func setTitle(with text: String) {
        navigationItem.title = text
        // Avoid using the title on pushing a view controller
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }

    private func setupSearchResultExtendedLayout() {
        if #available(iOS 11, *) {
            edgesForExtendedLayout = .top
        } else {
            edgesForExtendedLayout = []
        }
        extendedLayoutIncludesOpaqueBars = true
    }

    private func setupRightItems() {
        let startConversationItem = UIBarButtonItem(
            image: UIImage(named: "startChat"),
            style: .plain,
            target: self,
            action: .didTapNewChat
        )
        self.startConversationItem = startConversationItem

        let startUploadBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "uploadFile"),
            style: .plain,
            target: self,
            action: .didTapNewUpload
        )
        self.startUploadBarButtonItem = startUploadBarButtonItem

        navigationItem.setRightBarButtonItems([startUploadBarButtonItem, startConversationItem], animated: false)
    }
    
    private func setupSearchBarView(_ searchBarView: MEGASearchBarView) {
        searchBarView.delegate = self
        searchBarView.edittingDelegate = searchResultViewController
        searchResultViewController.searchHintSelectDelegate = searchBarView
    }

    private func addContentViewController() {
        contentViewController.willMove(toParent: self)
        addChild(contentViewController)
        slidePanelView.addRecentsViewController(contentViewController)
        contentViewController.didMove(toParent: self)
    }

    private func addOfflineViewController() {
        offlineViewController.willMove(toParent: self)
        addChild(offlineViewController)
        slidePanelView.addOfflineViewController(offlineViewController)
        contentViewController.didMove(toParent: self)
    }

    // MARK: - Refresh view with light/dark mode

    private func refreshView(with trait: UITraitCollection) {
        setupBackgroundColor(with: trait)
        setupNavigationBarColor(with: trait)
    }

    private func setupBackgroundColor(with trait: UITraitCollection) {
        switch trait.theme {
        case .light:
            slidePanelView.backgroundColor = UIColor.mnz_grayF7F7F7()
            view.backgroundColor = UIColor.mnz_grayF7F7F7()
        case .dark:
            slidePanelView.backgroundColor = UIColor.black
            view.backgroundColor = UIColor.black
        }
    }

    private func setupNavigationBarColor(with trait: UITraitCollection) {
        let color: UIColor
        switch trait.theme {
        case .light:
            color = constraintToTopPosition.isActive ? .white : UIColor.mnz_grayF7F7F7()
        case .dark:
            color = constraintToTopPosition.isActive ? .mnz_black1C1C1E() : .black
        }

        let navigationBar = navigationController?.navigationBar
        if #available(iOS 13, *) {
            navigationBar?.standardAppearance.backgroundColor = color
            navigationBar?.scrollEdgeAppearance?.backgroundColor = color
            navigationBar?.isTranslucent = false
        } else {
            navigationBar?.backgroundColor = color
            navigationBar?.barTintColor = color
        }
    }


    // MARK: - Tap Actions

    @objc fileprivate func didTapAvatarItem() {
        router.didTap(on: .avatar)
    }

    @objc fileprivate func didTapNewChat() {
        router.didTap(on: .newChat)
    }

    @objc fileprivate func didTapNewUpload() {
        let sourceItems = uploadViewModel.inputs.didTapUploadFromSourceItems()
        let sourceActions = sourceItems.map { [weak self] item -> ActionSheetAction in
            ActionSheetAction(title: item.title, detail: nil, accessoryView: nil, image: item.icon, style: .default) {
                self?.didSelectUploadSource(item.source)
            }
        }

        router.didTap(on: .uploadButton, with: sourceActions)
    }
}

// MARK: - SlidePanelAnimationControllerDelegate

extension HomeViewController: SlidePanelAnimationControllerDelegate {

    private func navigationBarTransitionColors(for trait: UITraitCollection) -> (UIColor, UIColor) {
        if #available(iOS 12, *) {
            switch trait.userInterfaceStyle {
            case .dark:
                return (.mnz_black1C1C1E(), .black)
            default:
                return (.white, .mnz_grayF7F7F7())
            }
        } else {
            return (.white, .mnz_grayF7F7F7())
        }
    }

    private func updateNavigationBarColor(_ color: UIColor) {
        let navigationBar = navigationController?.navigationBar
        if #available(iOS 13, *) {
            navigationBar?.standardAppearance.backgroundColor = color
            navigationBar?.scrollEdgeAppearance?.backgroundColor = color
            navigationBar?.isTranslucent = false
        } else {
            navigationBar?.backgroundColor = color
            navigationBar?.barTintColor = color
        }
    }

    func didUpdateAnimationProgress(
        _ animationProgress: CGFloat,
        from initialDockingPosition: SlidePanelAnimationController.DockingPosition,
        to targetDockingPosition: SlidePanelAnimationController.DockingPosition
    ) {
        let (slideColor, navigationBarColor) = navigationBarTransitionColors(for: self.traitCollection)
        let color: UIColor
        switch (initialDockingPosition, targetDockingPosition) {
        case (.top, .bottom):
            color = navigationBarColor
        case (.bottom, .top):
            let startColor = navigationBarColor
            let endColor = slideColor
            color = startColor.toColor(endColor, percentage: animationProgress * 100)
        default: fatalError("No other combinations")
        }
        updateNavigationBarColor(color)
    }

    func animateToTopPosition() {
        self.constraintToBottomPosition.isActive = false
        self.constraintToTopPosition.isActive = true
        self.view.layoutIfNeeded()
    }

    func animateToBottomPosition() {
        self.constraintToBottomPosition.isActive = true
        self.constraintToTopPosition.isActive = false
        self.view.layoutIfNeeded()
    }
}

// MARK: - SlidePanelDelegate

extension HomeViewController: SlidePanelDelegate {

    func slidePanel(_ panel: SlidePanelView, didBeginPanningWithVelocity velocity: CGPoint) {
        slidePanelAnimator.startsProgressiveAnimation(withDuration: 0.3)
    }

    func slidePanel(_ panel: SlidePanelView, didStopPanningWithVelocity velocity: CGPoint) {
        slidePanelAnimator.completeAnimation(withVelocityY: velocity.y)
    }

    func slidePanel(_ panel: SlidePanelView, translated: CGPoint, velocity: CGPoint) {
        slidePanelAnimator.continueAnimation(withVelocityY: velocity.y, translationY: translated.y)
    }
    
    func shouldEnablePanGestureScrollingUp(inSlidePanel slidePanel: SlidePanelView) -> Bool {
        slidePanelAnimator.isInBottomDockingPosition()
    }
    
    func shouldEnablePanGestureScrollingDown(inSlidePanel slidePanel: SlidePanelView) -> Bool {
        slidePanelAnimator.isInTopDockingPosition() && slidePanelView.isOverScroll()
    }
    
    func shouldEnablePanGesture(inSlidePanel slidePanel: SlidePanelView) -> Bool {
        shouldEnablePanGestureScrollingDown(inSlidePanel: slidePanel) ||
            shouldEnablePanGestureScrollingDown(inSlidePanel: slidePanel)
    }
    
    func shouldEnablePanGestureInSlidePanel(_ panel: SlidePanelView, withVelocity velocity: CGPoint) -> Bool {
        let scrollUp = velocity.y < 0
        let scrollDown = velocity.y > 0
        
        if slidePanelAnimator.isInBottomDockingPosition() && scrollUp {
            return true
        }
        
        if slidePanelAnimator.isInTopDockingPosition() && scrollDown && slidePanelView.isOverScroll() {
            return true
        }
        return false
    }
}

// MARK: - Explorer view delegate

extension HomeViewController: ExploreViewStackDelegate {
    func tappedCard(_ card: MEGAExploreViewStyle) {
        switch card {
        case .images:   router.photosExplorerSelected()
        case .documents:    router.documentsExplorerSelected()
        case .audio:    router.audioExplorerSelected()
        case .video:    router.videoExplorerSelected()
        }
    }
}

// MARK: - Lock of orientation for Home

extension HomeViewController {

    // MARK: - Force Vertical

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}

// MARK: - File Upload

extension HomeViewController {

    private func didSelectUploadSource(_ source: FileUploadingSourceItem.Source) {
        switch source {
        case .photos:
            uploadViewModel.inputs.didTapUploadFromPhotoAlbum()
        case .capture:
            uploadViewModel.inputs.didTapUploadFromCamera()
        case .imports:
            uploadViewModel.inputs.didTapUploadFromImports()
        case .documentScan:
            uploadViewModel.inputs.didTapUploadFromDocumentScan()
        }
    }
}

// MARK: - HomeRouting

extension HomeViewController: HomeRouting {
    func showAchievements() {
        router.didTap(on: .showAchievement)
    }

    func showOfflines() {
        router.didTap(on: .showOffline)
    }
}

// MARK: - RecentNodeActionDelegate

extension HomeViewController: RecentNodeActionDelegate {

    func showSelectedNode(in viewController: UIViewController!) {
        navigationController?.present(viewController, animated: true, completion: nil)
    }

    func showCustomActions(for node: MEGANode!, fromSender sender: Any!) {
        let selectionAction: (MEGANode, MegaNodeActionType) -> Void = { [router, weak self] node, action in
            guard let self = self else { return }
            switch action {

            // MARK: - Info
            case .info:
                router?.didTap(on: .fileInfo(node))

            // MARK: - Links
            case .manageLink, .getLink:
                router?.didTap(on: .linkManagement(node))
            case .removeLink:
                router?.didTap(on: .removeLink(node))

            // MARK: - Copy & Move & Delete
            case .moveToRubbishBin:
                router?.didTap(on: .delete(node))
            case .copy:
                router?.didTap(on: .copy(node))
            case .move:
                router?.didTap(on: .move(node))
            case .restore:
                node.mnz_restore()

            // MARK: - Save && Download
            case .saveToPhotos:
                self.recentsViewModel.inputs.saveToPhotoAlbum(of: node)
            case .download:
                SVProgressHUD.show(
                    UIImage(named: "hudDownload")!,
                    status: AMLocalizedString("downloadStarted", "Message shown when a download starts")
                )
                node.mnz_downloadNodeOverwriting(true)

            // MARK: - Rename
            case .rename:
                node.mnz_renameNode(in: self)

            // MARK: - Share
            case .share:
                router?.didTap(on: .share(node))
            case .shareFolder:
                router?.didTap(on: .shareFolder(node))
            case .manageShare:
                router?.didTap(on: .manageShare(node))
            case .leaveSharing:
                node.mnz_leaveSharing(in: self)

            // MARK: - Send to chat
            case .sendToChat:
                node.mnz_sendToChat(in: self)

            // MARK: - Favourite
            case .favourite:
                self.recentsViewModel.inputs.toggleFavourite(of: node)

            case .label:
                self.router.didTap(on: .setLabel(node))
            default:
                break
            }
        }
        router.didTap(on: .nodeCustomActions(node), with: selectionAction)
    }
}

// MARK: - HomeSearchControllerDelegate

extension HomeViewController: HomeSearchControllerDelegate {
    func didSelect(searchText: String) {
        guard #available(iOS 11, *) else { return }
        navigationItem.searchController?.searchBar.text = searchText
    }
}

// MARK: - TraitEnviromentAware

extension HomeViewController: TraitEnviromentAware {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }

    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        refreshView(with: currentTrait)
    }
}

// MARK: - MEGASearchBarViewDelegate

extension HomeViewController: MEGASearchBarViewDelegate {

    func didStartSearchSessionOnSearchController(_ searchController: MEGASearchBarView) {
        navigationController?.setNavigationBarHidden(true, animated: true)

        guard searchResultContainerView == nil else { return }

        let containerView = UIView(forAutoLayout: ())
        searchResultContainerView = containerView

        view.addSubview(containerView)
        containerView.autoPinEdge(.top, to: .bottom, of: searchBarView)
        containerView.autoPinEdge(.leading, to: .leading, of: view)
        containerView.autoPinEdge(.trailing, to: .trailing, of: view)
        containerView.autoPinEdge(.bottom, to: .bottom, of: view)
        containerView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        searchResultViewController.view.translatesAutoresizingMaskIntoConstraints = false
        searchResultViewController.willMove(toParent: self)
        addChild(searchResultViewController)
        containerView.addSubview(searchResultViewController.view)
        searchResultViewController.view.autoPinEdgesToSuperviewEdges()
        searchResultViewController.didMove(toParent: self)
    }

    func didResumeSearchSessionOnSearchController(_ searchController: MEGASearchBarView) {
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    func didFinishSearchSessionOnSearchController(_ searchController: MEGASearchBarView) {
        navigationController?.setNavigationBarHidden(false, animated: true)
        searchResultViewController.willMove(toParent: nil)
        searchResultContainerView.constraints.deactivate()
        searchResultViewController.view.removeFromSuperview()
        searchResultViewController.removeFromParent()
        searchResultContainerView.removeFromSuperview()
        searchResultContainerView = nil
    }
}

extension UIColor {
    func toColor(_ color: UIColor, percentage: CGFloat) -> UIColor {
        let percentage = max(min(percentage, 100), 0) / 100
        switch percentage {
        case 0: return self
        case 1: return color
        default:
            var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
            var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
            guard self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1) else { return self }
            guard color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else { return self }

            return UIColor(red: CGFloat(r1 + (r2 - r1) * percentage),
                           green: CGFloat(g1 + (g2 - g1) * percentage),
                           blue: CGFloat(b1 + (b2 - b1) * percentage),
                           alpha: CGFloat(a1 + (a2 - a1) * percentage))
        }
    }
}

// MARK: - Private Selector Extensions

private extension Selector {
    static let didTapAvatar = #selector(HomeViewController.didTapAvatarItem)
    static let didTapNewChat = #selector(HomeViewController.didTapNewChat)
    static let didTapNewUpload = #selector(HomeViewController.didTapNewUpload)
}