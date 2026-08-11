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

# Set compileSdk 34 and append subprojects block to android/app/build.gradle
app_gradle = "android/app/build.gradle"
if os.path.exists(app_gradle):
    with open(app_gradle, "r") as f:
        content = f.read()
    content = re.sub(r'compileSdk\s*=.*', 'compileSdk = 34', content)
    content = re.sub(r'compileSdkVersion\s+.*', 'compileSdkVersion 34', content)
    content = re.sub(r'targetSdkVersion\s+.*', 'targetSdkVersion 34', content)
    
    subproject_code = """

subprojects {
    afterEvaluate { project ->
        if (project.hasProperty('android')) {
            project.android {
                compileSdkVersion 34
                compileSdk 34
            }
        }
    }
}
"""
    if "compileSdkVersion 34" not in content:
        content += subproject_code

    with open(app_gradle, "w") as f:
        f.write(content)

# Also append to root android/build.gradle if present
root_gradle = "android/build.gradle"
if os.path.exists(root_gradle):
    with open(root_gradle, "r") as f:
        root_content = f.read()
    root_subproject_code = """
subprojects {
    afterEvaluate { project ->
        if (project.hasProperty('android')) {
            project.android {
                compileSdkVersion 34
                compileSdk 34
            }
        }
    }
}
"""
    if "compileSdkVersion 34" not in root_content:
        with open(root_gradle, "a") as f:
            f.write(root_subproject_code)

print("Android patching complete.")
