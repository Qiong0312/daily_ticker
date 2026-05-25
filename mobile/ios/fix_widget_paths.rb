#!/usr/bin/env ruby
# Fixes red/missing file references for TodayWidget + Shared folders.
# Usage: cd ios && ruby fix_widget_paths.rb

require 'xcodeproj'

project_path = File.join(__dir__, 'Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)

def fix_ref(ref, folder)
  return unless ref.path
  base = File.basename(ref.path)
  ref.path = base if ref.path.start_with?("#{folder}/")
end

project.files.each do |ref|
  next unless ref.path
  fix_ref(ref, 'TodayWidget') if ref.path.include?('TodayWidget/')
  fix_ref(ref, 'Shared') if ref.path.start_with?('Shared/')
  fix_ref(ref, 'Runner') if ref.path.start_with?('Runner/') && ref.path.end_with?('.swift')
end

runner_group = project.main_group['Runner']
shared_group = project.main_group['Shared']
today_group = project.main_group['TodayWidget']

if shared_group && runner_group
  plugin = project.files.find { |f| f.path == 'WidgetBridgePlugin.swift' }
  if plugin && shared_group.files.include?(plugin)
    shared_group.files.delete(plugin)
    runner_group.files << plugin unless runner_group.files.include?(plugin)
  end
end

if today_group
  store_refs = project.files.select { |f| f.path == 'WidgetDataStore.swift' }
  store_refs.each do |ref|
    today_group.files.delete(ref) if today_group.files.include?(ref)
    shared_group.files << ref if shared_group && !shared_group.files.include?(ref)
  end
end

project.save
puts 'Fixed widget file paths. Close and reopen Runner.xcworkspace in Xcode.'
