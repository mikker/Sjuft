Pod::Spec.new do |s|
  s.name             = "Sjuft"
  s.version          = "0.1.0"
  s.license          = 'MIT'
  s.summary          = "Flux in Swift"
  s.homepage         = "https://github.com/mikker/Sjuft"
  s.authors          = { "Mikkel Malmberg" => "mikkel@brnbw.com" }
  s.source           = { :git => "https://github.com/mikker/Sjuft.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/mikker'

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'

  s.dependency 'Dispatcher', '~> 0.1.0'

  s.source_files = 'Sjuft.swift'
  s.requires_arc = true
end
