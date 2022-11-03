Pod::Spec.new do |s|
    s.name                    = 'OCRKTP'
    s.version                 = '1.0.0'
    s.summary                 = 'Main module for Indonesian ID Card OCR'
    s.homepage                = 'https://medium.com/@alpiopio'
    s.author                  = { 'alfian0' => 'alfian.official.mail@gmail.com' }
    s.license                 = { :type => 'MIT', :file => 'LICENSE' }
    s.source                  = { :git => 'https://github.com/alfian0/OCRKTP.git', :tag => s.version }
    s.source_files            = 'OCRKTP/**/*.{swift}'
    s.platform                = :ios
    s.swift_version           = '5.0'
    s.ios.deployment_target   = '13.0'
    s.resources    = [
           'OCRKTP/**/*.{storyboard,xib,xcassets,strings}'
    ]
  end
  