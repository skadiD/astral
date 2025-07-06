import 'package:astral/src/rust/api/astral_wfp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';

class WfpPage extends StatefulWidget {
  const WfpPage({super.key});

  @override
  State<WfpPage> createState() => _WfpPageState();
}

class _WfpPageState extends State<WfpPage> {
  // init
  @override
  Future<void> initState() async {
    super.initState();
    final wfpController = await WfpController.newInstance();

    final rules = FilterRule.newWithParams(
      name: "测试",
      direction: Direction.outbound,
      action: FilterAction.block,
    );
    await wfpController.addFilters(rules: [await rules]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WFP 规则配置')),
      body: Column(children: [
         
        ],
      ),
    );
  }
}
