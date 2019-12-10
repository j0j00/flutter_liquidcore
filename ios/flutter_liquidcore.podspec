Pod::Spec.new do |s|
  s.name             = 'flutter_liquidcore'
  s.version          = '1.1.0'
  s.summary          = 'Node.js virtual machine for Android and iOS'
  s.description      = <<-DESC
Node.js virtual machine for Android and iOS using the amazing https://github.com/LiquidPlayer/LiquidCore library.
                       DESC
  s.homepage         = 'https://github.com/j0j00/flutter_liquidcore'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'j0j00' => 'jojodev@protonmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'LiquidCore', '~> 0.6'
  s.dependency 'Flutter'

  s.ios.deployment_target = '10.0'
end
