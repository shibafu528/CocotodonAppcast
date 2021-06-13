# frozen_string_literal: true
require 'bundler/setup'
require 'optparse'
require 'json'
require 'fileutils'
require 'erb'
require 'kramdown'
require 'time'

RELEASE_NOTE_PREFIX = 'https://shibafu528.github.io/CocotodonAppcast/releasenotes/'

public_dir = nil
versions_dir = nil

OptionParser.new do |opt|
  opt.on('--public PUBLIC_DIR') { |arg| public_dir = arg }
  opt.on('--versions VERSIONS_DIR') { |arg| versions_dir = arg }
  opt.parse!(ARGV)
end

versions = Dir.each_child(versions_dir).sort.map do |ver_file|
  next unless ver_file.end_with?('.json')
  File.open(File.join(versions_dir, ver_file), 'rb') { |io| JSON.parse(io.read, symbolize_names: true) }
end.compact

FileUtils.mkdir_p(File.join(public_dir, 'releasenotes'))
versions.each do |version|
  body = Kramdown::Document.new(version[:description], input: 'GFM').to_html
  html = ERB.new(File.read('releasenote.erb')).result_with_hash(version: version, body: body)
  File.open(File.join(public_dir, 'releasenotes', "#{version[:title]}.html"), 'wb') do |io|
    io.puts(html)
  end
end

appcast = ERB.new(File.read('appcast.erb')).result
File.open(File.join(public_dir, 'appcast.xml'), 'wb') do |io|
  io.puts(appcast)
end
