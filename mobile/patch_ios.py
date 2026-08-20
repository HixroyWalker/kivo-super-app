import os
import re

# 1. Write Canonical Podfile with dynamic Flutter SDK detection
podfile_content = """platform :ios, '14.0'

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
      matches = line.match(/FLUTTER_ROOT\=(.*)/)
      return matches[1].strip if matches
    end
  end
  
  if ENV['FLUTTER_ROOT'] && !ENV['FLUTTER_ROOT'].empty?
    return ENV['FLUTTER_ROOT']
  end

  which_flutter = `which flutter`.strip
  unless which_flutter.empty?
    return File.expand_path(File.join(File.dirname(File.realpath(which_flutter)), '..'))
  end

  '/Users/runner/hostedtoolcache/flutter/stable-arm64/flutter'
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

os.makedirs("ios", exist_ok=True)
with open("ios/Podfile", "w") as f:
    f.write(podfile_content)

# 2. Clean any existing .xcconfig files in Pods
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

# 3. Patch Xcode Project Bundle Identifier & Team ID
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
    if "CFBundleShortVersionString" in plist:
        plist = re.sub(r'<key>CFBundleShortVersionString</key>\s*<string>.*?</string>', '<key>CFBundleShortVersionString</key>\n\t<string>$(FLUTTER_BUILD_NAME)</string>', plist)
    if "CFBundleVersion" in plist:
        plist = re.sub(r'<key>CFBundleVersion</key>\s*<string>.*?</string>', '<key>CFBundleVersion</key>\n\t<string>$(FLUTTER_BUILD_NUMBER)</string>', plist)

    with open(info_plist_path, "w") as f:
        f.write(plist)

print("iOS patching complete.")
