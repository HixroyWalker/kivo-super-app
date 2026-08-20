import os
import re

# 1. Clean any existing .xcconfig files in Pods
pods_dir = "ios/Pods"
if os.path.exists(pods_dir):
    for root, dirs, files in os.walk(pods_dir):
        for file in files:
            if file.endswith(".xcconfig"):
                filepath = os.path.join(root, file)
                with open(filepath, "r") as f:
                    xc_content = f.read()
                if "-G" in xc_content:
                    new_xc = re.sub(r'-G(\s+|$)', ' ', xc_content)
                    with open(filepath, "w") as f:
                        f.write(new_xc)

# 2. Patch Xcode Project settings
pbxproj_path = "ios/Runner.xcodeproj/project.pbxproj"
if os.path.exists(pbxproj_path):
    with open(pbxproj_path, "r") as f:
        pbx = f.read()
        
    team_id = os.environ.get("APPLE_TEAM_ID") or os.environ.get("DEVELOPMENT_TEAM", "")
    if team_id:
        if "DEVELOPMENT_TEAM" in pbx:
            pbx = re.sub(r'DEVELOPMENT_TEAM\s*=\s*".*?"', f'DEVELOPMENT_TEAM = "{team_id}"', pbx)
            pbx = re.sub(r'DEVELOPMENT_TEAM\s*=\s*[^;]+;', f'DEVELOPMENT_TEAM = {team_id};', pbx)
        else:
            pbx = pbx.replace('buildSettings = {', f'buildSettings = {{\n\t\t\t\tDEVELOPMENT_TEAM = {team_id};')
        
    pbx = re.sub(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*[^;]+;', 'PRODUCT_BUNDLE_IDENTIFIER = com.kivowebb.app;', pbx)
    pbx = re.sub(r'CODE_SIGN_IDENTITY\s*=\s*"iPhone Developer";', 'CODE_SIGN_IDENTITY = "Apple Distribution";', pbx)
    pbx = re.sub(r'CODE_SIGN_IDENTITY\s*=\s*"Apple Development";', 'CODE_SIGN_IDENTITY = "Apple Distribution";', pbx)
    pbx = re.sub(r'CODE_SIGN_STYLE\s*=\s*Automatic;', 'CODE_SIGN_STYLE = Manual;', pbx)
    
    if "PROVISIONING_PROFILE_SPECIFIER" in pbx:
        pbx = re.sub(r'PROVISIONING_PROFILE_SPECIFIER\s*=\s*".*?"', 'PROVISIONING_PROFILE_SPECIFIER = "com.kivowebb.app AppStore"', pbx)
        pbx = re.sub(r'PROVISIONING_PROFILE_SPECIFIER\s*=\s*[^;]+;', 'PROVISIONING_PROFILE_SPECIFIER = "com.kivowebb.app AppStore";', pbx)
    else:
        pbx = pbx.replace('buildSettings = {', 'buildSettings = {\n\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = "com.kivowebb.app AppStore";')
        
    with open(pbxproj_path, "w") as f:
        f.write(pbx)

# 3. Patch Info.plist to guarantee encryption compliance & full screen & version bindings
info_plist_path = "ios/Runner/Info.plist"
if os.path.exists(info_plist_path):
    with open(info_plist_path, "r") as f:
        plist = f.read()

    if "ITSAppUsesNonExemptEncryption" not in plist:
        plist = plist.replace("<dict>", "<dict>\n\t<key>ITSAppUsesNonExemptEncryption</key>\n\t<false/>")
    if "GADApplicationIdentifier" not in plist:
        plist = plist.replace("<dict>", "<dict>\n\t<key>GADApplicationIdentifier</key>\n\t<string>ca-app-pub-3940256099942544~1458002511</string>")
    if "UIRequiresFullScreen" not in plist:
        plist = plist.replace("<dict>", "<dict>\n\t<key>UIRequiresFullScreen</key>\n\t<true/>")
    if "NSFaceIDUsageDescription" not in plist:
        plist = plist.replace("<dict>", "<dict>\n\t<key>NSFaceIDUsageDescription</key>\n\t<string>Kivo requires FaceID / TouchID to secure your wallet transfers, biometric login, and merchant financials.</string>")
    if "CFBundleShortVersionString" in plist:
        plist = re.sub(r'<key>CFBundleShortVersionString</key>\s*<string>.*?</string>', '<key>CFBundleShortVersionString</key>\n\t<string>$(FLUTTER_BUILD_NAME)</string>', plist)
    if "CFBundleVersion" in plist:
        plist = re.sub(r'<key>CFBundleVersion</key>\s*<string>.*?</string>', '<key>CFBundleVersion</key>\n\t<string>$(FLUTTER_BUILD_NUMBER)</string>', plist)

    with open(info_plist_path, "w") as f:
        f.write(plist)

print("iOS patching complete.")
