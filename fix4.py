with open(r'C:\careMate\android\app\src\main\AndroidManifest.xml', 'r', encoding='utf-8') as f:
    lines = f.readlines()
lines = [l for l in lines if 'android:name="io.flutter.app.FlutterApplication"' not in l]
with open(r'C:\careMate\android\app\src\main\AndroidManifest.xml', 'w', encoding='utf-8') as f:
    f.writelines(lines)
print('완료')
