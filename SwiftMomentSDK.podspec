Pod::Spec.new do |spec|
    spec.name = "SwiftMomentSDK"
    spec.version = "1.0.0"
    spec.summary = "iOS development kit for Moment (https://wearmoment.com)."
    spec.homepage = "https://github.com/SomaticLabs/SwiftMomentSDK"
    spec.license = { type: 'MIT', file: 'LICENSE' }
    spec.authors = { "Jake Rockland" => 'jake@somaticlabs.io' }
    spec.social_media_url = "http://twitter.com/SomaticLabs"

    spec.platform = :ios, "9.0"
    spec.requires_arc = true
    spec.source = { git: "https://github.com/SomaticLabs/SwiftMomentSDK.git", tag: "v#{spec.version}", submodules: true }
    spec.source_files = "SwiftMomentSDK/**/*.{h,swift}"

    spec.dependency "Alamofire", "~> 4.0"
end
