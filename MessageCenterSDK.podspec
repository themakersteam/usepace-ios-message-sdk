#
# Be sure to run `pod lib lint MessageCenter.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'MessageCenterSDK'
    s.version          = '0.1.8'
    s.summary          = 'MessageCenterSDK is chatting SDK'
    
    # This description is used to generate tags and improve search results.
    #   * Think: What does it do? Why did you write it? What is the focus?
    #   * Try to keep it short, snappy and to the point.
    #   * Write the description between the DESC delimiters below.
    #   * Finally, don't worry about the indent, CocoaPods strips it!
    
    s.description      = <<-DESC
    TODO: Add long description of the pod here.
    DESC
    
    s.homepage         = 'https://github.com/UsePace/ios-message-sdk'
    s.swift_version     = '4.2'
    # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'ikarmakhan' => 'ikarma.bred@gmail.com' }
    s.source           = { :git => 'https://github.com/UsePace/ios-message-sdk.git', :tag => s.version.to_s }
    # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
    
    s.ios.deployment_target = '11.0'
    s.source_files = 'MessageCenterSDK/Classes/**/*'
    s.dependency 'SendBirdSDK'
    s.dependency 'AlamofireImage'
    s.dependency 'FLAnimatedImage'
    s.dependency 'URLEmbeddedView'
    s.dependency 'CryptoSwift'
    s.dependency 'Toast', '~> 4.0.0'
    s.dependency 'IQKeyboardManagerSwift'
    s.resource_bundles = {
        'MessageCenterSDK' => ['MessageCenterSDK/Assets/*.{storyboard,png,xcassets,xib,lproj/*.strings}']
    }    
end
