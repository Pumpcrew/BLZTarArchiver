
import Foundation

enum TarError: Error {
    case invalidHeader
    case ioFailed(String)
    case pathTraversalDetected
    case unsupportedType
    case paxMalformed
    case gzipUnsupportedEngine
    case cancelled
}

final class TarHeader {
    enum TypeFlag: UInt8 {
        case regular      = 0x30  // '0'
        case directory    = 0x35  // '5'
        case paxExtended  = 0x78  // 'x'
    }

    var path: String
    var fileSize: Int64
    var typeflag: TypeFlag
    var permissions: UInt32
    var mtime: Int64

    init(path: String, fileSize: Int64, typeflag: TypeFlag, permissions: UInt32 = 0o644, mtime: Int64 = Int64(Date().timeIntervalSince1970)) {
        self.path = path
        self.fileSize = fileSize
        self.typeflag = typeflag
        self.permissions = permissions
        self.mtime = mtime
    }

    func encode() throws -> Data {
        var block = Data(repeating: 0, count: 512)
        let (name, prefix) = splitPathUSTAR(path)

        try putString(name, into: &block, at: 0, len: 100)
        try putOctal(UInt64(permissions), into: &block, at: 100, len: 8)
        try putOctal(0, into: &block, at: 108, len: 8)
        try putOctal(0, into: &block, at: 116, len: 8)
        try putOctal(UInt64(fileSize), into: &block, at: 124, len: 12)
        try putOctal(UInt64(mtime), into: &block, at: 136, len: 12)
        for i in 148..<156 { block[i] = 0x20 }
        block[156] = typeflag.rawValue
        try putString("", into: &block, at: 157, len: 100)
        try putString("ustar", into: &block, at: 257, len: 6)
        try putString("00", into: &block, at: 263, len: 2)
        try putString("", into: &block, at: 265, len: 32)
        try putString("", into: &block, at: 297, len: 32)
        try putOctal(0, into: &block, at: 329, len: 8)
        try putOctal(0, into: &block, at: 337, len: 8)
        try putString(prefix, into: &block, at: 345, len: 155)

        let checksum = block.reduce(0) { UInt64($0) + UInt64($1) }
        try putOctal(checksum, into: &block, at: 148, len: 8)
        return block
    }

    static func decode(from data: Data) throws -> TarHeader {
        guard data.count == 512 else { throw TarError.invalidHeader }
        func str(_ range: Range<Int>) -> String {
            String(bytes: data[range], encoding: .utf8)?
                .trimmingCharacters(in: .controlCharacters.union(.whitespacesAndNewlines)) ?? ""
        }
        func oct(_ range: Range<Int>) -> Int64 {
            let s = str(range).trimmingCharacters(in: .whitespacesAndNewlines)
            return Int64(s, radix: 8) ?? 0
        }

        let name = str(0..<100)
        let mode = UInt32(oct(100..<108))
        let size = oct(124..<136)
        let mtime = oct(136..<148)
        let typeRaw = data[156]
        let prefix = str(345..<500)
        let fullPath = prefix.isEmpty ? name : (prefix + "/" + name)

        guard let tf = TypeFlag(rawValue: typeRaw) else { throw TarError.unsupportedType }
        return TarHeader(path: fullPath, fileSize: size, typeflag: tf, permissions: mode, mtime: mtime)
    }
}

func splitPathUSTAR(_ path: String) -> (String, String) {
    if path.utf8.count <= 100 { return (path, "") }
    var idx = path.lastIndex(of: "/") ?? path.startIndex
    while idx > path.startIndex {
        let name = String(path[path.index(after: idx)...])
        let prefix = String(path[..<idx])
        if name.utf8.count <= 100 && prefix.utf8.count <= 155 { return (name, prefix) }
        idx = path[..<idx].lastIndex(of: "/") ?? path.startIndex
        if idx == path.startIndex { break }
    }
    let name = String(path.suffix(100))
    let prefix = String(path.dropLast(name.utf8.count)).suffix(155)
    return (String(name), String(prefix))
}

func putString(_ s: String, into data: inout Data, at: Int, len: Int) throws {
    let bytes = Array(s.utf8.prefix(len))
    data.replaceSubrange(at..<(at + bytes.count), with: bytes)
    if bytes.count < len { /* NUL padding */ }
}
func putOctal(_ v: UInt64, into data: inout Data, at: Int, len: Int) throws {
    let s = String(v, radix: 8)
    let pad = max(0, len - 1 - s.count)
    let out = String(repeating: "0", count: pad) + s
    let bytes = Array(out.utf8)
    data.replaceSubrange(at..<(at + bytes.count), with: bytes)
    data[at + len - 1] = 0
}
