# CR038 · puts the native .swift files from native/ into the iPhone project (Codemagic runs this; safe to run again).
require 'xcodeproj'
proj = Xcodeproj::Project.open('ios/App/App.xcodeproj')
target = proj.targets.find { |t| t.name == 'App' } or abort('no App target')
group = proj.main_group.find_subpath('App', false) or abort('no App group')
Dir.glob(File.join(__dir__, '*.swift')).map { |f| File.basename(f) }.sort.each do |f|
  next if group.files.any? { |x| x.path == f }
  ref = group.new_reference(f)
  target.add_file_references([ref])
  puts "added #{f}"
end
proj.save
