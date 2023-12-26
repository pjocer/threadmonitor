#
# Be sure to run `pod lib lint SNKThreadMonitor.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SNKThreadMonitor'
  s.version          = '0.2.5'
  s.summary          = 'A short description of SNKThreadMonitor.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://git.17zjh.com/snakeGame-iOS/snkthreadmonitor'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Jocer' => 'pjocer@outlook.com' }
  s.source           = { :git => 'git@git.17zjh.com:snakeGame-iOS/snkthreadmonitor.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  s.module_name = 'SNKThreadMonitor'
  s.ios.deployment_target = '11.0'
  
  s.subspec 'Core' do |c|
    c.source_files = 'SNKThreadMonitor/Classes/Core/**/*'
  end
  
  s.default_subspecs = 'Core'
  
  # s.resource_bundles = {
  #   'SNKThreadMonitor' => ['SNKThreadMonitor/Assets/*.png']
  # }

  
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
