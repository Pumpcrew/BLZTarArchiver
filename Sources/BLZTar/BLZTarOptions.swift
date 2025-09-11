
import Foundation

public final class BLZTarArchiveOptions {
    public enum GzipEngine { case zlib, nioExtras }

    public var gzip: Bool
    public var gzipEngine: GzipEngine
    public var excludes: [String]
    public var preservePermissions: Bool
    public var onProgressBytes: ((Int64, Int64) -> Void)?
    public var reportGranularityBytes: Int64
    public var onProgressPerFile: ((URL, Int64, Int64) -> Void)?

    public init(
        gzip: Bool = false,
        gzipEngine: GzipEngine = .zlib,
        excludes: [String] = [],
        preservePermissions: Bool = true,
        onProgressBytes: ((Int64, Int64) -> Void)? = nil,
        reportGranularityBytes: Int64 = 512 * 1024,
        onProgressPerFile: ((URL, Int64, Int64) -> Void)? = nil
    ) {
        self.gzip = gzip
        self.gzipEngine = gzipEngine
        self.excludes = excludes
        self.preservePermissions = preservePermissions
        self.onProgressBytes = onProgressBytes
        self.reportGranularityBytes = reportGranularityBytes
        self.onProgressPerFile = onProgressPerFile
    }
}

public final class BLZTarExtractOptions {
    public enum GzipEngine { case zlib, nioExtras }

    public var overwrite: Bool
    public var preservePermissions: Bool
    public var onEntry: ((String) -> Void)?
    public var onProgressBytes: ((Int64, Int64) -> Void)?
    public var reportGranularityBytes: Int64
    public var gzipEngine: GzipEngine

    public init(
        overwrite: Bool = true,
        preservePermissions: Bool = true,
        onEntry: ((String) -> Void)? = nil,
        onProgressBytes: ((Int64, Int64) -> Void)? = nil,
        reportGranularityBytes: Int64 = 512 * 1024,
        gzipEngine: GzipEngine = .zlib
    ) {
        self.overwrite = overwrite
        self.preservePermissions = preservePermissions
        self.onEntry = onEntry
        self.onProgressBytes = onProgressBytes
        self.reportGranularityBytes = reportGranularityBytes
        self.gzipEngine = gzipEngine
    }
}
