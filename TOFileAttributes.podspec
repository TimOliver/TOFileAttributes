Pod::Spec.new do |s|
  s.name     = 'TOFileAttributes'
  s.version  = '1.0.0'
  s.license  =  { :type => 'MIT', :file => 'LICENSE' }
  s.summary  = 'An abstract class that enables writing data to the extended attributes of a file on an APFS file system.'
  s.homepage = 'https://github.com/TimOliver/TOFileAttributes'
  s.author   = 'Tim Oliver'
  s.source   = { :git => 'https://github.com/TimOliver/TOFileAttributes.git', :tag => s.version }
  s.source_files = 'TOFileAttributes/**/*.{h,m}'
  s.requires_arc = true
  s.dependency 'TOPropertyAccessor'

  s.ios.deployment_target   = '11.0'
  s.osx.deployment_target   = '10.13'
  s.tvos.deployment_target = '11.0'
end
