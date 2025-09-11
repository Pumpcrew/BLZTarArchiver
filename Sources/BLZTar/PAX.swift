
import Foundation

final class PAXRecord {
    var path: String?
}

func needsPAX(forPath path: String) -> Bool {
    if path.utf8.count > 255 { return true }
    let (name, prefix) = splitPathUSTAR(path)
    if name.utf8.count > 100 || prefix.utf8.count > 155 { return true }
    return false
}

func ustarCompatibleName(_ path: String) -> String {
    let (name, prefix) = splitPathUSTAR(path)
    return prefix.isEmpty ? name : (prefix + "/" + name)
}

func paxHeaderName(for path: String) -> String {
    let base = (path as NSString).lastPathComponent
    return "PaxHeaders.\(Int.random(in: 0...Int.max))/\(base)"
}

func buildPAX(path: String) -> Data {
    func paxLine(key: String, value: String) -> Data {
        let kv = "\(key)=\(value)\n"
        var len = "\(kv.utf8.count + 2) "
        while true {
            let full = "\(len)\(kv)"
            let actual = full.utf8.count
            let digits = String(actual).utf8.count
            let expect = "\(digits) "
            if len == expect { return Data(full.utf8) }
            len = "\(actual) "
        }
    }
    var d = Data()
    d.append(paxLine(key: "path", value: path))
    return d
}

func parsePAX(_ data: Data) throws -> PAXRecord {
    var idx = 0
    let rec = PAXRecord()
    while idx < data.count {
        var lenStr = ""
        while idx < data.count, let ch = UnicodeScalar(data[idx]), ch >= "0" && ch <= "9" {
            lenStr.append(Character(ch)); idx += 1
        }
        guard idx < data.count, data[idx] == 0x20 else { throw TarError.paxMalformed }
        idx += 1
        guard let length = Int(lenStr), length > 0, (idx - (lenStr.count + 1)) + length <= data.count else { throw TarError.paxMalformed }
        let start = idx
        let slice = data[start ..< (start + length - (lenStr.count + 1))]
        if let line = String(data: slice, encoding: .utf8),
           let eq = line.firstIndex(of: "=") {
            let key = String(line[..<eq])
            let val = String(line[line.index(after: eq)...]).trimmingCharacters(in: .newlines)
            if key == "path" { rec.path = val }
        }
        idx = (idx - (lenStr.count + 1)) + length
    }
    return rec
}
