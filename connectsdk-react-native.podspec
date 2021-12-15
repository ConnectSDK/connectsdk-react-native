require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name           = 'connectsdk-react-native'
  s.version        = package['version']
  s.summary        = package['description']
  s.description    = package['description']
  s.license        = package['license']
  s.author         = package['author']
  s.homepage       = package['homepage']
  s.source         = { :git => 'https://github.com/ConnectSDK/connectsdk-react-native', :tag => "v#{s.version}" }

  s.requires_arc   = true
  s.platform       = :ios, '11.0'

  s.source_files = "ios/**/*.{h,m}"

  s.preserve_paths = 'LICENSE', 'README.md', 'package.json', 'index.js'

  s.dependency 'React-Core'
  s.ios.dependency 'ConnectSDK-Lite'
  s.ios.dependency 'EventEmitter'
end