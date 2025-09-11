
import Foundation

final class ProgressEmitter {
    private let total: Int64
    private var processed: Int64 = 0
    private var lastEmitted: Int64 = 0
    private let granularity: Int64
    private let cb: ((Int64, Int64) -> Void)?

    init(total: Int64, granularity: Int64, cb: ((Int64, Int64) -> Void)?) {
        self.total = max(0, total)
        self.granularity = max(1, granularity)
        self.cb = cb
    }

    func add(_ delta: Int64) {
        guard let cb else { return }
        processed &+= delta
        if processed - lastEmitted >= granularity || processed == total {
            lastEmitted = processed
            cb(min(processed, total), total)
        }
    }

    func finish() {
        guard let cb else { return }
        cb(total, total)
    }
}
