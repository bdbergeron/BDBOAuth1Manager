Pod::Spec.new do |s|
  s.name      = 'BDBOAuth1Manager'
  s.version   = '2.0.0'
  s.license   = 'MIT'
  s.summary   = 'AFNetworking 2.0-compatible replacement for AFOAuth1Client.'
  s.homepage  = 'https://github.com/bdbergeron/BDBOAuth1Manager'
  s.social_media_url = 'https://twitter.com/bradbergeron'
  s.authors   = { 'Bradley David Bergeron' => 'brad@bradbergeron.com' }
  s.source    = { :git => 'https://github.com/bdbergeron/BDBOAuth1Manager.git', :tag => s.version.to_s }
  s.requires_arc = true

  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.9'

  s.source_files = 'BDBOAuth1Manager/**/*.{h,m}'

  s.dependency 'AFNetworking/NSURLSession', '~> 3.0.0'
end
