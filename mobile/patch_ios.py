import os
import re
import subprocess

os.makedirs("ios/Flutter", exist_ok=True)
flutter_root = ""
try:
    flutter_bin = subprocess.check_output(["which", "flutter"]).decode().strip()
    if flutter_bin:
        flutter_root = os.path.dirname(os.path.dirname(flutter_bin))
except Exception:
    pass

if not flutter_root:
    flutter_root = os.environ.get("FLUTTER_ROOT", "")

# 1. Write ios/Flutter/Generated.xcconfig
gen_xcconfig_path = "ios/Flutter/Generated.xcconfig"
with open(gen_xcconfig_path, "w") as f:
    f.write(f"""// This is a generated file; do not edit or check into version control.
FLUTTER_ROOT={flutter_root}
FLUTTER_APPLICATION_PATH={os.path.abspath('.')}
COCOAPODS_PARALLEL_CODE_SIGN=true
FLUTTER_TARGET=lib/main.dart
FLUTTER_BUILD_DIR=build
FLUTTER_BUILD_NAME=1.0.22
FLUTTER_BUILD_NUMBER=116
""")

# 2. Write canonical Podfile
podfile_path = "ios/Podfile"
canonical_podfile = f"""platform :ios, '14.0'

ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {{
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}}

def flutter_root
  '{flutter_root}'
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks! :linkage => :static

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    if target.respond_to?(:build_configurations)
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
        config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
        config.build_settings['SWIFT_EMIT_APP_INTENTS_METADATA'] = 'NO'
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
        config.build_settings['OTHER_CFLAGS'] = ['$(inherited)', '-Wno-non-modular-include-in-framework-module', '-Wno-error=non-modular-include-in-framework-module']
        config.build_settings['OTHER_CPLUSPLUSFLAGS'] = ['$(inherited)', '-Wno-non-modular-include-in-framework-module', '-Wno-error=non-modular-include-in-framework-module']
        config.build_settings['OTHER_SWIFT_FLAGS'] = ['$(inherited)', '-Xcc', '-Wno-non-modular-include-in-framework-module']
      end
    end
  end
end
"""

with open(podfile_path, "w") as f:
    f.write(canonical_podfile)

# 3. Patch project.pbxproj
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

# 4. Patch Info.plist
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
    if "NSPhotoLibraryUsageDescription" not in plist:
        plist = plist.replace("<dict>", "<dict>\n\t<key>NSPhotoLibraryUsageDescription</key>\n\t<string>Kivo allows you to select photos to share in the social feed, marketplace, and profile.</string>")
    if "NSCameraUsageDescription" not in plist:
        plist = plist.replace("<dict>", "<dict>\n\t<key>NSCameraUsageDescription</key>\n\t<string>Kivo uses the camera to scan QR payment codes and capture photos for your social feed.</string>")
    if "NSMicrophoneUsageDescription" not in plist:
        plist = plist.replace("<dict>", "<dict>\n\t<key>NSMicrophoneUsageDescription</key>\n\t<string>Kivo uses the microphone for merchant soundbox audio and voice playback.</string>")
    if "CFBundleShortVersionString" in plist:
        plist = re.sub(r'<key>CFBundleShortVersionString</key>\s*<string>.*?</string>', '<key>CFBundleShortVersionString</key>\n\t<string>$(FLUTTER_BUILD_NAME)</string>', plist)
    if "CFBundleVersion" in plist:
        plist = re.sub(r'<key>CFBundleVersion</key>\s*<string>.*?</string>', '<key>CFBundleVersion</key>\n\t<string>$(FLUTTER_BUILD_NUMBER)</string>', plist)

    with open(info_plist_path, "w") as f:
        f.write(plist)

print("iOS patching complete.")
