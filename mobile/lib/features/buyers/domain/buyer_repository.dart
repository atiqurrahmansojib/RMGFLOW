import 'buyer.dart';

/// Document 12.2: domain contract; BuyerRepositoryImpl (data/) implements it
/// against the real API. Keeps BuyerListController/BuyerFormController free
/// of Dio/HTTP details.
abstract class BuyerRepository {
  Future<List<Buyer>> list({String? search, int page = 0, int size = 100});
  Future<Buyer> get(int id);
  Future<Buyer> create(BuyerDraft draft);
  Future<Buyer> update(int id, BuyerDraft draft);
  Future<void> deactivate(int id);
}
