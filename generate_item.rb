# frozen_string_literal: true
require 'bundler/setup'
require 'optparse'
require 'octokit'
require 'zip'
require 'plist'
require 'json'
require 'fileutils'

tag = nil
app_archive = nil

OptionParser.new do |opt|
  opt.on('--tag TAG') { |arg| tag = arg }
  opt.on('--archive ARCHIVE') { |arg| app_archive = arg }
  opt.parse!(ARGV)
end

output = {
  title: tag,
  url: "https://github.com/shibafu528/Cocotodon/releases/download/#{tag}/Cocotodon-#{tag}.zip",
  type: 'application/octet-stream',
}

# Fetch release note
github = Octokit::Client.new(access_token: ENV.fetch('GITHUB_TOKEN'))
release = github.release_for_tag('shibafu528/Cocotodon', tag)
output[:description] = release.body
output[:pub_date] = release.published_at

# Fetch version from plist
Zip::File.open(app_archive) do |zip|
  entry = zip.glob('Cocotodon.app/Contents/Info.plist').first
  plist = Plist.parse_xml(entry.get_input_stream.read)
  output[:minimum_system_version] = plist['LSMinimumSystemVersion']
  output[:sparkle_version] = plist['CFBundleVersion']
  output[:sparkle_short_version_string] = plist['CFBundleShortVersionString']
end

# Generate sign
output[:sparkle_sign] = IO.popen(['sign_update', '-s', ENV.fetch('SPARKLE_PRIVATE_KEY'), app_archive]) { |io| io.read.chomp }
abort unless $? == 0

# Write JSON
FileUtils.mkdir_p('versions')
File.open(File.join('versions', "#{tag}.json"), 'wb') do |io|
  io.puts(JSON.pretty_generate(output))
end
