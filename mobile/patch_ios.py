import os
import re

podfile_path = "ios/Podfile"
if os.path.exists(podfile_path):
    with open(podfile_path, "r") as f:
        content = f.read()
        
    patch = """    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
      config.build_settings['CLANG_WARN_NON_MODULAR_INCLUDE_IN_FRAMEWORK_MODULE'] = 'NO'
      config.build_settings['GCC_TREAT_WARNINGS_AS_ERRORS'] = 'NO'
      
      if target.name.start_with?('gRPC') || target.name == 'abseil'
        config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '0'
      end
      
      cflags = ['-Wno-non-modular-include-in-framework-module', '-Wno-error=non-modular-include-in-framework-module']
      ['OTHER_CFLAGS', 'OTHER_CPLUSPLUSFLAGS', 'WARNING_CFLAGS'].each do |flag_key|
        if config.build_settings[flag_key].nil?
          config.build_settings[flag_key] = ['$(inherited)'] + cflags
        elsif config.build_settings[flag_key].is_a?(String)
          config.build_settings[flag_key] = config.build_settings[flag_key].gsub(/-Werror\\S*/, '')
          config.build_settings[flag_key] += ' ' + cflags.join(' ')
        elsif config.build_settings[flag_key].is_a?(Array)
          config.build_settings[flag_key].reject! { |flag| flag.to_s.start_with?('-Werror') }
          config.build_settings[flag_key].concat(cflags)
        end
      end

      config.build_settings.each do |key, value|
        if value.is_a?(String)
          config.build_settings[key] = value.gsub(/-G(\\s+|$)/, ' ').gsub(/-Werror(\\S*)/, ' ').strip
        elsif value.is_a?(Array)
          config.build_settings[key] = value.map { |v| v.is_a?(String) ? v.gsub(/-G(\\s+|$)/, ' ').gsub(/-Werror(\\S*)/, ' ').strip : v }.reject { |v| v == '-G' || v.empty? }
        end
      end
    end
    if target.respond_to?(:source_build_phase) && target.source_build_phase
      target.source_build_phase.files.each do |file|
        if file.settings && file.settings['COMPILER_FLAGS']
          flags = file.settings['COMPILER_FLAGS'].split
          flags.reject! { |flag| flag.start_with?('-Werror') || flag == '-G' || flag == '-GCC_WARN_INHIBIT_ALL_WARNINGS' }
          if target.name == 'gRPC-Core' || target.name.include?('gRPC')
            flags << '-Wno-missing-template-arg-list-after-template-kw'
          end
          file.settings['COMPILER_FLAGS'] = flags.join(' ')
        end
      end
    end"""
    
    if 'flutter_additional_ios_build_settings(target)' in content:
        content = re.sub(r'use_frameworks!.*', "use_frameworks! :linkage => :static\n  pod 'Firebase', :modular_headers => true\n  pod 'FirebaseCore', :modular_headers => true", content)
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
        pbx = re.sub(r'DEVELOPMENT_TEAM\s*=\s*".*?"', f'DEVELOPMENT_TEAM = "{team_id}"', pbx)
        pbx = re.sub(r'DEVELOPMENT_TEAM\s*=\s*[^;]+', f'DEVELOPMENT_TEAM = {team_id}', pbx)
        
    with open(pbxproj_path, "w") as f:
        f.write(pbx)

print("iOS patching complete.")
