import 'factory.dart';

abstract class FactoryRepository {
  Future<List<Factory>> list({PartnerType? partnerType});
  Future<Factory> create(FactoryDraft draft);
  Future<Factory> update(int id, FactoryDraft draft);
  Future<void> deactivate(int id);
}
