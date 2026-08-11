import os
import re

# Clean AndroidManifest package attribute for AGP 8
manifest_path = "android/app/src/main/AndroidManifest.xml"
if os.path.exists(manifest_path):
    with open(manifest_path, "r") as f:
        content = f.read()
    content = content.replace('package="com.kivo.app"', '')
    with open(manifest_path, "w") as f:
        f.write(content)

# Set compileSdk 35 and targetSdkVersion 34 in android/app/build.gradle
app_gradle = "android/app/build.gradle"
if os.path.exists(app_gradle):
    with open(app_gradle, "r") as f:
        content = f.read()
    content = re.sub(r'compileSdk\s*=.*', 'compileSdk = 35', content)
    content = re.sub(r'compileSdkVersion\s+.*', 'compileSdkVersion 35', content)
    content = re.sub(r'targetSdkVersion\s+.*', 'targetSdkVersion 34', content)
    with open(app_gradle, "w") as f:
        f.write(content)

# Prepend subprojects resolutionStrategy & compileSdk 35 to root android/build.gradle
root_gradle = "android/build.gradle"
if os.path.exists(root_gradle):
    with open(root_gradle, "r") as f:
        root_content = f.read()
    subproject_code = """
subprojects {
    project.configurations.all {
        resolutionStrategy.eachDependency { details ->
            if (details.requested.group == 'androidx.exifinterface') {
                details.useVersion '1.3.7'
            }
        }
    }
    afterEvaluate { project ->
        if (project.hasProperty('android')) {
            project.android {
                compileSdkVersion 35
                compileSdk 35
            }
        }
    }
}
"""
    with open(root_gradle, "w") as f:
        f.write(subproject_code + "\n" + root_content)

# Dynamically patch all pub-cache plugin build.gradle files to compileSdk 35
pub_cache = os.path.expanduser("~/.pub-cache")
if os.path.exists(pub_cache):
    for root_dir, dirs, files in os.walk(pub_cache):
        for f_name in files:
            if f_name == "build.gradle":
                p = os.path.join(root_dir, f_name)
                try:
                    with open(p, "r") as f:
                        c = f.read()
                    c_new = re.sub(r'compileSdkVersion\s+[0-9]+', 'compileSdkVersion 35', c)
                    c_new = re.sub(r'compileSdk\s*=\s*[0-9]+', 'compileSdk = 35', c_new)
                    c_new = re.sub(r'flutter\.compileSdkVersion', '35', c_new)
                    if c_new != c:
                        with open(p, "w") as f:
                            f.write(c_new)
                except Exception:
                    pass

print("Android patching complete.")
