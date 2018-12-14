Pod::Spec.new do |s|
  s.name             = 'Diffuse'
  s.summary          = 'A library that aims to simplify the diffing of two collections'
  s.version          = '0.1.0'
  s.author           = 'FINN.no'
  s.homepage         = 'https://github.com/finn-no/Diffuse'
  s.social_media_url = 'https://twitter.com/FINN_tech'
  s.source           = { :git => 'https://github.com/finn-no/Diffuse.git', :tag => s.version }
  s.description      = <<-DESC
  Diffuse is library that aims to simplify the diffing of two collections. After diffing you get to know:
  - indices where insertion has happened
  - indices that has been removed
  - indices that has moved
  - indices that has been updated
                   DESC
  s.license          = 'MIT'
  s.platform         = :ios, '9.0'
  s.requires_arc     = true
  s.swift_version    = '4.2'
  s.source_files     = 'Diffuse/**/*'
  s.frameworks       = 'Foundation', 'UIKit'
end
