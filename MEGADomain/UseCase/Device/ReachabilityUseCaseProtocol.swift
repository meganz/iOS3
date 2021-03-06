import Foundation

protocol ReachabilityUseCaseProtocol {

    func isReachable() -> Bool

    func registerNetworkChangeListener(
        _ lisetner: @escaping (NetworkReachability) -> Void
    )
}

final class ReachabilityUseCase: ReachabilityUseCaseProtocol {

    private var networkChangedListener: ((NetworkReachability) -> Void)?

    func registerNetworkChangeListener(_ lisetner: @escaping (NetworkReachability) -> Void) {
        self.networkChangedListener = lisetner
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(networkConnectionDidChange),
            name: .reachabilityChanged,
            object: nil
        )
    }
    
    func isReachable() -> Bool {
        MEGAReachabilityManager.isReachable()
    }

    // MARK: - Internals & Privates

    @objc private func networkConnectionDidChange() {
        guard let networkChangedListener = networkChangedListener else { return }
        switch isReachable() {
        case false: networkChangedListener(.unreachable)
        case true: networkChangedListener(.reachable(reachableApproach()))
        }
    }

    private func reachableApproach() -> ReachabilityApproach {
        if MEGAReachabilityManager.isReachableViaWWAN() { return .viaWWAN }
        if MEGAReachabilityManager.isReachableViaWiFi() { return .viaWiFi }
        return .unexpected
    }
    
    // MARK: - Lifecycles
    
    deinit {
        if networkChangedListener != nil {
            NotificationCenter.default.removeObserver(
                self,
                name: .reachabilityChanged, object: nil
            )
        }
    }
}
