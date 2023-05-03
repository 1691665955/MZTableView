Pod::Spec.new do |spec|
  spec.name         = "MZHTableView"
  spec.version      = "0.0.4"
  spec.summary      = "高性能横向TableView，支持cell复用"
  spec.homepage     = "https://github.com/1691665955/MZTableView"
  spec.authors         = { 'MZ' => '1691665955@qq.com' }
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.source = { :git => "https://github.com/1691665955/MZTableView.git", :tag => spec.version}
  spec.platform     = :ios, "9.0"
  spec.swift_version = '5.0'
  spec.source_files  = "MZTableView/MZTableView/*"
end
