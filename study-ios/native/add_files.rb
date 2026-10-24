# Adds native files to the generated Xcode project (App target).
require 'xcodeproj'
proj = Xcodeproj::Project.open('ios/App/App.xcodeproj')
target = proj.targets.find { |t| t.name == 'App' }
group = proj.main_group['App']
swift = ARGV.select { |f| f.end_with?('.swift') }
other = ARGV.reject { |f| f.end_with?('.swift') || f.end_with?('.entitlements') }
swift.each do |f|
  next if group.files.any? { |r| r.path == f }
  target.add_file_references([group.new_reference(f)])
end
other.each do |f|
  next if group.files.any? { |r| r.path == f }
  target.add_resources([group.new_reference(f)])
end
ARGV.select { |f| f.end_with?('.entitlements') }.each do |f|
  group.new_reference(f) unless group.files.any? { |r| r.path == f }
  target.build_configurations.each { |c| c.build_settings['CODE_SIGN_ENTITLEMENTS'] = "App/#{f}" }
end
# iOS 16.2+ (Screen Time APIs, same as the previous build)
proj.build_configurations.each { |c| c.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.2' }
target.build_configurations.each { |c| c.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.2' }
proj.save
puts "Added to Xcode project: #{ARGV.join(', ')}"
