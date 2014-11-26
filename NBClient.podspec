Pod::Spec.new do |s|
  s.name     = 'NBClient'
  s.version  = '1.0.0'
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

  s.subspec 'Core' do |sp|
    # Build settings
    sp.dependency 'NBClient/Locale'
    sp.frameworks = 'Security'
    # File patterns
    sp.source_files = 'NBClient/NBClient/*.{h,m}'
    sp.exclude_files = 'NBClient/UI'
    sp.private_header_files = 'NBClient/NBClient/*_Internal.h'
  end

  s.subspec 'UI' do |sp|
    # Build settings
    sp.dependency 'NBClient/Core'
    sp.frameworks = 'UIKit'
    # File patterns
    sp.source_files = 'NBClient/NBClient/UI/*.{h,m}'
    sp.private_header_files = 'NBClient/NBClient/UI/*_Internal.h'
    sp.resources = [
      'NBClient/NBClient/UI/*.xib', 
      'NBClient/NBClient/UI/NBClient_UI.xcassets',
      'NBClient/NBClient/UI/pe-icon-7-stroke.ttf'
    ]
  end

  s.subspec 'Locale' do |sp|
    # Subspecs
    sp.default_subspecs = 'en'
    # File patterns
    sp.subspec 'All' do |l|
      l.resources = l.preserve_paths = 'NBClient/NBClient/*.lproj'
    end
    sp.subspec 'en' do |l|
      l.resources = l.preserve_paths = 'NBClient/NBClient/en.lproj'
    end
  end

end
