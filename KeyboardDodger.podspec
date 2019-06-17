#
# Be sure to run `pod lib lint NAME.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name = "KeyboardDodger"
  s.version = "2.0.0"
  s.summary = "KeyboardDodger uses a constraint to move a view out of the way of the on-screen keyboard."
  s.homepage = "https://github.com/TradeMe/KeyboardDodger"
  s.license = { :type => 'MIT' }
  s.author = { "Daniel Clelland" => "daniel.clelland@gmail.com" }
  s.source = { :git => "https://github.com/TradeMe/KeyboardDodger.git", :tag => "2.0.0" }
  s.source_files = 'KeyboardDodger/*.swift'
  s.ios.deployment_target = '8.0'
  s.swift_version = '5.0'
end
