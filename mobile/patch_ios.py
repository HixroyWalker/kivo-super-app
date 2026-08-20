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
        content = re.sub(r'use_frameworks!.*', "use_frameworks! :linkage => :static", content)
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
    pbx = re.sub(r'CODE_SIGN_IDENTITY\s*=\s*"iPhone Developer";', 'CODE_SIGN_IDENTITY = "Apple Distribution";', pbx)
    pbx = re.sub(r'CODE_SIGN_IDENTITY\s*=\s*"Apple Development";', 'CODE_SIGN_IDENTITY = "Apple Distribution";', pbx)
        
    with open(pbxproj_path, "w") as f:
        f.write(pbx)

print("iOS patching complete.")
