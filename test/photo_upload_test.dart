import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_buddy/features/food/photo_upload.dart';
import 'package:image/image.dart' as img;

/// A 40×20 JPEG whose EXIF says "rotate 90° clockwise to view", as many Android cameras save portrait photos.
Uint8List _sidewaysJpeg() {
  final image = img.Image(width: 40, height: 20);
  image.exif.imageIfd.orientation = 6;
  image.exif.imageIfd['Model'] = img.IfdValueAscii('Test Phone');
  return img.encodeJpg(image);
}

void main() {
  test('bakes the EXIF rotation into the pixels and drops all EXIF', () {
    final out = img.decodeJpg(preparePhotoForUpload(_sidewaysJpeg()))!;
    expect(out.width, 20);
    expect(out.height, 40);
    expect(out.exif.imageIfd.hasOrientation, isFalse);
    expect(out.exif.imageIfd['Model'], isNull);
  });

  test('shrinks photos larger than 1024 px', () {
    final big = img.encodeJpg(img.Image(width: 2048, height: 1024));
    final out = img.decodeJpg(preparePhotoForUpload(big))!;
    expect(out.width, 1024);
    expect(out.height, 512);
  });

  test('returns bytes it cannot decode unchanged', () {
    final junk = Uint8List.fromList([1, 2, 3, 4]);
    expect(preparePhotoForUpload(junk), same(junk));
  });
}
