with open(r'C:\careMate\android\app\src\main\AndroidManifest.xml', 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace('android:name=""', 'android:name=""', 1)
with open(r'C:\careMate\android\app\src\main\AndroidManifest.xml', 'w', encoding='utf-8') as f:
    f.write(content)
print('완료')
