#!/usr/bin/env jruby

# flickrup.rb - A utility to upload photos to Flickr.
#
# This work is public domain.
#
# Create a config file ~/.flickrup and add your Flickr API Key and secret key
# For example:
# 
# secret: SECRET_KEY
# api_key: API_KEY
# 
# To run the script do something like the following:
# flickrup.rb dir_to_upload
# or
# flickrup.rb path_to_file
#
# Note that currently flickrup is uploads recursively. In later versions I hope
# to address this, but right now I'm lazy.
#
# It requires curl to be installed on your computer. Also it requires the 
# rest_client gem to be installed.

require 'yaml'
require 'rubygems'
require 'rest_client'
require 'md5'
require 'json'

ConfigFile = '/Users/abhi/.flickrup.yaml'

RestUrl = 'http://api.flickr.com/services/rest/'
UploadUrl = 'http://api.flickr.com/services/upload/'

#RestClient.log = 'stdout'

def gen_sig params
  sig_str = @config['secret'] + params.sort.collect do |key,value| 
    "#{key}#{value}" unless key.eql? 'photo'
  end.join('')

  p sig_str

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

def call_method params={}, upload=false
  url = upload ? UploadUrl : RestUrl

  params['api_key'] = @config['api_key']
  params['format'] = 'json'
  params['auth_token'] = @config['auth_token'] if @config.has_key? 'auth_token'
  params['api_sig'] = gen_sig params

  if upload
    req = params.collect do |k,v|
      "-F #{k}=#{v.kind_of?(File) ? '@' : ''}'#{v.kind_of?(File) ? v.path : v}'"
    end.join(' ')

    return `curl -s #{req} #{url}`
  else
    return JSON::parse(RestClient.post(url, params).gsub(/^jsonFlickrApi\(/, '').gsub(/\)$/, ''))
  end
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

def upload path
  if File.directory?(path)
    files = Dir.entries(path) - [".", ".."]
    Dir.chdir(path) do
      files.each { |file| upload file }
    end
  else
    puts call_method({'photo' => File.new(path, 'rb')}, upload=true)
  end
end

def main
  load_config 
  unless @config.has_key? 'auth_token'
    frob = call_method 'method' => 'flickr.auth.getFrob'
    frob = frob["frob"]["_content"]

    create_login_url frob

    gettoken = call_method 'method' => 'flickr.auth.getToken',
                           'frob' => frob

    @config['auth_token'] = gettoken["auth"]["token"]["_content"]
    write_config
  end

  ARGV.each { |path| upload path }
end

main