Pod::Spec.new do |s|
  s.name         = "BDBOAuth1Manager"
  s.version      = "1.0.0"
  s.summary      = "AFNetworking 2.0-compatible replacement for AFOAuth1Client with support both NSURLConnection- and NSURLSession-based usage."
  s.homepage     = "https://github.com/bdbergeron/BDBOAuth1Manager"
  s.license      = 'MIT'
  s.author       = { 'Mattt Thompson' => 'm@mattt.me', 'Bradley David Bergeron' => 'bradbergeron@gmail.com' }
  s.source       = { :git => "https://github.com/bdbergeron/BDBOAuth1Manager.git", :tag => '1.0.0' }
  s.source_files = 'BDBOAuth1Manager'
  s.requires_arc = true

  s.dependency 'AFNetworking', '~> 2.0.0'
end
