import 'package:astral/src/rust/api/astral_wfp.dart';
import 'package:isar/isar.dart';

// WfpModel
@collection
class WfpModel {
  /// 主键自增
  Id id = Isar.autoIncrement;

  /// 规则名称
  @Index()
  String name = '';

  /// 应用程序路径
  String? appPath;

  /// 本地地址
  String? local;

  /// 远程地址
  String? remote;

  /// 本地端口
  int? localPort;

  /// 远程端口
  int? remotePort;

  /// 本地端口范围
  @Index()
  List<int>? localPortRange;

  /// 远程端口范围
  @Index()
  List<int>? remotePortRange;

  /// 协议类型
  @enumerated
  Protocol? protocol;

  /// 方向
  @enumerated
  Direction direction = Direction.both;

  /// 过滤动作
  @enumerated
  FilterAction action = FilterAction.block;

  /// 优先级
  int? priority;

  /// 描述
  String? description;
}
