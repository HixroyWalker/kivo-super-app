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

# Set compileSdk 34 in android/app/build.gradle
app_gradle = "android/app/build.gradle"
if os.path.exists(app_gradle):
    with open(app_gradle, "r") as f:
        content = f.read()
    content = re.sub(r'compileSdk\s*=.*', 'compileSdk = 34', content)
    content = re.sub(r'compileSdkVersion\s+.*', 'compileSdkVersion 34', content)
    content = re.sub(r'targetSdkVersion\s+.*', 'targetSdkVersion 34', content)
    with open(app_gradle, "w") as f:
        f.write(content)

# Prepend subprojects resolutionStrategy & compileSdk 34 to root android/build.gradle
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
                compileSdkVersion 34
                compileSdk 34
            }
        }
    }
}
"""
    with open(root_gradle, "w") as f:
        f.write(subproject_code + "\n" + root_content)

print("Android patching complete.")
