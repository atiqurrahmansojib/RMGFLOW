import 'style.dart';

abstract class StyleRepository {
  Future<List<Style>> list({String? search});
  Future<Style> create(StyleDraft draft);
}
