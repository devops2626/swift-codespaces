import Foundation
import Hummingbird
import Logging

@main
enum Entrypoint {
    static func main() async throws {
        let router = Router()
        router.get("/health", use: health)
        router.post("/analyze", use: analyze)

        let app = Application(
            router: router,
            configuration: .init(address: .hostname("0.0.0.0", port: 8080))
        )
        try await app.runService()
    }
}

struct HealthResponse: ResponseEncodable {
    let status: String
    let service: String
}

@Sendable
func health(_ request: Request, _ context: some RequestContext) async throws -> HealthResponse {
    HealthResponse(status: "ok", service: "swift-codespaces-image-api")
}

struct AnalysisResponse: ResponseEncodable {
    struct OCR: ResponseEncodable {
        let enabled: Bool
        let text: String?
        let error: String?
    }

    let width: Int?
    let height: Int?
    let format: String?
    let bytes: Int
    let ocr: OCR
}

@Sendable
func analyze(_ request: Request, _ context: some RequestContext) async throws -> AnalysisResponse {
    let maxBytes = 5 * 1024 * 1024
    let buffer = try await request.body.collect(upTo: maxBytes)
    let data = Data(buffer.readableBytesView)

    guard !data.isEmpty else {
        throw HTTPError(.badRequest, message: "Empty body. Send raw image bytes with Content-Type image/*.")
    }

    let contentType = request.headers[.contentType].map(String.init) ?? ""
    let isImage = contentType.hasPrefix("image/") || looksLikeImage(data)
    guard isImage else {
        throw HTTPError(
            .unsupportedMediaType,
            message: "Expected image body (Content-Type: image/png, image/jpeg, ...). Got: \(contentType.isEmpty ? "(none)" : contentType)"
        )
    }

    let wantOCR: Bool = {
        let query = request.uri.query ?? ""
        return query.split(separator: "&").contains { part in
            part == "ocr=true" || part.hasPrefix("ocr=true")
        }
    }()

    let info = try ImageTools.inspect(data: data)
    var ocrText: String? = nil
    var ocrError: String? = nil
    if wantOCR {
        do {
            ocrText = try ImageTools.ocr(data: data)
        } catch {
            ocrError = String(describing: error)
        }
    }

    return AnalysisResponse(
        width: info.width,
        height: info.height,
        format: info.format,
        bytes: data.count,
        ocr: .init(enabled: wantOCR, text: ocrText, error: ocrError)
    )
}

func looksLikeImage(_ data: Data) -> Bool {
    if data.count >= 8 {
        let png: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        if Array(data.prefix(8)) == png { return true }
    }
    if data.count >= 3 {
        let jpeg: [UInt8] = [0xFF, 0xD8, 0xFF]
        if Array(data.prefix(3)) == jpeg { return true }
    }
    if data.count >= 6 {
        let s = String(data: data.prefix(6), encoding: .ascii) ?? ""
        if s.hasPrefix("GIF87a") || s.hasPrefix("GIF89a") { return true }
    }
    if data.count >= 12 {
        let riff = String(data: data.prefix(4), encoding: .ascii)
        let webp = String(data: data.subdata(in: 8..<12), encoding: .ascii)
        if riff == "RIFF" && webp == "WEBP" { return true }
    }
    return false
}
