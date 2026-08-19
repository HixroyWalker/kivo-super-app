import os
import re

podfile_path = "ios/Podfile"
if os.path.exists(podfile_path):
    with open(podfile_path, "r") as f:
        content = f.read()
        
    patch = """    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
      config.build_settings['GCC_TREAT_WARNINGS_AS_ERRORS'] = 'NO'
      config.build_settings.each do |key, value|
        if value.is_a?(String)
          config.build_settings[key] = value.gsub(/-G(\\s+|$)/, ' ').strip
        elsif value.is_a?(Array)
          config.build_settings[key] = value.map { |v| v.is_a?(String) ? v.gsub(/-G(\\s+|$)/, ' ').strip : v }.reject { |v| v == '-G' || v.empty? }
        end
      end
    end
    if target.name == 'BoringSSL-GRPC' || target.name.include?('BoringSSL')
      target.source_build_phase.files.each do |file|
        if file.settings && file.settings['COMPILER_FLAGS']
          flags = file.settings['COMPILER_FLAGS'].split
          flags.reject! { |flag| flag == '-G' || flag == '-GCC_WARN_INHIBIT_ALL_WARNINGS' }
          file.settings['COMPILER_FLAGS'] = flags.join(' ')
        end
      end
    end
    if target.name == 'gRPC-Core' || target.name.include?('gRPC-C++') || target.name.include?('gRPC')
      target.build_configurations.each do |config|
        config.build_settings['GCC_TREAT_WARNINGS_AS_ERRORS'] = 'NO'
      end
      target.source_build_phase.files.each do |file|
        if file.settings && file.settings['COMPILER_FLAGS']
          flags = file.settings['COMPILER_FLAGS'].split
          flags.reject! { |flag| flag == '-Werror' || flag == '-Werror=missing-template-arg-list-after-template-kw' }
          flags << '-Wno-missing-template-arg-list-after-template-kw'
          file.settings['COMPILER_FLAGS'] = flags.join(' ')
        end
      end
    end"""
    
    if 'flutter_additional_ios_build_settings(target)' in content:
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
        pbx = re.sub(r'DEVELOPMENT_TEAM\s*=\s*".*?"', f'DEVELOPMENT_TEAM = "{team_id}"', pbx)
        pbx = re.sub(r'DEVELOPMENT_TEAM\s*=\s*[^;]+', f'DEVELOPMENT_TEAM = {team_id}', pbx)
        
    with open(pbxproj_path, "w") as f:
        f.write(pbx)

print("iOS patching complete.")
