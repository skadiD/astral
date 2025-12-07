import 'package:isar_community/isar.dart';

part 'test_model.g.dart';

@collection
class TestModel {
  Id id = Isar.autoIncrement;
  
  String? name;
}