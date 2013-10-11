Pod::Spec.new do |s|
  s.name         = "BDBOAuth1Manager"
  s.version      = "0.1.0"
  s.summary      = "AFNetworking 2.0.0 Extension for OAuth 1.0a Authentication."
  s.homepage     = "https://github.com/bdbergeron/BDBOAuth1Manager"
  s.license      = 'MIT'
  s.author       = { 'Mattt Thompson' => 'm@mattt.me', 'Bradley David Bergeron' => 'bradbergeron@gmail.com' }
  s.source       = { :git => "https://github.com/bdbergeron/BDBOAuth1Manager.git", :tag => '0.1.0' }
  s.source_files = 'BDBOAuth1Manager'
  s.requires_arc = true

  s.dependency 'AFNetworking', '~> 2.0.0'
end
