Pod::Spec.new do |s|
  s.name     = 'NBClient'
  s.version  = '0.1.0'
  s.license  = 'MIT'
  s.summary  = 'An iOS client to the NationBuilder API.'
  s.homepage = 'https://github.com/3dna/nationbuilder-ios'
  s.authors  = { 'Peng Wang' => 'peng@nationbuilder.com' }
  s.source   = { :git => 'https://github.com/3dna/nationbuilder-ios.git', :tag => s.version.to_s }
  
  # Platform
  s.platform = :ios
  s.ios.deployment_target = '7.0'

  # Build settings
  s.requires_arc = true
  s.frameworks = 'Security'

  # File patterns
  s.source_files = 'NBClient/NBClient'
  s.private_header_files = 'NBClient/NBClient/*_Internal.h'
end
