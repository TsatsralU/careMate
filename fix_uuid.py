with open(r'C:\careMate\lib\services\beacon_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace('6CB03F73-0B99-2A9C-377F-0F4B40FF71EA', 'FDA50693-A4E2-4FB1-AFCF-C6EB07647825')
with open(r'C:\careMate\lib\services\beacon_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('완료')
