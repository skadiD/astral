import 'dart:convert';
import 'package:astral/k/models/room.dart';
import 'dart:io';

// 简单加密密钥
const String encryptionSecret = '这就是密钥';

/// 游程编码（RLE）- 压缩连续重复的字符
/// 例如：00000000 -> z8（z表示0，8表示个数）
String _rleEncode(String input) {
  if (input.isEmpty) return '';

  StringBuffer result = StringBuffer();
  int count = 1;
  String lastChar = input[0];

  for (int i = 1; i < input.length; i++) {
    if (input[i] == lastChar && count < 36) {
      // 36是base36的最大单个字符表示（0-9, a-z）
      count++;
    } else {
      // 输出前一个字符的运行长度
      if (count == 1) {
        result.write(lastChar);
      } else if (count == 2) {
        result.write(lastChar);
        result.write(lastChar);
      } else {
        // 用!+base36数字表示重复次数
        result.write(lastChar);
        result.write('!');
        result.write(count.toRadixString(36));
      }
      lastChar = input[i];
      count = 1;
    }
  }

  // 处理最后一个字符
  if (count == 1) {
    result.write(lastChar);
  } else if (count == 2) {
    result.write(lastChar);
    result.write(lastChar);
  } else {
    result.write(lastChar);
    result.write('!');
    result.write(count.toRadixString(36));
  }

  return result.toString();
}

/// 游程解码
String _rleDecode(String input) {
  if (input.isEmpty) return '';

  StringBuffer result = StringBuffer();
  int i = 0;

  while (i < input.length) {
    String char = input[i];
    i++;

    // 检查是否有重复计数
    if (i < input.length && input[i] == '!') {
      i++; // 跳过'!'
      int count = 0;
      // 读取base36数字
      while (i < input.length && input[i] != '!' && _isBase36Char(input[i])) {
        count = count * 36 + int.parse(input[i], radix: 36);
        i++;
      }
      // 重复该字符
      result.write(char * count);
    } else {
      result.write(char);
    }
  }

  return result.toString();
}

/// 检查是否是base36字符
bool _isBase36Char(String char) {
  return (char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57) || // 0-9
      (char.codeUnitAt(0) >= 97 && char.codeUnitAt(0) <= 122); // a-z
}

/// 生成 CRC32 校验和作为签名（4字节，更紧凑）
String _generateChecksum(String data) {
  // 简单的校验算法：计算数据的哈希值并转换为base32
  int hash = 0;
  for (int i = 0; i < data.length; i++) {
    hash = ((hash << 5) - hash) + data.codeUnitAt(i);
    hash = hash & hash; // 保证32位整数
  }
  // 转换为4字符的base32编码
  return hash.toRadixString(36).padLeft(4, '0').substring(0, 4);
}

/// 验证校验和
bool _verifyChecksum(String data, String checksum) {
  return _generateChecksum(data) == checksum;
}

/// Base32 编码（更紧凑，无填充字符）
/// 使用Crockford Base32（0-9a-v，移除了易混淆的字符）
String _base32Encode(List<int> bytes) {
  const String alphabet = '0123456789abcdefghijklmnopqrstuvwxyz';
  StringBuffer result = StringBuffer();
  int bits = 0;
  int value = 0;

  for (int i = 0; i < bytes.length; i++) {
    value = (value << 8) | bytes[i];
    bits += 8;
    while (bits >= 5) {
      bits -= 5;
      result.write(alphabet[(value >> bits) & 31]);
    }
  }

  if (bits > 0) {
    result.write(alphabet[(value << (5 - bits)) & 31]);
  }

  return result.toString();
}

/// Base32 解码
List<int> _base32Decode(String encoded) {
  const String alphabet = '0123456789abcdefghijklmnopqrstuvwxyz';
  List<int> result = [];
  int bits = 0;
  int value = 0;

  for (int i = 0; i < encoded.length; i++) {
    int charIndex = alphabet.indexOf(encoded[i].toLowerCase());
    if (charIndex == -1)
      throw ArgumentError('Invalid character in base32 string');

    value = (value << 5) | charIndex;
    bits += 5;

    if (bits >= 8) {
      bits -= 8;
      result.add((value >> bits) & 0xFF);
    }
  }

  return result;
}

/// URL-safe Base64 编码
/// 将标准 Base64 转换为 URL-safe 版本，减少特殊字符
String _base64UrlEncode(List<int> bytes) {
  String encoded = base64Encode(bytes);
  // 替换特殊字符：+ -> -, / -> _，移除末尾的 =
  return encoded.replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
}

/// URL-safe Base64 解码
/// 将 URL-safe Base64 恢复为标准格式并解码
List<int> _base64UrlDecode(String encoded) {
  // 恢复原始 Base64 格式
  String restored = encoded.replaceAll('-', '+').replaceAll('_', '/');

  // 添加缺失的填充字符
  while (restored.length % 4 != 0) {
    restored += '=';
  }

  return base64Decode(restored);
}

/// 将房间对象加密为分享码（RLE 超压缩版）
///
/// 接收一个 [Room] 对象，返回加密分享码
/// 优化策略：
/// 1. 二进制格式（无JSON键名）
/// 2. Base32编码（比Base64短15%）
/// 3. 游程编码RLE（压缩连续重复字符，特别对0有效）
/// 4. 4字符校验和
String encryptRoomWithJWT(Room room) {
  try {
    if (room.name.isEmpty) {
      throw ArgumentError('房间名称不能为空');
    }

    // 使用二进制格式
    final BytesBuilder bb = BytesBuilder();

    // 版本号（1字节）
    bb.addByte(0x01);

    // 加密标志（1字节）
    bb.addByte(room.encrypted ? 1 : 0);

    // 字符串编码：长度(1字节) + 内容
    void _addString(String str) {
      final bytes = utf8.encode(str);
      if (bytes.length > 255) {
        throw ArgumentError('字符串过长，不能超过255字节');
      }
      bb.addByte(bytes.length);
      bb.add(bytes);
    }

    _addString(room.name);
    _addString(room.roomName);
    _addString(room.password);
    _addString(room.messageKey);

    // 获取二进制数据
    List<int> binaryData = bb.toBytes();

    // 压缩数据
    final List<int> compressedData = gzip.encode(binaryData);

    // Base32 编码
    String encoded = _base32Encode(compressedData);

    // 应用游程编码进一步压缩（特别对gzip输出的0有效）
    String compressed = _rleEncode(encoded);

    // 生成4字符校验和
    final String checksum = _generateChecksum(compressed);

    // 返回格式：校验和.RLE压缩数据
    return '$checksum.$compressed';
  } catch (e) {
    throw Exception('房间加密失败: $e');
  }
}

/// 将分享码解密为房间对象（RLE 超压缩版）
///
/// 接收一个分享码字符串，返回解密后的 [Room] 对象
Room? decryptRoomFromJWT(String token) {
  try {
    if (token.isEmpty) {
      throw ArgumentError('分享码不能为空');
    }

    // 分离校验和和数据
    final parts = token.split('.');
    if (parts.length != 2) {
      throw Exception('分享码格式错误');
    }

    final String checksum = parts[0];
    final String compressed = parts[1];

    // 验证校验和
    if (!_verifyChecksum(compressed, checksum)) {
      throw Exception('分享码已损坏或被修改');
    }

    // RLE 解码
    final String encoded = _rleDecode(compressed);

    // Base32 解码
    final List<int> compressedData = _base32Decode(encoded);

    // Gzip 解压
    final List<int> binaryData = gzip.decode(compressedData);

    // 解析二进制格式
    int offset = 0;

    // 读取版本号
    final int version = binaryData[offset++];
    if (version != 0x01) {
      throw Exception('不支持的版本号: $version');
    }

    // 读取加密标志
    final int encryptedByte = binaryData[offset++];
    final bool encrypted = encryptedByte == 1;

    // 读取字符串
    String _readString() {
      final int length = binaryData[offset++];
      final String str = utf8.decode(
        binaryData.sublist(offset, offset + length),
      );
      offset += length;
      return str;
    }

    final String name = _readString();
    final String roomName = _readString();
    final String password = _readString();
    final String messageKey = _readString();

    // 从解析的数据创建Room对象
    return Room(
      name: name,
      encrypted: encrypted,
      roomName: roomName,
      password: password,
      tags: [],
      messageKey: messageKey,
    );
  } catch (e) {
    print('解密房间信息失败: $e');
    return null;
  }
}

/// 将房间对象加密为密文（简化版，不使用JWT）
///
/// 接收一个 [Room] 对象，返回加密后的密文字符串
/// 加密过程：将 Room 对象转换为 JSON，压缩，使用 URL-safe Base64 编码
String encryptRoom(Room room) {
  // 创建精简的 Map，使用缩写键名和数字编码
  final Map<String, dynamic> roomMap = {
    'n': room.name,
    'e': room.encrypted ? 1 : 0, // 0=false, 1=true
    'rn': room.roomName,
    'p': room.password,
    'mk': room.messageKey,
  };

  // 将 Map 转换为 JSON 字符串
  final String jsonString = jsonEncode(roomMap);

  // 压缩JSON数据
  final List<int> compressedData = gzip.encode(utf8.encode(jsonString));

  // 使用 URL-safe Base64 编码
  final String encryptedString = _base64UrlEncode(compressedData);

  return encryptedString;
}

/// 将密文解密为房间对象（简化版）
///
/// 接收一个加密的密文字符串，返回解密后的 [Room] 对象
/// 解密过程：使用 URL-safe Base64 解码、解压，然后转换为 Room 对象
Room? decryptRoom(String encryptedString) {
  try {
    // 使用 URL-safe Base64 解码
    final List<int> compressedData = _base64UrlDecode(encryptedString);

    // 解压数据
    final List<int> decompressedData = gzip.decode(compressedData);
    final String jsonString = utf8.decode(decompressedData);

    // 将 JSON 字符串转换为 Map
    final Map<String, dynamic> roomMap = jsonDecode(jsonString);

    // 从 Map 创建 Room 对象
    return Room(
      name: roomMap['n'] ?? '',
      encrypted: (roomMap['e'] as int?) == 1 ? true : false, // 0=false, 1=true
      roomName: roomMap['rn'] ?? '',
      password: roomMap['p'] ?? '',
      tags: [], // tags 已移除
      messageKey: roomMap['mk'] ?? '',
    );
  } catch (e) {
    // 解密失败时返回null
    print('解密房间信息失败: $e');
    return null;
  }
}

/// 验证房间对象的有效性
///
/// 检查房间对象的各个字段是否符合要求
/// 返回验证结果和错误信息
(bool isValid, String? errorMessage) validateRoom(Room? room) {
  if (room == null) {
    return (false, '房间对象为空');
  }

  // 验证房间名称
  if (room.name.isEmpty || room.name.trim().isEmpty) {
    return (false, '房间名称不能为空');
  }

  if (room.name.length > 50) {
    return (false, '房间名称过长，不能超过50个字符');
  }

  // 验证房间名称字符
  if (room.name.contains(RegExp(r'[<>:"/\\|?*]'))) {
    return (false, '房间名称包含非法字符');
  }

  // 对于非加密房间，验证房间号和密码
  if (!room.encrypted) {
    if (room.roomName.isEmpty) {
      return (false, '公开房间必须有房间号');
    }

    if (room.roomName.length > 100) {
      return (false, '房间号过长，不能超过100个字符');
    }

    if (room.password.length > 100) {
      return (false, '房间密码过长，不能超过100个字符');
    }
  }

  // 验证标签
  if (room.tags.length > 10) {
    return (false, '标签数量不能超过10个');
  }

  for (String tag in room.tags) {
    if (tag.length > 20) {
      return (false, '标签长度不能超过20个字符');
    }
    if (tag.contains(RegExp(r'[<>:"/\\|?*]'))) {
      return (false, '标签包含非法字符');
    }
  }

  return (true, null);
}

/// 清理房间对象数据
///
/// 去除多余的空白字符，标准化数据格式
Room cleanRoom(Room room) {
  return Room(
    id: room.id,
    name: room.name.trim(),
    encrypted: room.encrypted,
    roomName: room.roomName.trim(),
    password: room.password.trim(),
    messageKey: room.messageKey.trim(),
    tags:
        room.tags
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(),
    sortOrder: room.sortOrder,
  );
}

/// 生成房间摘要信息
///
/// 用于分享时显示房间的基本信息
String generateRoomSummary(Room room) {
  final type = room.encrypted ? '🔒 加密房间' : '🔓 公开房间';
  final tags = room.tags.isNotEmpty ? '\n🏷️ ${room.tags.join(', ')}' : '';

  return '''
🏠 房间：${room.name}
$type$tags
'''.trim();
}

/// 检查分享码格式
///
/// 验证分享码是否符合预期格式（校验和.数据 格式）
bool isValidShareCode(String shareCode) {
  if (shareCode.isEmpty) return false;

  // 格式验证：应该包含两个部分，用点分隔
  final parts = shareCode.split('.');
  if (parts.length != 2) return false;

  // 检查校验和部分（应该是4个字符）
  final checksum = parts[0];
  if (checksum.length != 4) return false;

  // 检查数据部分是否为有效的Base32字符串
  try {
    final encodedString = parts[1];
    _base32Decode(encodedString);
    return true;
  } catch (e) {
    return false;
  }
}
