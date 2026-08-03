import Foundation

enum ImageToolsError: Error, CustomStringConvertible {
    case commandFailed(String)
    case parseFailed(String)

    var description: String {
        switch self {
        case .commandFailed(let message): return message
        case .parseFailed(let message): return message
        }
    }
}

enum ImageTools {
    struct Info {
        let width: Int?
        let height: Int?
        let format: String?
    }

    /// Inspect image with `vipsheader` (from libvips-tools).
    static func inspect(data: Data) throws -> Info {
        let dir = FileManager.default.temporaryDirectory
        let input = dir.appendingPathComponent("inspect-\(UUID().uuidString)")
        try data.write(to: input)
        defer { try? FileManager.default.removeItem(at: input) }

        // vipsheader prints lines like:
        // width: 640
        // height: 480
        // format: uchar
        // bands: 3
        // interpretation: srgb
        // filename: ...
        let output = try run("/usr/bin/vipsheader", arguments: ["-a", input.path])
        var width: Int?
        var height: Int?
        var format: String?

        for line in output.split(separator: "\n") {
            let parts = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else { continue }
            switch parts[0] {
            case "width": width = Int(parts[1])
            case "height": height = Int(parts[1])
            case "loader", "vips-loader":
                // e.g. jpegload, pngload
                format = parts[1].replacingOccurrences(of: "load", with: "")
            default:
                break
            }
        }

        // Fallback: infer format from magic bytes if loader not present
        if format == nil {
            if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) { format = "png" }
            else if data.starts(with: [0xFF, 0xD8, 0xFF]) { format = "jpeg" }
            else if String(data: data.prefix(6), encoding: .ascii)?.hasPrefix("GIF") == true { format = "gif" }
            else if data.count >= 12,
                    String(data: data.prefix(4), encoding: .ascii) == "RIFF",
                    String(data: data.subdata(in: 8..<12), encoding: .ascii) == "WEBP" {
                format = "webp"
            }
        }

        return Info(width: width, height: height, format: format)
    }

    /// OCR with system `tesseract` CLI (eng).
    static func ocr(data: Data) throws -> String {
        let dir = FileManager.default.temporaryDirectory
        let input = dir.appendingPathComponent("ocr-\(UUID().uuidString).img")
        let base = dir.appendingPathComponent("ocr-out-\(UUID().uuidString)")
        let outputTxt = base.appendingPathExtension("txt")

        try data.write(to: input)
        defer {
            try? FileManager.default.removeItem(at: input)
            try? FileManager.default.removeItem(at: outputTxt)
        }

        // tesseract input outputbase -l eng
        _ = try run("/usr/bin/tesseract", arguments: [input.path, base.path, "-l", "eng"])
        let text = (try? String(contentsOf: outputTxt, encoding: .utf8)) ?? ""
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @discardableResult
    private static func run(_ executable: String, arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        let outData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errData = stderr.fileHandleForReading.readDataToEndOfFile()
        let out = String(data: outData, encoding: .utf8) ?? ""
        let err = String(data: errData, encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw ImageToolsError.commandFailed(
                "\(executable) failed (\(process.terminationStatus)): \(err.isEmpty ? out : err)"
            )
        }
        return out.isEmpty ? err : out
    }
}
