import os
import re

podfile_path = "ios/Podfile"
if os.path.exists(podfile_path):
    with open(podfile_path, "r") as f:
        content = f.read()
        
    patch = """    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      ['OTHER_CFLAGS', 'OTHER_CPLUSPLUSFLAGS', 'CFLAGS'].each do |flag_key|
        if config.build_settings[flag_key]
          flags = config.build_settings[flag_key]
          if flags.is_a?(String)
            config.build_settings[flag_key] = flags.gsub(/-G\\b/, '')
          elsif flags.is_a?(Array)
            config.build_settings[flag_key] = flags.reject { |f| f == '-G' }
          end
        end
      end
    end"""
    
    if 'flutter_additional_ios_build_settings(target)' in content:
        content = content.replace('flutter_additional_ios_build_settings(target)', 'flutter_additional_ios_build_settings(target)\n' + patch)
        with open(podfile_path, "w") as f:
            f.write(content)

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
