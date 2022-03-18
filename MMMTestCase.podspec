#
# MMMTestCase. Part of MMMTemple.
# Copyright (C) 2015-2020 MediaMonks. All rights reserved.
#

Pod::Spec.new do |s|

	s.name = "MMMTestCase"
	s.version = "1.5.1"
	s.summary = "Our helpers for FBTestCase and XCTestCase"
	s.description =  s.summary
	s.homepage = "https://github.com/mediamonks/#{s.name}"
	s.license = "MIT"
	s.authors = "MediaMonks"
	s.source = { :git => "https://github.com/mediamonks/#{s.name}.git", :tag => s.version.to_s }

	s.ios.deployment_target = '11.0'
	s.tvos.deployment_target = '10.0'

	s.framework = 'XCTest'
	s.dependency 'FBSnapshotTestCase/Core'

	s.subspec 'ObjC' do |ss|
		ss.source_files = [ "Sources/#{s.name}ObjC/*.{h,m}" ]
	end

	s.swift_versions = '4.2'
	s.static_framework = true
	s.pod_target_xcconfig = {
		"DEFINES_MODULE" => "YES"
	}

	s.subspec 'Swift' do |ss|
		ss.source_files = [ "Sources/#{s.name}/*.swift" ]
		ss.dependency "#{s.name}/ObjC"
		ss.dependency "MMMLoadable"
	end

	s.default_subspec = 'ObjC', 'Swift'
end
