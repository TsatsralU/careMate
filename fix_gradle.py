s = open(r"C:/careMate/android/settings.gradle.kts").read()
s = s.replace("1.9.22", "2.1.0")
open(r"C:/careMate/android/settings.gradle.kts", "w").write(s)

content = open(r"C:/careMate/android/app/build.gradle.kts").read()
if "isCoreLibraryDesugaringEnabled" not in content:
    content = content.replace("compileOptions {", "compileOptions {\n        isCoreLibraryDesugaringEnabled = true")
    if "dependencies {" not in content:
        content += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")\n}'
    open(r"C:/careMate/android/app/build.gradle.kts", "w").write(content)

print("완료")
