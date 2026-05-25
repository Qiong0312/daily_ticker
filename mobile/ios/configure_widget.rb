#!/usr/bin/env ruby
# Adds TodayWidget extension + App Group to the Flutter iOS Xcode project.
# Usage: cd ios && gem install xcodeproj && ruby configure_widget.rb

require 'xcodeproj'

project_path = File.join(__dir__, 'Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)

runner = project.targets.find { |t| t.name == 'Runner' }
abort('Runner target not found') unless runner

if project.targets.any? { |t| t.name == 'TodayWidgetExtension' }
  puts 'TodayWidgetExtension target already exists — skipping.'
  exit 0
end

# App Group on Runner
runner.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
end

project.build_configurations.each do |config|
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
end

# Widget extension target
widget_target = project.new_target(
  :app_extension,
  'TodayWidgetExtension',
  :ios,
  '17.0'
)
widget_target.product_type = 'com.apple.product-type.app-extension'

widget_group = project.main_group.new_group('TodayWidget', 'TodayWidget')
shared_group = project.main_group.new_group('Shared', 'Shared')

widget_sources = %w[
  TodayWidget/TodayWidget.swift
  TodayWidget/TodayWidgetProvider.swift
  TodayWidget/TodayWidgetViews.swift
  TodayWidget/TodayWidgetIntents.swift
  Shared/WidgetDataStore.swift
]

runner_sources = %w[
  Runner/WidgetBridgePlugin.swift
  Shared/WidgetDataStore.swift
]

def add_source(project, target, group, path)
  ref = group.new_file(path)
  target.source_build_phase.add_file_reference(ref)
end

widget_sources.each { |p| add_source(project, widget_target, widget_group, p) }
runner_sources.each do |p|
  next if runner.source_build_phase.files_references.any? { |r| r.path&.include?(File.basename(p)) }
  add_source(project, runner, shared_group, p)
end

widget_target.build_configurations.each do |config|
  config.build_settings.merge!(
    'INFOPLIST_FILE' => 'TodayWidget/Info.plist',
    'CODE_SIGN_ENTITLEMENTS' => 'TodayWidget/TodayWidget.entitlements',
    'PRODUCT_BUNDLE_IDENTIFIER' => 'com.dailyticker.dailyTicker.TodayWidget',
    'PRODUCT_NAME' => '$(TARGET_NAME)',
    'SWIFT_VERSION' => '5.0',
    'IPHONEOS_DEPLOYMENT_TARGET' => '17.0',
    'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks',
    'SKIP_INSTALL' => 'YES',
    'CURRENT_PROJECT_VERSION' => '$(FLUTTER_BUILD_NUMBER)',
    'MARKETING_VERSION' => '$(FLUTTER_BUILD_NAME)',
    'GENERATE_INFOPLIST_FILE' => 'NO',
    'APPLICATION_EXTENSION_API_ONLY' => 'YES',
  )
end

# Embed extension in Runner
embed_phase = runner.copy_files_build_phases.find { |p| p.name == 'Embed App Extensions' }
unless embed_phase
  embed_phase = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
  embed_phase.name = 'Embed App Extensions'
  embed_phase.symbol_dst_subfolder_spec = :plug_ins
  runner.build_phases << embed_phase
end

product_ref = widget_target.product_reference
build_file = embed_phase.add_file_reference(product_ref)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

runner.add_dependency(widget_target)

project.save
puts 'Done. Open ios/Runner.xcworkspace in Xcode and verify signing for Runner + TodayWidgetExtension.'
