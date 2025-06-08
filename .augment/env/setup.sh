#!/bin/bash
set -e

echo "Setting up development environment for WordSuggest Swift project..."

# Update package lists
sudo apt-get update

# Install basic development tools (avoiding npm conflict)
sudo apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    python3 \
    python3-pip

echo "Installing development tools..."

# Install pygments for syntax highlighting/checking
pip3 install --user pygments

# Create a simple Swift syntax checker script
cat > /tmp/swift_syntax_checker.py << 'EOF'
#!/usr/bin/env python3
import sys
import re
import os

def check_swift_syntax(filename):
    """Basic Swift syntax checker"""
    try:
        with open(filename, 'r') as f:
            content = f.read()
        
        # Basic syntax checks
        errors = []
        warnings = []
        
        # Check for basic Swift syntax patterns
        if 'import' not in content and filename != 'main.swift':
            warnings.append(f"Warning: No import statements found in {filename}")
        
        # Check for balanced braces
        open_braces = content.count('{')
        close_braces = content.count('}')
        if open_braces != close_braces:
            errors.append(f"Error: Unbalanced braces in {filename} (open: {open_braces}, close: {close_braces})")
        
        # Check for balanced parentheses
        open_parens = content.count('(')
        close_parens = content.count(')')
        if open_parens != close_parens:
            errors.append(f"Error: Unbalanced parentheses in {filename} (open: {open_parens}, close: {close_parens})")
        
        # Check for balanced square brackets
        open_brackets = content.count('[')
        close_brackets = content.count(']')
        if open_brackets != close_brackets:
            errors.append(f"Error: Unbalanced square brackets in {filename} (open: {open_brackets}, close: {close_brackets})")
        
        # Check for basic Swift keywords
        swift_keywords = ['class', 'func', 'var', 'let', 'import', 'struct', 'enum', 'protocol']
        has_swift_content = any(keyword in content for keyword in swift_keywords)
        
        if not has_swift_content:
            warnings.append(f"Warning: {filename} doesn't appear to contain Swift code")
        
        # Print warnings
        for warning in warnings:
            print(warning)
        
        # Print errors
        if errors:
            for error in errors:
                print(error)
            return False
        else:
            print(f"✓ {filename} passed basic syntax checks")
            return True
            
    except Exception as e:
        print(f"Error checking {filename}: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 swift_syntax_checker.py <swift_file>")
        sys.exit(1)
    
    filename = sys.argv[1]
    success = check_swift_syntax(filename)
    sys.exit(0 if success else 1)
EOF

chmod +x /tmp/swift_syntax_checker.py

# Add the script to PATH
sudo cp /tmp/swift_syntax_checker.py /usr/local/bin/swift_syntax_checker
sudo chmod +x /usr/local/bin/swift_syntax_checker

# Add to user's profile
echo 'export PATH="/usr/local/bin:$PATH"' >> $HOME/.profile
export PATH="/usr/local/bin:$PATH"

echo "Development environment setup completed!"

# Change to the workspace directory
cd /mnt/persist/workspace

echo "Verifying project structure..."
ls -la

echo "Found Swift files:"
ls -la *.swift

echo "Running Swift syntax checks on all Swift files..."

# Check each Swift file
for file in *.swift; do
    if [ -f "$file" ]; then
        echo "Checking $file..."
        python3 /usr/local/bin/swift_syntax_checker "$file"
    fi
done

echo "Creating a project verification script..."

# Create a project structure verification script
cat > verify_project.py << 'EOF'
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
EOF

chmod +x verify_project.py

echo "Running project structure verification..."
python3 verify_project.py

echo "Setup completed successfully!"