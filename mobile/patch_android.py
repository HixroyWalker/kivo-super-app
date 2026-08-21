import os
import re

# 1. Clean AndroidManifest package attribute for AGP 8 and inject AdMob app ID
manifest_path = "android/app/src/main/AndroidManifest.xml"
if os.path.exists(manifest_path):
    with open(manifest_path, "r") as f:
        content = f.read()
    content = content.replace('package="com.kivo.app"', '')
    perms = """
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
"""
    if '<uses-permission android:name="android.permission.CAMERA"' not in content:
        content = content.replace('<manifest', '<manifest\n' + perms)
    if 'com.google.android.gms.ads.APPLICATION_ID' not in content:
        admob_meta = '<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="ca-app-pub-3940256099942544~3347511713"/>'
        content = content.replace('</application>', f'    {admob_meta}\n    </application>')
    with open(manifest_path, "w") as f:
        f.write(content)

# 2. Set compileSdk 36, targetSdkVersion 34, and configure release signing in android/app/build.gradle
app_gradle = "android/app/build.gradle"
if os.path.exists(app_gradle):
    with open(app_gradle, "r") as f:
        content = f.read()
        
    signing_preamble = """
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
"""
    if 'keystoreProperties' not in content:
        content = signing_preamble + "\n" + content
        
    content = re.sub(r'compileSdk\s*=.*', 'compileSdk = 34', content)
    content = re.sub(r'compileSdkVersion\s+.*', 'compileSdkVersion 34', content)
    content = re.sub(r'targetSdkVersion\s+.*', 'targetSdkVersion 34', content)
    
    signing_config_block = """
        release {
            if (keystorePropertiesFile.exists()) {
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
                storePassword keystoreProperties['storePassword']
            }
        }
"""
    if 'signingConfigs {' in content and 'signingConfigs.release' not in content:
        content = content.replace('signingConfigs {', 'signingConfigs {\n' + signing_config_block)
        
    if 'buildTypes {' in content and 'signingConfig = signingConfigs.release' not in content:
        content = re.sub(r'signingConfig\s*=\s*signingConfigs\.debug', 'signingConfig = (keystorePropertiesFile.exists() ? signingConfigs.release : signingConfigs.debug)', content)
        
    with open(app_gradle, "w") as f:
        f.write(content)

# 3. Append subprojects resolutionStrategy & compileSdk 34 to root android/build.gradle
root_gradle = "android/build.gradle"
if os.path.exists(root_gradle):
    with open(root_gradle, "r") as f:
        root_content = f.read()
    subproject_code = """
subprojects {
    afterEvaluate { project ->
        if (project.hasProperty('android')) {
            project.android {
                compileSdkVersion 34
            }
        }
    }
}
"""
    if "subprojects {" not in root_content:
        with open(root_gradle, "a") as f:
            f.write("\n" + subproject_code + "\n")

# 4. Dynamically patch all pub-cache plugin build.gradle files to compileSdk 34 and Gradle 9 compatibility
cache_dirs = [
    os.path.expanduser("~/.pub-cache"),
    os.environ.get("PUB_CACHE", ""),
    "/home/runner/.pub-cache",
    "/opt/hostedtoolcache",
    "/Users/runner/.pub-cache",
]
for cd in cache_dirs:
    if cd and os.path.exists(cd):
        for root_dir, dirs, files in os.walk(cd):
            for f_name in files:
                if f_name.endswith(".gradle") or f_name.endswith(".gradle.kts"):
                    p = os.path.join(root_dir, f_name)
                    try:
                        with open(p, "r") as f:
                            c = f.read()
                        c_new = re.sub(r'configurations\.all\s*\{(?:\s*resolutionStrategy\s*\{[^}]*\})?\s*\}', '// configurations.all removed for AGP', c)
                        c_new = re.sub(r'configurations\.configureEach\s*\{(?:\s*resolutionStrategy\s*\{[^}]*\})?\s*\}', '// configurations.configureEach removed for AGP', c_new)
                        
                        # Fallback line-by-line commenter for any remaining configurations.all
                        lines = c_new.split('\n')
                        clean_lines = []
                        in_config_block = False
                        brace_count = 0
                        for line in lines:
                            if 'configurations.all' in line or 'configurations.configureEach' in line:
                                in_config_block = True
                                brace_count += line.count('{') - line.count('}')
                                clean_lines.append('// ' + line)
                            elif in_config_block:
                                brace_count += line.count('{') - line.count('}')
                                clean_lines.append('// ' + line)
                                if brace_count <= 0:
                                    in_config_block = False
                            else:
                                clean_lines.append(line)
                        c_new = '\n'.join(clean_lines)
                        
                        c_new = re.sub(r'compileSdkVersion\s+[0-9]+', 'compileSdkVersion 34', c_new)
                        c_new = re.sub(r'compileSdk\s*=\s*[0-9]+', 'compileSdk = 34', c_new)
                        c_new = re.sub(r'flutter\.compileSdkVersion', '34', c_new)
                        if c_new != c:
                            with open(p, "w") as f:
                                f.write(c_new)
                    except Exception:
                        pass

print("Android patching complete.")
