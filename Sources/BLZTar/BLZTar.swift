
import Foundation

public final class BLZTar {

    public static func archive(directory: URL, to outURL: URL, options: BLZTarArchiveOptions = .init()) throws {
        let fm = FileManager.default
        let plan = try planArchive(from: directory, excludes: options.excludes)
        let totalTarBytes = computeTotalBytesForArchive(plan)
        let tarURL = options.gzip ? outURL.deletingPathExtension().appendingPathExtension("tar") : outURL

        fm.createFile(atPath: tarURL.path, contents: nil, attributes: nil)
        guard let outHandle = try? FileHandle(forWritingTo: tarURL) else { throw TarError.ioFailed("Cannot open output file") }
        defer { try? outHandle.close() }

        let emitter = ProgressEmitter(total: totalTarBytes, granularity: options.reportGranularityBytes, cb: options.onProgressBytes)

        for entry in plan {
            let fullURL = directory.appendingPathComponent(entry.path)
            let perms = try modeOf(fullURL)
            let mtime = try mtimeOf(fullURL)

            if entry.needsPAX {
                let paxData = buildPAX(path: entry.path)
                let paxHeader = TarHeader(path: paxHeaderName(for: entry.path),
                                          fileSize: Int64(paxData.count),
                                          typeflag: .paxExtended,
                                          permissions: 0o644,
                                          mtime: mtime)
                let h = try paxHeader.encode()
                outHandle.write(h); emitter.add(Int64(h.count))
                outHandle.write(paxData); emitter.add(Int64(paxData.count))
                let pad = (512 - (paxData.count % 512)) % 512
                if pad > 0 { let z = Data(repeating: 0, count: pad); outHandle.write(z); emitter.add(Int64(pad)) }
            }

            if entry.isDir {
                let dirHeader = TarHeader(path: ustarCompatibleName(entry.path),
                                          fileSize: 0,
                                          typeflag: .directory,
                                          permissions: perms,
                                          mtime: mtime)
                let h = try dirHeader.encode()
                outHandle.write(h); emitter.add(Int64(h.count))
            } else {
                let fileHeader = TarHeader(path: ustarCompatibleName(entry.path),
                                           fileSize: entry.size,
                                           typeflag: .regular,
                                           permissions: perms,
                                           mtime: mtime)
                let h = try fileHeader.encode()
                outHandle.write(h); emitter.add(Int64(h.count))

                guard let inH = try? FileHandle(forReadingFrom: fullURL) else { throw TarError.ioFailed("Cannot open \(fullURL.path)") }
                defer { try? inH.close() }

                var perFileDone: Int64 = 0
                let buf = 256 * 1024
                while let chunk = try? inH.read(upToCount: buf), let chunk, !chunk.isEmpty {
                    outHandle.write(chunk)
                    let c = Int64(chunk.count)
                    emitter.add(c)
                    perFileDone += c
                    options.onProgressPerFile?(fullURL, perFileDone, entry.size)
                }
                let pad = (512 - (Int(entry.size) % 512)) % 512
                if pad > 0 { let z = Data(repeating: 0, count: pad); outHandle.write(z); emitter.add(Int64(pad)) }
            }
        }

        let eof = Data(repeating: 0, count: 1024)
        outHandle.write(eof); emitter.add(1024)
        emitter.finish()

        if options.gzip {
            switch options.gzipEngine {
            case .zlib:
                #if canImport(zlib)
                try GzipZlib.gzip(input: tarURL, output: outURL, granularity: options.reportGranularityBytes, cb: options.onProgressBytes)
                #else
                throw TarError.gzipUnsupportedEngine
                #endif
            case .nioExtras:
                #if canImport(NIOCore) && canImport(NIOExtras)
                try GzipNIOExtras.gzip(input: tarURL, output: outURL, granularity: options.reportGranularityBytes, cb: options.onProgressBytes)
                #else
                throw TarError.gzipUnsupportedEngine
                #endif
            }
            try? fm.removeItem(at: tarURL)
        }
    }

    public static func extract(archive: URL, toDirectory outDir: URL, options: BLZTarExtractOptions = .init()) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: outDir, withIntermediateDirectories: true)

        let isGz = archive.path.lowercased().hasSuffix(".tgz") || archive.path.lowercased().hasSuffix(".tar.gz")
        let tarURL: URL
        if isGz {
            tarURL = outDir.appendingPathComponent(".blz_temp_\(UUID().uuidString).tar")
            switch options.gzipEngine {
            case .zlib:
                #if canImport(zlib)
                try GzipZlib.gunzip(input: archive, output: tarURL, granularity: options.reportGranularityBytes, cb: options.onProgressBytes)
                #else
                throw TarError.gzipUnsupportedEngine
                #endif
            case .nioExtras:
                #if canImport(NIOCore) && canImport(NIOExtras)
                try GzipNIOExtras.gunzip(input: archive, output: tarURL, granularity: options.reportGranularityBytes, cb: options.onProgressBytes)
                #else
                throw TarError.gzipUnsupportedEngine
                #endif
            }
        } else {
            tarURL = archive
        }
        defer { if isGz { try? fm.removeItem(at: tarURL) } }

        let total = try computeTotalBytesForExtraction(tarURL: tarURL)
        let emitter = ProgressEmitter(total: total, granularity: options.reportGranularityBytes, cb: options.onProgressBytes)

        guard let inHandle = try? FileHandle(forReadingFrom: tarURL) else { throw TarError.ioFailed("Cannot open archive") }
        defer { try? inHandle.close() }

        var pendingPAX: PAXRecord? = nil

        while true {
            guard let headerData = try? inHandle.read(upToCount: 512), let headerData else { break }
            if headerData.count == 0 { break }
            emitter.add(512)

            if headerData == Data(repeating: 0, count: 512) {
                if let z = try? inHandle.read(upToCount: 512), let z, z.count == 512 { emitter.add(512) }
                break
            }

            guard let header = try? TarHeader.decode(from: headerData) else { throw TarError.invalidHeader }

            switch header.typeflag {
            case .paxExtended:
                let size = Int(header.fileSize)
                let body = try readExact(handle: inHandle, size: size)
                emitter.add(Int64(size))
                let pad = (512 - (size % 512)) % 512
                if pad > 0 { _ = try? inHandle.read(upToCount: pad); emitter.add(Int64(pad)) }
                pendingPAX = try parsePAX(body)

            case .directory, .regular:
                let finalPath = pendingPAX?.path ?? header.path
                pendingPAX = nil

                let safePath = try secureJoin(base: outDir, relative: finalPath)
                options.onEntry?(finalPath)

                if header.typeflag == .directory {
                    try fm.createDirectory(at: safePath, withIntermediateDirectories: true)
                    if options.preservePermissions { try setMode(safePath, mode: header.permissions) }
                } else {
                    try fm.createDirectory(at: safePath.deletingLastPathComponent(), withIntermediateDirectories: true)
                    if fm.fileExists(atPath: safePath.path), options.overwrite == false {
                        let size = Int(header.fileSize)
                        if size > 0 { _ = try inHandle.read(upToCount: size); emitter.add(Int64(size)) }
                        let pad = (512 - (size % 512)) % 512
                        if pad > 0 { _ = try? inHandle.read(upToCount: pad); emitter.add(Int64(pad)) }
                    } else {
                        fm.createFile(atPath: safePath.path, contents: nil, attributes: nil)
                        guard let out = try? FileHandle(forWritingTo: safePath) else { throw TarError.ioFailed("Cannot create \(safePath.path)") }
                        defer { try? out.close() }

                        var remaining = header.fileSize
                        let buf = 256 * 1024
                        while remaining > 0 {
                            let toRead = Int(min(Int64(buf), remaining))
                            let chunk = try readExact(handle: inHandle, size: toRead)
                            out.write(chunk)
                            remaining -= Int64(chunk.count)
                            emitter.add(Int64(chunk.count))
                        }
                        let pad = (512 - (Int(header.fileSize) % 512)) % 512
                        if pad > 0 { _ = try? inHandle.read(upToCount: pad); emitter.add(Int64(pad)) }

                        if options.preservePermissions { try setMode(safePath, mode: header.permissions) }
                        try setMtime(safePath, mtime: header.mtime)
                    }
                }

            default:
                let size = Int(header.fileSize)
                if size > 0 { _ = try inHandle.read(upToCount: size); emitter.add(Int64(size)) }
                let pad = (512 - (size % 512)) % 512
                if pad > 0 { _ = try? inHandle.read(upToCount: pad); emitter.add(Int64(pad)) }
            }
        }
        emitter.finish()
    }
}

func readExact(handle: FileHandle, size: Int) throws -> Data {
    var remaining = size
    var out = Data()
    while remaining > 0 {
        guard let chunk = try? handle.read(upToCount: remaining), let chunk, !chunk.isEmpty else {
            throw TarError.ioFailed("Unexpected EOF")
        }
        out.append(chunk)
        remaining -= chunk.count
    }
    return out
}
