import os

print("Running Firebase header patcher...")

symlinks_dir = 'ios/.symlinks/plugins'
if not os.path.exists(symlinks_dir):
    print(f"Directory not found: {symlinks_dir}")
else:
    for root, dirs, files in os.walk(symlinks_dir, followlinks=True):
        if 'firebase_' in root:
            for file in files:
                if file.endswith('.h'):
                    header = os.path.join(root, file)
                    try:
                        with open(header, 'r') as f:
                            header_content = f.read()
                        if '#import <Firebase/Firebase.h>' in header_content:
                            header_content = header_content.replace(
                                '#import <Firebase/Firebase.h>',
                                '#import <FirebaseCore/FirebaseCore.h>\\n#import <FirebaseMessaging/FirebaseMessaging.h>\\n#import <FirebaseAuth/FirebaseAuth.h>'
                            )
                            with open(header, 'w') as f:
                                f.write(header_content)
                            print(f"Patched {header} to remove non-modular Firebase umbrella import.")
                    except Exception as e:
                        print(f"Error patching {header}: {e}")

print("Firebase header patcher complete.")
