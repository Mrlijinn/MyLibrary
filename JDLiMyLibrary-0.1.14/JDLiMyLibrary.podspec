Pod::Spec.new do |s|
  s.name = "JDLiMyLibrary"
  s.version = "0.1.14"
  s.summary = "pay iOS For MyLibrary."
  s.license = {"type"=>"MIT", "file"=>"LICENSE"}
  s.authors = {"lijin"=>"18648250125@163.com"}
  s.homepage = "https://github.com/Mrlijinn/MyLibrary"
  s.description = "description by ios team pay"
  s.source = { :path => '.' }

  s.ios.deployment_target    = '8.0'
  s.ios.vendored_framework   = 'ios/JDLiMyLibrary.framework'
end
