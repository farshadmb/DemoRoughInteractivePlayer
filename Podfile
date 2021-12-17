# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

# ignore all warnings from all dependencies
inhibit_all_warnings!

# supportet swift versions
supports_swift_versions '>= 4.2'

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

target 'InteractiveVideoPlayer' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for InteractiveVideoPlayer

  pod 'RxSwift', '~> 6.0'
  pod 'RxCocoa'
  pod 'RxCoreLocation'
  pod 'RxCoreMotion', :git => 'https://github.com/farshadmb/RxCoreMotion.git', :branch => 'rxcoremotion-rx6.0.0'
  pod 'RxAVFoundation'
  pod 'SwiftLint'
  pod 'PureLayout'
  pod 'XCoordinator'
  pod 'CocoaLumberjack/Swift'

end

post_install do |installer|
  # this code for make resolve waring that be noticed by xcode 12.
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
    end
  end

  # this code for make all IBDesignable work for IB Designer in xcode 12.
  installer.pods_project.build_configurations.each do | config |
      if config.name == 'Debug'
        # config.build_settings['CODE_SIGNING_ALLOWED'] = 'YES'
        config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = ['$(FRAMEWORK_SEARCH_PATHS)']
        # config.build_settings.delete('CODE_SIGNING_ALLOWED')
        # config.build_settings.delete('CODE_SIGNING_REQUIRED')
      end
  end
end
