
desc "Run the NBClient iOS unit tests"
task :test do
  command = "xcodebuild"
  command << " -workspace NBClient.xcworkspace"
  command << " -scheme 'NBClient' -sdk 'iphonesimulator'"
  command << " -configuration Release"
  command << " clean test"
  command << " | xcpretty -c; exit ${PIPESTATUS[0]}"
  sh(command) rescue nil
  unless $?.success?
    puts error_text("iOS unit tests failed")
    exit $?.exitstatus
  end
end

task :default => 'test'

private

def error_text(text)
 "\033[0;31m! #{text}"
end
