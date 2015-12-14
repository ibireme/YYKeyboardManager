Pod::Spec.new do |s|
  s.name         = 'YYKeyboardManager'
  s.summary      = 'iOS utility class allows you to access keyboard view and track keyboard animation.'
  s.version      = '0.9.2'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.authors      = { 'ibireme' => 'ibireme@gmail.com' }
  s.social_media_url = 'http://blog.ibireme.com'
  s.homepage     = 'https://github.com/ibireme/YYKeyboardManager'
  s.platform     = :ios, '6.0'
  s.ios.deployment_target = '6.0'
  s.source       = { :git => 'https://github.com/ibireme/YYKeyboardManager.git', :tag => s.version.to_s }
  
  s.requires_arc = true
  s.source_files = 'YYKeyboardManager/*.{h,m}'
  s.public_header_files = 'YYKeyboardManager/*.{h}'
  
  s.frameworks = 'UIKit'

end
