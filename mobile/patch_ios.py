import os
import re

podfile_path = "ios/Podfile"
if os.path.exists(podfile_path):
    with open(podfile_path, "r") as f:
        content = f.read()
        
    patch = """    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
      config.build_settings['SWIFT_EMIT_APP_INTENTS_METADATA'] = 'NO'
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      
      # Suppress Xcode 16 Explicit Module non-modular include errors
      config.build_settings['OTHER_CFLAGS'] = ['$(inherited)', '-Wno-non-modular-include-in-framework-module', '-Wno-error=non-modular-include-in-framework-module']
      config.build_settings['OTHER_CPLUSPLUSFLAGS'] = ['$(inherited)', '-Wno-non-modular-include-in-framework-module', '-Wno-error=non-modular-include-in-framework-module']
      config.build_settings['OTHER_SWIFT_FLAGS'] = ['$(inherited)', '-Xcc', '-Wno-non-modular-include-in-framework-module']
      
      if target.name.start_with?('gRPC') || target.name == 'abseil'
        config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '0'
      end
    end"""
    
    if 'flutter_additional_ios_build_settings(target)' in content:
        content = re.sub(r'#?\s*platform\s+:ios\s*,.*', "platform :ios, '14.0'", content)
        if "platform :ios, '14.0'" not in content:
            content = "platform :ios, '14.0'\n" + content
        if "use_frameworks!" in content:
            content = re.sub(r'#?\s*use_frameworks!.*', "use_frameworks! :linkage => :static", content)
        else:
            content = content.replace("target 'Runner' do", "target 'Runner' do\n  use_frameworks! :linkage => :static")
        content = content.replace('use_modular_headers!', '')
        content = content.replace('flutter_additional_ios_build_settings(target)', 'flutter_additional_ios_build_settings(target)\n' + patch)
        with open(podfile_path, "w") as f:
            f.write(content)

# Clean any existing .xcconfig files in Pods
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
        
    with open(pbxproj_path, "w") as f:
        f.write(pbx)

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
