
import Foundation
#if canImport(zlib)
import zlib

final class GzipZlib {
    static func gzip(input: URL, output: URL, granularity: Int64, cb: ((Int64, Int64) -> Void)?) throws {
        let inData = try Data(contentsOf: input, options: .mappedIfSafe)
        let emitter = ProgressEmitter(total: Int64(inData.count), granularity: granularity, cb: cb)

        var stream = z_stream()
        let windowBits: Int32 = 15 + 16
        guard deflateInit2_(&stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, windowBits, 8, Z_DEFAULT_STRATEGY, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size)) == Z_OK
        else { throw TarError.ioFailed("deflateInit2 failed") }
        defer { deflateEnd(&stream) }

        var outData = Data()
        let chunk = 64 * 1024
        var snapshot: Int64 = 0

        try inData.withUnsafeBytes { (srcPtr: UnsafeRawBufferPointer) in
            stream.next_in = UnsafeMutablePointer<Bytef>(mutating: srcPtr.bindMemory(to: Bytef.self).baseAddress!)
            stream.avail_in = uInt(srcPtr.count)

            let outBuf = UnsafeMutablePointer<Bytef>.allocate(capacity: chunk)
            defer { outBuf.deallocate() }

            repeat {
                stream.next_out = outBuf
                stream.avail_out = uInt(chunk)
                let ret = deflate(&stream, stream.avail_in > 0 ? Z_NO_FLUSH : Z_FINISH)
                if ret == Z_STREAM_ERROR { throw TarError.ioFailed("deflate error") }
                let have = chunk - Int(stream.avail_out)
                if have > 0 { outData.append(outBuf, count: have) }
                let now = Int64(stream.total_in)
                emitter.add(now - snapshot)
                snapshot = now
            } while stream.avail_out == 0
        }
        emitter.finish()
        try outData.write(to: output)
    }

    static func gunzip(input: URL, output: URL, granularity: Int64, cb: ((Int64, Int64) -> Void)?) throws {
        let inData = try Data(contentsOf: input, options: .mappedIfSafe)
        let emitter = ProgressEmitter(total: Int64(inData.count), granularity: granularity, cb: cb)

        var stream = z_stream()
        let windowBits: Int32 = 15 + 16
        guard inflateInit2_(&stream, windowBits, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size)) == Z_OK
        else { throw TarError.ioFailed("inflateInit2 failed") }
        defer { inflateEnd(&stream) }

        var outData = Data(capacity: inData.count * 2)
        let chunk = 64 * 1024
        var snapshot: Int64 = 0

        try inData.withUnsafeBytes { (srcPtr: UnsafeRawBufferPointer) in
            stream.next_in = UnsafeMutablePointer<Bytef>(mutating: srcPtr.bindMemory(to: Bytef.self).baseAddress!)
            stream.avail_in = uInt(srcPtr.count)

            let outBuf = UnsafeMutablePointer<Bytef>.allocate(capacity: chunk)
            defer { outBuf.deallocate() }

            var ret: Int32
            repeat {
                stream.next_out = outBuf
                stream.avail_out = uInt(chunk)
                ret = inflate(&stream, Z_NO_FLUSH)
                if ret == Z_STREAM_ERROR || ret == Z_DATA_ERROR || ret == Z_MEM_ERROR {
                    throw TarError.ioFailed("inflate error \(ret)")
                }
                let have = chunk - Int(stream.avail_out)
                if have > 0 { outData.append(outBuf, count: have) }
                let now = Int64(stream.total_in)
                emitter.add(now - snapshot)
                snapshot = now
            } while ret != Z_STREAM_END
        }
        emitter.finish()
        try outData.write(to: output)
    }
}
#endif
