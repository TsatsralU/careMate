with open(r'C:\careMate\lib\services\beacon_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace('const int kRssiImmediate   = -65', 'const int kRssiImmediate   = -50')
content = content.replace('const int kRssiNear        = -80', 'const int kRssiNear        = -65')
with open(r'C:\careMate\lib\services\beacon_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('완료')
