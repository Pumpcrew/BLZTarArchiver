
import Foundation
#if canImport(NIOCore) && canImport(NIOExtras)
import NIOCore
import NIOExtras

final class GzipNIOExtras {
    static func gzip(input: URL, output: URL, granularity: Int64, cb: ((Int64, Int64) -> Void)?) throws {
        let bytes = try Data(contentsOf: input)
        let emitter = ProgressEmitter(total: Int64(bytes.count), granularity: granularity, cb: cb)

        var inBuf = ByteBufferAllocator().buffer(capacity: bytes.count)
        inBuf.writeBytes(bytes)
        let encoder = GzipEncoder()
        var out = ByteBufferAllocator().buffer(capacity: bytes.count)

        let chunk = 256 * 1024
        while inBuf.readableBytes > 0 {
            var part = inBuf.readSlice(length: min(chunk, inBuf.readableBytes))!
            try encoder.encode(data: part, out: &out, final: inBuf.readableBytes == 0)
            emitter.add(Int64(part.readableBytes))
        }
        emitter.finish()
        let outData = out.readData(length: out.readableBytes) ?? Data()
        try outData.write(to: output)
    }

    static func gunzip(input: URL, output: URL, granularity: Int64, cb: ((Int64, Int64) -> Void)?) throws {
        let bytes = try Data(contentsOf: input)
        let emitter = ProgressEmitter(total: Int64(bytes.count), granularity: granularity, cb: cb)

        var inBuf = ByteBufferAllocator().buffer(capacity: bytes.count)
        inBuf.writeBytes(bytes)
        let decoder = GzipDecoder()
        var out = ByteBufferAllocator().buffer(capacity: bytes.count * 2)

        let chunk = 256 * 1024
        while inBuf.readableBytes > 0 {
            var part = inBuf.readSlice(length: min(chunk, inBuf.readableBytes))!
            try decoder.decode(data: part, out: &out)
            emitter.add(Int64(part.readableBytes))
        }
        emitter.finish()
        let outData = out.readData(length: out.readableBytes) ?? Data()
        try outData.write(to: output)
    }
}
#endif
