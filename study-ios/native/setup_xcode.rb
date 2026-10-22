require 'xcodeproj'

project = Xcodeproj::Project.open('ios/App/App.xcodeproj')
app = project.targets.find { |t| t.name == 'App' }
raise 'App target not found' unless app
app_id = app.build_configurations.first.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] || 'com.yourname.studytogether'

app.build_configurations.each { |c| c.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.2' }

app_group = project.main_group.find_subpath('App', false)
raise 'App group not found' unless app_group

%w[ViewController.swift LiveActivityPlugin.swift StudyAttributes.swift].each do |f|
  ref = app_group.new_file(f)
  app.add_file_references([ref])
end
app.resources_build_phase.add_file_reference(app_group.new_file('alarm.wav'))

widget = project.new_target(:app_extension, 'StudyWidget', :ios, '16.2')
wg = project.main_group.new_group('StudyWidget', 'StudyWidget')
%w[StudyWidget.swift StudyAttributes.swift].each do |f|
  widget.add_file_references([wg.new_file(f)])
end
wg.new_file('Info.plist')

widget.build_configurations.each do |c|
  s = c.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = "#{app_id}.StudyWidget"
  s['INFOPLIST_FILE'] = 'StudyWidget/Info.plist'
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['SWIFT_VERSION'] = '5.0'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '16.2'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['SKIP_INSTALL'] = 'YES'
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['MARKETING_VERSION'] = '1.0'
  s['CURRENT_PROJECT_VERSION'] = '1'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
end

embed = app.new_copy_files_build_phase('Embed Foundation Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
bf = embed.add_file_reference(widget.product_reference, true)
bf.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
app.add_dependency(widget)

project.save
puts "Widget target added for #{app_id}"
