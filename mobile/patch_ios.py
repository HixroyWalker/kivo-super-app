import os
import re
import shutil

os.makedirs("ios/Flutter", exist_ok=True)
flutter_bin = shutil.which("flutter")
flutter_root = ""

if flutter_bin:
    flutter_root = os.path.dirname(os.path.dirname(os.path.realpath(flutter_bin)))

if not flutter_root:
    candidates = [
        os.environ.get("FLUTTER_ROOT", ""),
        os.path.expanduser("~/hostedtoolcache/flutter"),
        os.path.expanduser("~/flutter"),
        "/opt/hostedtoolcache/flutter",
    ]
    for c in candidates:
        if c and os.path.exists(c):
            if os.path.exists(os.path.join(c, "bin", "flutter")):
                flutter_root = c
                break
            for root_dir, dirs, files in os.walk(c):
                if "bin" in dirs and os.path.exists(os.path.join(root_dir, "bin", "flutter")):
                    flutter_root = root_dir
                    break
            if flutter_root:
                break

# 1. Write ios/Flutter/Generated.xcconfig only if missing
gen_xcconfig_path = "ios/Flutter/Generated.xcconfig"
if not os.path.exists(gen_xcconfig_path):
    with open(gen_xcconfig_path, "w") as f:
        f.write(f"""// This is a generated file; do not edit or check into version control.
FLUTTER_ROOT={flutter_root}
FLUTTER_APPLICATION_PATH={os.path.abspath('.')}
COCOAPODS_PARALLEL_CODE_SIGN=true
FLUTTER_TARGET=lib/main.dart
FLUTTER_BUILD_DIR=build
FLUTTER_BUILD_NAME=1.0.22
FLUTTER_BUILD_NUMBER=130
""")

# 2. Write canonical Podfile
podfile_path = "ios/Podfile"
canonical_podfile = """platform :ios, '14.0'

ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  if File.exist?(generated_xcode_build_settings_path)
    File.foreach(generated_xcode_build_settings_path) do |line|
      matches = line.match(/FLUTTER_ROOT=(.*)/)
      if matches && !matches[1].strip.empty?
        return matches[1].strip
      end
    end
  end
  f = ENV['FLUTTER_ROOT']
  return f if f && !f.empty?
  Dir.glob('/Users/runner/hostedtoolcache/flutter/**/bin/flutter').first&.sub('/bin/flutter', '') || '/Users/runner/flutter'
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks! :linkage => :static
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
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
