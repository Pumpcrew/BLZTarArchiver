
import Foundation

final class TarPlannedEntry {
    let path: String
    let isDir: Bool
    let size: Int64
    let needsPAX: Bool
    init(path: String, isDir: Bool, size: Int64, needsPAX: Bool) {
        self.path = path; self.isDir = isDir; self.size = size; self.needsPAX = needsPAX
    }
}

func planArchive(from directory: URL, excludes: [String]) throws -> [TarPlannedEntry] {
    var items: [TarPlannedEntry] = []
    let fm = FileManager.default
    guard let en = fm.enumerator(at: directory,
                                 includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey, .fileSizeKey],
                                 options: [.skipsHiddenFiles]) else { return [] }

    let base = directory.standardizedFileURL.path
    for case let url as URL in en {
        let rel = String(url.path.dropFirst(base.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if rel.isEmpty { continue }
        if shouldExclude(rel, patterns: excludes) { continue }
        let rv = try url.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey, .fileSizeKey])
        let isDir = rv.isDirectory ?? false
        let isReg = rv.isRegularFile ?? false
        if isDir {
            items.append(.init(path: rel, isDir: true, size: 0, needsPAX: needsPAX(forPath: rel)))
        } else if isReg {
            items.append(.init(path: rel, isDir: false, size: Int64(rv.fileSize ?? 0), needsPAX: needsPAX(forPath: rel)))
        }
    }
    return items
}

func computeTotalBytesForArchive(_ plan: [TarPlannedEntry]) -> Int64 {
    var total: Int64 = 0
    for e in plan {
        if e.needsPAX {
            let paxBody = buildPAX(path: e.path)
            total += 512
            total += Int64(paxBody.count)
            total += Int64((512 - (paxBody.count % 512)) % 512)
        }
        total += 512
        if !e.isDir {
            total += e.size
            total += Int64((512 - (Int(e.size) % 512)) % 512)
        }
    }
    total += 1024
    return total
}

func computeTotalBytesForExtraction(tarURL: URL) throws -> Int64 {
    guard let h = try? FileHandle(forReadingFrom: tarURL) else { throw TarError.ioFailed("Cannot open archive") }
    defer { try? h.close() }
    var total: Int64 = 0
    while true {
        guard let header = try? h.read(upToCount: 512), let header, header.count == 512 else { break }
        total += 512
        if header == Data(repeating: 0, count: 512) {
            if let z = try? h.read(upToCount: 512), let z, z.count == 512 { total += 512 }
            break
        }
        guard let th = try? TarHeader.decode(from: header) else { throw TarError.invalidHeader }
        let body = Int(th.fileSize)
        if body > 0 {
            total += Int64(body)
            let pad = (512 - (body % 512)) % 512
            total += Int64(pad)
            _ = try? h.read(upToCount: body)
            if pad > 0 { _ = try? h.read(upToCount: pad) }
        }
    }
    return total
}
