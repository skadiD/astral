import 'dart:io';
import 'package:objectbox/objectbox.dart';

@Entity()
class NewAppSetting {
  @Id(assignable: true)
  final int id;
  // 玩家名称
  final String playerName = Platform.localHostname;

  NewAppSetting({this.id = 1});
}

