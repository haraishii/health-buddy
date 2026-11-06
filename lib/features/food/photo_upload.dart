import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Readies a picked photo for the AI and the result screen:
/// - applies the EXIF rotation to the pixels. Many Android cameras save portrait photos sideways with a
///   "rotate" flag that the model ignores, which would put the callouts in the wrong place;
/// - drops all EXIF (GPS position, device serial), which neither the server nor Ollama needs;
/// - shrinks it to at most 1024 px and encodes it as JPEG.
///
/// Bytes it cannot decode are returned unchanged. Slow on big photos: run it with `compute`.
Uint8List preparePhotoForUpload(Uint8List bytes) {
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    return bytes;
  }
  if (decoded == null) return bytes;

  var out = img.bakeOrientation(decoded);
  if (math.max(out.width, out.height) > 1024) {
    out = out.width >= out.height ? img.copyResize(out, width: 1024) : img.copyResize(out, height: 1024);
  }
  out.exif = img.ExifData();
  return img.encodeJpg(out, quality: 85);
}
