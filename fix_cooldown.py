with open(r'C:\careMate\lib\services\beacon_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace('const int kCooldownMinutes = 5', 'const int kCooldownMinutes = 1')
with open(r'C:\careMate\lib\services\beacon_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('완료')
