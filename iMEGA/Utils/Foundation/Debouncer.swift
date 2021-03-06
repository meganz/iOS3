import Foundation

final class Debouncer {
    private let delay: TimeInterval
    private let dispatchQueue: DispatchQueue
    private let workQueue = DispatchQueue(label: "DebouncerWorkQueue")

    private var dispatchWork: DispatchWorkItem?

    init(delay: TimeInterval, dispatchQueue: DispatchQueue = .main) {
        self.delay = delay
        self.dispatchQueue = dispatchQueue
    }

    private func execute(_ action: @escaping () -> Void) {
        let dispatchWork = DispatchWorkItem { action() }
        self.dispatchWork = dispatchWork
        dispatchQueue.asyncAfter(deadline: .now() + delay, execute: dispatchWork)
    }

    func start(action: @escaping () -> Void) {
        workQueue.async {
            self.cancel()
            self.execute(action)
        }
    }

    func cancel() {
        dispatchWork?.cancel()
    }
}
