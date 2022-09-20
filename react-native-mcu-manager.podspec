require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-mcu-manager"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.source_files = "ios/**/*.{h,m,mm,swift}"

  s.platforms    = { :ios => "10.0" }
  s.source       = { :git => "https://github.com/PlayerData/react-native-mcu-manager.git", :tag => "#{s.version}" }

  s.dependency "React-Core"
  s.dependency "iOSMcuManagerLibrary", "~> 1.2.0"

end
