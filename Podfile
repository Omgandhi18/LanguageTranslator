# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'LanguageTranslator' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for LanguageTranslator
  pod 'IQKeyboardManagerSwift'
  pod 'GoogleMLKit/LanguageID'
  pod 'GoogleMLKit/TextRecognition'
  pod 'GoogleMLKit/Translate'
pod 'MaterialComponents'
  target 'LanguageTranslatorTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'LanguageTranslatorUITests' do
    # Pods for testing
  end

end
post_install do |installer|
    installer.generated_projects.each do |project|
        project.targets.each do |target|
            target.build_configurations.each do |config|
                config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
            end
        end
    end
end