import 'package:flutter_test/flutter_test.dart';
import 'package:albmap/core/constants/app_constants.dart';

void main() {
  group('AppConstants.isRemoteMediaPath', () {
    test('null/empty is never remote', () {
      expect(AppConstants.isRemoteMediaPath(null), isFalse);
      expect(AppConstants.isRemoteMediaPath(''), isFalse);
    });

    test('absolute http(s) URLs are remote', () {
      expect(AppConstants.isRemoteMediaPath('https://cdn.example.com/a.png'), isTrue);
      expect(AppConstants.isRemoteMediaPath('http://cdn.example.com/a.png'), isTrue);
    });

    test('server-relative /uploads/ paths are remote', () {
      expect(AppConstants.isRemoteMediaPath('/uploads/logo123.png'), isTrue);
    });

    // The bug class this guards against: a raw local file path (what
    // ImagePicker.pickImage returns before upload) getting fed to
    // Image.network instead of Image.file, which throws at runtime.
    test('a bare local file path is not remote', () {
      expect(AppConstants.isRemoteMediaPath('/data/user/0/com.example/cache/image_picker123.jpg'), isFalse);
      expect(AppConstants.isRemoteMediaPath('/private/var/mobile/tmp/img.jpg'), isFalse);
    });
  });

  group('AppConstants.resolveMediaUrl', () {
    test('null/empty passes through as null', () {
      expect(AppConstants.resolveMediaUrl(null), isNull);
      expect(AppConstants.resolveMediaUrl(''), isNull);
    });

    test('already-absolute URLs pass through unchanged', () {
      expect(
        AppConstants.resolveMediaUrl('https://cdn.example.com/a.png'),
        'https://cdn.example.com/a.png',
      );
    });

    test('a local (non-remote, non-/uploads/) path passes through unchanged', () {
      expect(
        AppConstants.resolveMediaUrl('/data/user/0/com.example/cache/img.jpg'),
        '/data/user/0/com.example/cache/img.jpg',
      );
    });

    test('a /uploads/ path is resolved against the API origin', () {
      final resolved = AppConstants.resolveMediaUrl('/uploads/logo123.png');
      expect(resolved, isNotNull);
      expect(resolved, endsWith('/uploads/logo123.png'));
      // The API base URL's "/v1" suffix must not leak into the media
      // origin — uploaded files are served from the server root.
      expect(resolved, isNot(contains('/v1/uploads')));
    });
  });
}
