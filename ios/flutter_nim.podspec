#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_nim'
  s.version          = '0.1.7'
  s.summary          = 'A new Flutter plugin for netease im.'
  s.description      = <<-DESC
A new Flutter plugin for netease im.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'NIMSDK', '7.0.3'

  s.ios.deployment_target = '9.0'
end

