require 'json'

package = JSON.parse(File.read(File.join(__dir__, '..', 'package.json')))

# expo-modules-core 58.0.16 bans `JavaScriptValue` arguments and adds `@JS` closure arguments in the same release.
js_closure_args = ENV['MCU_MANAGER_JS_CLOSURE_ARGS']
if js_closure_args.nil?
  search_paths = [ENV['PROJECT_ROOT'] || Pod::Config.instance.installation_root.to_s, __dir__]
  find_expo_modules_core_version = <<~JS
    const { dirname } = require('path');
    const expo = require.resolve('expo/package.json', { paths: #{search_paths.to_json} });
    require(require.resolve('expo-modules-core/package.json', { paths: [dirname(expo)] })).version
  JS
  expo_modules_core_version = IO.popen(['node', '--print', find_expo_modules_core_version], &:read).strip

  if expo_modules_core_version.empty?
    Pod::UI.warn "[ReactNativeMcuManager] Couldn't find expo-modules-core; assuming Expo SDK 57 or older. " \
                 'On Expo SDK 58, set MCU_MANAGER_JS_CLOSURE_ARGS=1.'
  end
  js_closure_args = Gem::Version.new(expo_modules_core_version) >= Gem::Version.new('58.0.16') ? '1' : '0'
end

Pod::Spec.new do |s|
  s.name           = 'ReactNativeMcuManager'
  s.version        = package['version']
  s.summary        = package['description']
  s.description    = package['description']
  s.license        = package['license']
  s.author         = package['author']
  s.homepage       = package['homepage']
  s.platform       = :ios, '13.4'
  s.swift_version  = '5.4'
  s.source         = { git: 'https://github.com/PlayerData/react-native-mcu-manager' }
  s.static_framework = true

  s.dependency 'ExpoModulesCore'
  s.dependency 'iOSMcuManagerLibrary', '1.14.3'

  xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_COMPILATION_MODE' => 'wholemodule'
  }
  if js_closure_args == '1'
    xcconfig['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = '$(inherited) MCU_MANAGER_JS_CLOSURE_ARGS'
  end
  s.pod_target_xcconfig = xcconfig

  s.source_files = '**/*.{h,m,swift}'
end
