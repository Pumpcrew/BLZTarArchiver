
import Foundation

func simpleMatch(text: String, pattern: String) -> Bool {
    func match(_ t: ArraySlice<Character>, _ p: ArraySlice<Character>) -> Bool {
        if p.isEmpty { return t.isEmpty }
        let pc = p.first!
        if pc == "*" { return match(t, p.dropFirst()) || (!t.isEmpty && match(t.dropFirst(), p)) }
        if pc == "?" { return !t.isEmpty && match(t.dropFirst(), p.dropFirst()) }
        return (!t.isEmpty && t.first! == pc) && match(t.dropFirst(), p.dropFirst())
    }
    return match(ArraySlice(text), ArraySlice(pattern))
}

func shouldExclude(_ path: String, patterns: [String]) -> Bool {
    for p in patterns { if simpleMatch(text: path, pattern: p) { return true } }
    return false
}

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
import Darwin
#else
import Glibc
#endif

func modeOf(_ url: URL) throws -> UInt32 {
    var st = stat()
    guard lstat(url.path, &st) == 0 else { throw TarError.ioFailed("lstat failed") }
    return UInt32(st.st_mode & 0o7777)
}

func mtimeOf(_ url: URL) throws -> Int64 {
    var st = stat()
    guard lstat(url.path, &st) == 0 else { throw TarError.ioFailed("lstat failed") }
    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    return Int64(st.st_mtimespec.tv_sec)
    #else
    return Int64(st.st_mtim.tv_sec)
    #endif
}

func setMode(_ url: URL, mode: UInt32) throws {
    _ = try? FileManager.default.setAttributes([.posixPermissions: NSNumber(value: mode)], ofItemAtPath: url.path)
}

func setMtime(_ url: URL, mtime: Int64) throws {
    let d = Date(timeIntervalSince1970: TimeInterval(mtime))
    try FileManager.default.setAttributes([.modificationDate: d], ofItemAtPath: url.path)
}

func secureJoin(base: URL, relative: String) throws -> URL {
    let dest = base.appendingPathComponent(relative)
    let stdBase = base.standardizedFileURL
    let stdDest = dest.standardizedFileURL
    if !stdDest.path.hasPrefix(stdBase.path) { throw TarError.pathTraversalDetected }
    return stdDest
}
