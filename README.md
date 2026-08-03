# Swift on GitHub Codespaces — Image Analysis API (Phase 1)

Linux-native **image inspection + optional OCR** API using:

- [Hummingbird](https://github.com/hummingbird-project/hummingbird) (HTTP)
- **libvips** (`vipsheader`) for width/height/format
- **Tesseract** CLI for OCR

Runs in GitHub Codespaces. **Not** Apple Vision / Core ML (those require macOS/iOS).

## Quick start

1. Open this repo on GitHub
2. **Code → Codespaces → Create codespace on main**
3. Wait for `postCreateCommand` (installs `libvips-tools`, `tesseract-ocr`)
4. In the terminal:

```bash
bash Scripts/make-sample.sh   # tiny PNG
swift run App
```

5. In a second terminal (or after forwarding port **8080**):

```bash
curl -s http://127.0.0.1:8080/health
curl -s -H "Content-Type: image/png" --data-binary @Samples/sample.png http://127.0.0.1:8080/analyze
curl -s -H "Content-Type: image/png" --data-binary @Samples/sample.png "http://127.0.0.1:8080/analyze?ocr=true"
```

Or run the smoke script while the server is up:

```bash
bash Scripts/smoke-test.sh
```

## API

### `GET /health`

```json
{ "status": "ok", "service": "swift-codespaces-image-api" }
```

### `POST /analyze`

Send **raw image bytes** with an image `Content-Type`.

| Query | Effect |
|-------|--------|
| (none) | Metadata only |
| `?ocr=true` | Also run English OCR via Tesseract |

**Limits:** body max **5 MiB**.

Example response:

```json
{
  "width": 1,
  "height": 1,
  "format": "png",
  "bytes": 68,
  "ocr": { "enabled": false, "text": null, "error": null }
}
```

## What this is / is not

| This repo (Linux / Codespaces) | On a Mac |
|--------------------------------|----------|
| libvips metadata | Vision framework |
| Tesseract OCR | `VNRecognizeTextRequest` |
| Hummingbird HTTP API | Core ML models |

Use this Codespace to learn **server-side Swift** and image pipelines. Use a Mac for Apple Vision / Core ML demos.

## Project layout

```
.devcontainer/     Codespace config (Swift image + vips/tesseract)
Sources/App/       Hummingbird server
Scripts/           smoke test + sample generator
Samples/           test images
```

## Notes

- Free GitHub accounts include limited Codespaces hours — stop the codespace when idle.
- OCR quality depends on image clarity; a 1×1 PNG will return empty text.
- Multipart `multipart/form-data` uploads are a natural Phase 2 enhancement; Phase 1 uses raw bodies for reliability.
