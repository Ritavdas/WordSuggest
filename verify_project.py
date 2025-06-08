#!/usr/bin/env python3
import os
import sys

def verify_project_structure():
    """Verify the WordSuggest project structure"""
    required_files = [
        'main.swift',
        'AppDelegate.swift', 
        'TextMonitor.swift',
        'WordSuggestionService.swift',
        'SuggestionWindow.swift',
        'Info.plist',
        'WordSuggest.xcodeproj/project.pbxproj'
    ]
    
    missing_files = []
    present_files = []
    
    for file in required_files:
        if os.path.exists(file):
            present_files.append(file)
            print(f"✓ Found: {file}")
        else:
            missing_files.append(file)
            print(f"✗ Missing: {file}")
    
    print(f"\nProject verification summary:")
    print(f"Present files: {len(present_files)}/{len(required_files)}")
    print(f"Missing files: {len(missing_files)}")
    
    if missing_files:
        print(f"Missing files: {', '.join(missing_files)}")
        return False
    else:
        print("✓ All required project files are present!")
        return True

def count_swift_files():
    """Count Swift files in the project"""
    swift_files = [f for f in os.listdir('.') if f.endswith('.swift')]
    print(f"\nFound {len(swift_files)} Swift files:")
    for f in swift_files:
        print(f"  - {f}")
    return len(swift_files)

if __name__ == "__main__":
    print("=== WordSuggest Project Verification ===")
    structure_ok = verify_project_structure()
    swift_count = count_swift_files()
    
    print(f"\n=== Summary ===")
    print(f"Project structure: {'✓ PASS' if structure_ok else '✗ FAIL'}")
    print(f"Swift files found: {swift_count}")
    
    success = structure_ok and swift_count > 0
    sys.exit(0 if success else 1)
