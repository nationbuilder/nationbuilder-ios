
desc "Run the NBClient iOS unit tests"
task :test do
  command = "xcodebuild"
  command << " -workspace NBClient.xcworkspace"
  command << " -scheme 'Travis-NBClientTests' -sdk 'iphonesimulator'"
  command << " -configuration Debug"
  command << " clean test"
  command << " | xcpretty -c; exit ${PIPESTATUS[0]}"
  sh(command) rescue nil
  puts error_text("iOS unit tests failed") unless $?.success?
end

task :default => 'test'

private

def error_text(text)
 "\033[0;31m! #{text}"
end
