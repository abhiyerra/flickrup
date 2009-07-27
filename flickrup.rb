#!/usr/bin/env ruby

# flickrup.rb - A utility to upload photos to Flickr.
#
# This work is put in public domain by Kesava Abhinav Yerra.

require 'yaml'
require 'rubygems'
require 'md5'
require 'rexml/document'
require 'optparse'

ConfigFile = "#{ENV['HOME']}/.flickrup.yaml"

RestUrl = 'http://api.flickr.com/services/rest/'
UploadUrl = 'http://api.flickr.com/services/upload/'

def gen_sig params
  sig_str = @config['secret'] + params.sort.collect do |key,value| 
    "#{key}#{value}" unless key.eql? 'photo'
  end.join('')

  MD5.hexdigest sig_str
end

def create_login_url frob
  params = {}
  params['api_key'] = @config['api_key']
  params['perms'] = 'delete' 
  params['frob'] = frob
  params['api_sig'] = gen_sig params

  auth_url = 'http://flickr.com/services/auth/?' + params.collect { |k,v| "#{k}=#{v}" }.join('&')
  
  puts "Please go to this url and authenticate and press enter after!"
  puts auth_url
  gets
end

def call_method params={}
  url = params.has_key?('photo') ? UploadUrl : RestUrl

  params['api_key'] = @config['api_key']
  params['auth_token'] = @config['auth_token'] if @config.has_key? 'auth_token'
  params['api_sig'] = gen_sig params

  req = params.collect do |k,v|
    "-F #{k}=#{v.kind_of?(File) ? '@' : ''}'#{v.kind_of?(File) ? v.path : v}'"
  end.join(' ')

  result = `curl -s #{req} #{url}`
  
  doc = REXML::Document.new(result)
  doc.root
end

def load_config
  begin
    @config = YAML::load_file ConfigFile
  rescue
    puts "Failed to load config"
    exit
  end
end

def write_config
  open(ConfigFile, 'w') { |out| YAML::dump(@config, out) }
end

def upload path, params={}
  if File.directory?(path)
    files = Dir.entries(path) - [".", ".."]
    Dir.chdir(path) do
      files.each { |file| upload file }
    end
  else
    up = call_method({'photo' => File.new(path, 'rb')})
    if up.elements['photoid']
      puts "Uploaded: #{path}"
    else
      puts "Failed: #{path}"
    end
  end
end

def main
  load_config 
  unless @config.has_key? 'auth_token'
    frob = call_method('method' => 'flickr.auth.getFrob').elements['frob'].text
    create_login_url frob
    @config['auth_token'] = call_method('method' => 'flickr.auth.getToken', 'frob' => frob).elements['auth'].elements['token'].text

    write_config
  end

  upload = false
  set = nil
  sets = false

  options = {}
  OptionParser.new do |opts|
    opts.on('--upload', '-u', 'Upload some pictures') { upload = true }
    opts.on('--set [SET]', '-s', String, 'Sets') do |set|
      if set.nil?
        sets = true 
      else
        set = set
      end
    end
    opts.on('--list', '-l', 'List') do
      if sets
        sets = call_method('method' => 'flickr.photosets.getList')
        sets.each_element('//photoset') do |photoset|
          puts "#{photoset.attributes['id']} #{photoset.elements['title'].text}"
        end
      end

      if set
        photos = call_method('method' => 'flickr.photosets.getPhotos', 
                           'photoset_id' => set,
                           'privacy_filter' => '1')
        photos.each_element('//photo') do |photo|
          puts "http://farm#{photo.attributes['farm']}.static.flickr.com/#{photo.attributes['server']}/#{photo.attributes['id']}_#{photo.attributes['secret']}_b.jpg"
        end
      end

      exit
    end

    opts.on('--create', '-c', 'Create') do
      if sets && upload
      end

      if set && upload
        options[:set] = set
      end
    end
  end.parse!

  ARGV.each { |path| upload path, options } if upload.eql? true
end

main
