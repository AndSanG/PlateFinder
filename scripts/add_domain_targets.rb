#!/usr/bin/env ruby
# Adds macOS Domain Framework + macOS Unit Test Bundle to PlateFinder.xcodeproj.
# Run from the project root: ruby scripts/add_domain_targets.rb

require 'xcodeproj'

PROJ_PATH      = 'PlateFinder.xcodeproj'
MACOS_TARGET   = '15.0'
BUNDLE_PREFIX  = 'com.dapeter.notruper'
SWIFT_VERSION  = '5.0'

proj = Xcodeproj::Project.open(PROJ_PATH)

# Guard: abort if already added so the script is idempotent
if proj.targets.any? { |t| t.name == 'PlateFinder' && t.sdk == 'macosx' }
  puts 'Domain framework target already exists — nothing to do.'
  exit 0
end

# ── 1. macOS Framework target ────────────────────────────────────────────────
framework = proj.new_target(:framework, 'PlateFinder', :osx, MACOS_TARGET)
framework.build_configurations.each do |cfg|
  s = cfg.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = "#{BUNDLE_PREFIX}.domain"
  s['SWIFT_VERSION']             = SWIFT_VERSION
  s['MACOSX_DEPLOYMENT_TARGET']  = MACOS_TARGET
  s['DEFINES_MODULE']            = 'YES'
  s['SKIP_INSTALL']              = 'YES'
  s['CODE_SIGN_STYLE']           = 'Automatic'
  s['CODE_SIGNING_ALLOWED']      = 'NO'
  # Keep the framework name distinct from the iOS app product name in the
  # build directory by using a different PRODUCT_NAME.
  s['PRODUCT_NAME']              = 'PlateFinder'
end

puts "Added macOS Framework target '#{framework.name}' (#{framework.uuid})"

# ── 2. macOS Unit Testing Bundle ─────────────────────────────────────────────
tests = proj.new_target(:unit_test_bundle, 'PlateFinderTests', :osx, MACOS_TARGET)
tests.build_configurations.each do |cfg|
  s = cfg.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = "#{BUNDLE_PREFIX}.tests"
  s['SWIFT_VERSION']             = SWIFT_VERSION
  s['MACOSX_DEPLOYMENT_TARGET']  = MACOS_TARGET
  s['TEST_HOST']                 = ''   # unit tests, no host app
  s['CODE_SIGN_STYLE']           = 'Automatic'
  s['CODE_SIGNING_ALLOWED']      = 'NO'
end

# Make tests depend on and link against the domain framework
tests.add_dependency(framework)
link_phase = tests.frameworks_build_phase
link_phase.add_file_reference(framework.product_reference)

puts "Added macOS Test Bundle target '#{tests.name}' (#{tests.uuid})"

proj.save
puts 'project.pbxproj saved.'

# ── 3. Create a shared scheme for domain tests ───────────────────────────────
scheme = Xcodeproj::XCScheme.new

# Build action — build both framework and test bundle
scheme.build_action.entries.clear
[framework, tests].each do |target|
  entry = Xcodeproj::XCScheme::BuildAction::Entry.new(target)
  entry.build_for_testing  = true
  entry.build_for_running  = false
  entry.build_for_archiving = false
  scheme.build_action.add_entry(entry)
end

# Test action — random order + code coverage
scheme.test_action.code_coverage_enabled   = true
scheme.test_action.build_configuration     = 'Debug'

testable = Xcodeproj::XCScheme::TestAction::TestableReference.new(tests)
testable.randomize_execution_order = true
scheme.test_action.add_testable(testable)

schemes_dir = Xcodeproj::XCScheme.shared_data_dir(PROJ_PATH) + 'xcschemes/'
scheme.save_as(PROJ_PATH, 'PlateFinderTests', true)

puts "Shared scheme 'PlateFinderTests.xcscheme' created with random order + coverage."
puts 'Done.'
