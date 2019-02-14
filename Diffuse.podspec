Pod::Spec.new do |s|
  s.name             = 'Diffuse'
  s.summary          = 'A library that aims to simplify the diffing of two collections'
  s.version          = '0.2.0'
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
  s.platforms        = { :ios => '9.0', :osx => '10.14' }
  s.requires_arc     = true
  s.swift_version    = '4.2'
  s.default_subspec  = 'UIKitExtensions'

  s.subspec 'Core' do |sp|
    sp.source_files = "Diffuse/Shared/**/*.swift"
    sp.frameworks   = 'Foundation'
  end

  s.subspec 'UIKitExtensions' do |sp|
    sp.dependency 'Core'
    sp.source_files = "Diffuse/UIKitExtensions/**/*.swift"
    sp.frameworks   = 'UIKit'
  end
end
