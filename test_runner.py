#!/usr/bin/env python3
"""
WordSuggest Test Runner and Validation Script

This script performs comprehensive testing and validation of the WordSuggest application
including code quality checks, logic validation, and integration testing.
"""

import os
import sys
import re
import json
from typing import List, Dict, Any, Optional

class WordSuggestValidator:
    def __init__(self):
        self.test_results = {
            'structure': {'passed': 0, 'failed': 0, 'details': []},
            'code_quality': {'passed': 0, 'failed': 0, 'details': []},
            'logic': {'passed': 0, 'failed': 0, 'details': []},
            'integration': {'passed': 0, 'failed': 0, 'details': []},
            'security': {'passed': 0, 'failed': 0, 'details': []},
            'performance': {'passed': 0, 'failed': 0, 'details': []}
        }
        
    def run_all_tests(self):
        """Run all test categories"""
        print("🚀 Starting WordSuggest Comprehensive Testing")
        print("=" * 60)
        
        self.test_project_structure()
        self.test_code_quality()
        self.test_logic_validation()
        self.test_integration_points()
        self.test_security_aspects()
        self.test_performance_considerations()
        
        self.generate_report()
        
    def test_project_structure(self):
        """Test project structure and file organization"""
        print("\n📁 Testing Project Structure...")
        
        required_files = [
            'main.swift',
            'AppDelegate.swift',
            'TextMonitor.swift',
            'WordSuggestionService.swift',
            'SuggestionWindow.swift',
            'Info.plist',
            'WordSuggest.xcodeproj/project.pbxproj'
        ]
        
        for file in required_files:
            if os.path.exists(file):
                self._pass('structure', f"✓ Found required file: {file}")
            else:
                self._fail('structure', f"✗ Missing required file: {file}")
        
        # Check for test files
        test_files = ['WordSuggestTests.swift', 'UIComponentTests.swift']
        for test_file in test_files:
            if os.path.exists(test_file):
                self._pass('structure', f"✓ Found test file: {test_file}")
            else:
                self._fail('structure', f"✗ Missing test file: {test_file}")
    
    def test_code_quality(self):
        """Test code quality and best practices"""
        print("\n🔍 Testing Code Quality...")
        
        swift_files = [f for f in os.listdir('.') if f.endswith('.swift') and not f.endswith('Tests.swift')]
        
        for file in swift_files:
            self._analyze_swift_file(file)
    
    def _analyze_swift_file(self, filename: str):
        """Analyze a Swift file for code quality"""
        try:
            with open(filename, 'r') as f:
                content = f.read()
                lines = content.split('\n')
            
            # Check for proper imports
            if 'import Cocoa' in content or 'import Foundation' in content:
                self._pass('code_quality', f"✓ {filename}: Proper imports found")
            else:
                self._fail('code_quality', f"✗ {filename}: Missing essential imports")
            
            # Check for class/struct definitions
            if re.search(r'class\s+\w+|struct\s+\w+', content):
                self._pass('code_quality', f"✓ {filename}: Contains class/struct definitions")
            else:
                self._fail('code_quality', f"✗ {filename}: No class/struct definitions found")
            
            # Check for proper error handling
            if 'guard' in content or 'try' in content or 'catch' in content:
                self._pass('code_quality', f"✓ {filename}: Error handling present")
            else:
                self._fail('code_quality', f"⚠ {filename}: Limited error handling")
            
            # Check for memory management
            if '[weak self]' in content or '[unowned self]' in content:
                self._pass('code_quality', f"✓ {filename}: Memory management considerations")
            else:
                self._fail('code_quality', f"⚠ {filename}: Check memory management")
            
            # Check for documentation
            doc_comments = len(re.findall(r'///.*|/\*\*.*\*/', content))
            if doc_comments > 0:
                self._pass('code_quality', f"✓ {filename}: Documentation comments found ({doc_comments})")
            else:
                self._fail('code_quality', f"⚠ {filename}: Limited documentation")
            
            # Check line length (should be reasonable)
            long_lines = [i+1 for i, line in enumerate(lines) if len(line) > 120]
            if len(long_lines) == 0:
                self._pass('code_quality', f"✓ {filename}: Good line length")
            else:
                self._fail('code_quality', f"⚠ {filename}: {len(long_lines)} lines exceed 120 characters")
                
        except Exception as e:
            self._fail('code_quality', f"✗ {filename}: Error analyzing file - {e}")
    
    def test_logic_validation(self):
        """Test core logic and algorithms"""
        print("\n🧠 Testing Logic Validation...")
        
        # Test WordSuggestionService logic
        self._test_suggestion_service_logic()
        
        # Test TextMonitor logic
        self._test_text_monitor_logic()
        
        # Test SuggestionWindow logic
        self._test_suggestion_window_logic()
    
    def _test_suggestion_service_logic(self):
        """Test suggestion service logic"""
        try:
            with open('WordSuggestionService.swift', 'r') as f:
                content = f.read()
            
            # Check for built-in dictionary
            if 'synonymMap' in content and 'good' in content:
                self._pass('logic', "✓ Built-in synonym dictionary present")
            else:
                self._fail('logic', "✗ Built-in synonym dictionary missing")
            
            # Check for OpenAI integration
            if 'openAIAPIKey' in content and 'api.openai.com' in content:
                self._pass('logic', "✓ OpenAI integration implemented")
            else:
                self._fail('logic', "✗ OpenAI integration missing")
            
            # Check for fallback mechanism
            if 'getBuiltInSuggestions' in content:
                self._pass('logic', "✓ Fallback mechanism present")
            else:
                self._fail('logic', "✗ Fallback mechanism missing")
            
            # Check for proper JSON handling
            if 'JSONSerialization' in content:
                self._pass('logic', "✓ JSON handling implemented")
            else:
                self._fail('logic', "✗ JSON handling missing")
            
            # Check for confidence scoring
            if 'confidence' in content:
                self._pass('logic', "✓ Confidence scoring implemented")
            else:
                self._fail('logic', "✗ Confidence scoring missing")
                
        except Exception as e:
            self._fail('logic', f"✗ Error testing suggestion service: {e}")
    
    def _test_text_monitor_logic(self):
        """Test text monitor logic"""
        try:
            with open('TextMonitor.swift', 'r') as f:
                content = f.read()
            
            # Check for hotkey handling
            if 'hotKey' in content and 'Cmd+Shift+W' in content:
                self._pass('logic', "✓ Hotkey handling implemented")
            else:
                self._fail('logic', "✗ Hotkey handling missing or incomplete")
            
            # Check for accessibility API usage
            if 'AXUIElement' in content and 'kAXSelectedTextAttribute' in content:
                self._pass('logic', "✓ Accessibility API usage present")
            else:
                self._fail('logic', "✗ Accessibility API usage missing")
            
            # Check for clipboard fallback
            if 'NSPasteboard' in content and 'Cmd+C' in content:
                self._pass('logic', "✓ Clipboard fallback implemented")
            else:
                self._fail('logic', "✗ Clipboard fallback missing")
            
            # Check for delegate pattern
            if 'TextMonitorDelegate' in content:
                self._pass('logic', "✓ Delegate pattern implemented")
            else:
                self._fail('logic', "✗ Delegate pattern missing")
                
        except Exception as e:
            self._fail('logic', f"✗ Error testing text monitor: {e}")
    
    def _test_suggestion_window_logic(self):
        """Test suggestion window logic"""
        try:
            with open('SuggestionWindow.swift', 'r') as f:
                content = f.read()
            
            # Check for window positioning
            if 'CGPoint' in content and 'screenFrame' in content:
                self._pass('logic', "✓ Window positioning logic present")
            else:
                self._fail('logic', "✗ Window positioning logic missing")
            
            # Check for visual effects
            if 'NSVisualEffectView' in content:
                self._pass('logic', "✓ Visual effects implemented")
            else:
                self._fail('logic', "✗ Visual effects missing")
            
            # Check for auto-hide functionality
            if 'asyncAfter' in content and 'orderOut' in content:
                self._pass('logic', "✓ Auto-hide functionality present")
            else:
                self._fail('logic', "✗ Auto-hide functionality missing")
            
            # Check for clipboard integration
            if 'NSPasteboard' in content and 'setString' in content:
                self._pass('logic', "✓ Clipboard integration present")
            else:
                self._fail('logic', "✗ Clipboard integration missing")
                
        except Exception as e:
            self._fail('logic', f"✗ Error testing suggestion window: {e}")
    
    def test_integration_points(self):
        """Test integration between components"""
        print("\n🔗 Testing Integration Points...")
        
        try:
            with open('AppDelegate.swift', 'r') as f:
                app_delegate_content = f.read()
            
            # Check for proper component initialization
            components = ['TextMonitor', 'WordSuggestionService', 'SuggestionWindow']
            for component in components:
                if component in app_delegate_content:
                    self._pass('integration', f"✓ {component} integration present")
                else:
                    self._fail('integration', f"✗ {component} integration missing")
            
            # Check for delegate connections
            if 'delegate = self' in app_delegate_content:
                self._pass('integration', "✓ Delegate connections established")
            else:
                self._fail('integration', "✗ Delegate connections missing")
            
            # Check for status bar integration
            if 'NSStatusBar' in app_delegate_content:
                self._pass('integration', "✓ Status bar integration present")
            else:
                self._fail('integration', "✗ Status bar integration missing")
            
            # Check for accessibility permission handling
            if 'AXIsProcessTrusted' in app_delegate_content:
                self._pass('integration', "✓ Accessibility permission handling present")
            else:
                self._fail('integration', "✗ Accessibility permission handling missing")
                
        except Exception as e:
            self._fail('integration', f"✗ Error testing integration: {e}")
    
    def test_security_aspects(self):
        """Test security considerations"""
        print("\n🔒 Testing Security Aspects...")
        
        try:
            with open('WordSuggestionService.swift', 'r') as f:
                content = f.read()
            
            # Check that API key is not hardcoded
            if 'openAIAPIKey = ""' in content:
                self._pass('security', "✓ API key not hardcoded")
            elif 'sk-' in content:
                self._fail('security', "✗ API key appears to be hardcoded")
            else:
                self._pass('security', "✓ API key handling appears secure")
            
            # Check for HTTPS usage
            if 'https://' in content:
                self._pass('security', "✓ HTTPS usage for API calls")
            else:
                self._fail('security', "✗ HTTPS usage not found")
            
            # Check Info.plist for proper permissions
            with open('Info.plist', 'r') as f:
                plist_content = f.read()
            
            if 'NSAccessibilityUsageDescription' in plist_content:
                self._pass('security', "✓ Accessibility usage description present")
            else:
                self._fail('security', "✗ Accessibility usage description missing")
            
            if 'NSAppleEventsUsageDescription' in plist_content:
                self._pass('security', "✓ Apple Events usage description present")
            else:
                self._fail('security', "✗ Apple Events usage description missing")
                
        except Exception as e:
            self._fail('security', f"✗ Error testing security: {e}")
    
    def test_performance_considerations(self):
        """Test performance aspects"""
        print("\n⚡ Testing Performance Considerations...")
        
        try:
            # Check for async operations
            swift_files = [f for f in os.listdir('.') if f.endswith('.swift')]
            async_usage = 0
            
            for file in swift_files:
                with open(file, 'r') as f:
                    content = f.read()
                    if 'DispatchQueue' in content or 'async' in content:
                        async_usage += 1
            
            if async_usage > 0:
                self._pass('performance', f"✓ Async operations used in {async_usage} files")
            else:
                self._fail('performance', "✗ No async operations found")
            
            # Check for memory management
            with open('TextMonitor.swift', 'r') as f:
                content = f.read()
                if '[weak self]' in content:
                    self._pass('performance', "✓ Weak references used to prevent retain cycles")
                else:
                    self._fail('performance', "⚠ Check for potential retain cycles")
            
            # Check for efficient data structures
            with open('WordSuggestionService.swift', 'r') as f:
                content = f.read()
                if 'Dictionary' in content or '[String: [String]]' in content:
                    self._pass('performance', "✓ Efficient data structures used")
                else:
                    self._fail('performance', "⚠ Consider using more efficient data structures")
                    
        except Exception as e:
            self._fail('performance', f"✗ Error testing performance: {e}")
    
    def _pass(self, category: str, message: str):
        """Record a passed test"""
        self.test_results[category]['passed'] += 1
        self.test_results[category]['details'].append(('PASS', message))
        print(f"  {message}")
    
    def _fail(self, category: str, message: str):
        """Record a failed test"""
        self.test_results[category]['failed'] += 1
        self.test_results[category]['details'].append(('FAIL', message))
        print(f"  {message}")
    
    def generate_report(self):
        """Generate comprehensive test report"""
        print("\n" + "=" * 60)
        print("📊 COMPREHENSIVE TEST REPORT")
        print("=" * 60)
        
        total_passed = 0
        total_failed = 0
        
        for category, results in self.test_results.items():
            passed = results['passed']
            failed = results['failed']
            total = passed + failed
            
            total_passed += passed
            total_failed += failed
            
            if total > 0:
                percentage = (passed / total) * 100
                status = "✅ PASS" if percentage >= 80 else "⚠️ WARN" if percentage >= 60 else "❌ FAIL"
                print(f"\n{category.upper()}: {status} ({passed}/{total} - {percentage:.1f}%)")
                
                # Show failed tests
                failed_tests = [detail[1] for detail in results['details'] if detail[0] == 'FAIL']
                if failed_tests:
                    print("  Issues found:")
                    for issue in failed_tests[:3]:  # Show first 3 issues
                        print(f"    • {issue}")
                    if len(failed_tests) > 3:
                        print(f"    • ... and {len(failed_tests) - 3} more")
        
        # Overall summary
        total_tests = total_passed + total_failed
        overall_percentage = (total_passed / total_tests) * 100 if total_tests > 0 else 0
        
        print(f"\n{'='*60}")
        print(f"OVERALL RESULT: {total_passed}/{total_tests} tests passed ({overall_percentage:.1f}%)")
        
        if overall_percentage >= 90:
            print("🎉 EXCELLENT: Application is in great shape!")
        elif overall_percentage >= 80:
            print("✅ GOOD: Application is working well with minor issues")
        elif overall_percentage >= 70:
            print("⚠️ FAIR: Application needs some improvements")
        else:
            print("❌ POOR: Application needs significant work")
        
        # Recommendations
        print(f"\n📋 RECOMMENDATIONS:")
        if self.test_results['code_quality']['failed'] > 0:
            print("  • Improve code quality and documentation")
        if self.test_results['security']['failed'] > 0:
            print("  • Address security concerns")
        if self.test_results['performance']['failed'] > 0:
            print("  • Optimize performance aspects")
        if self.test_results['logic']['failed'] > 0:
            print("  • Fix logic implementation issues")
        
        print(f"\n🔧 NEXT STEPS:")
        print("  1. Run the application in Xcode to test functionality")
        print("  2. Test with real text selection scenarios")
        print("  3. Verify OpenAI integration with valid API key")
        print("  4. Test accessibility permissions on macOS")
        print("  5. Perform user acceptance testing")

if __name__ == "__main__":
    validator = WordSuggestValidator()
    validator.run_all_tests()
