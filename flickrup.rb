#!/usr/bin/env jruby

# flickrup.rb - A utility to upload photos to Flickr.
#
# This work is put in public domain by Kesava Abhinav Yerra.
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
# It requires curl to be installed on your computer.
#
# TODO:
#  - getopt
#  - pretty print the output
#  - automatically open a browser window with login_url
#  - Ability to create a set before uploading or 
#     post to existing set.

require 'yaml'
require 'rubygems'
require 'md5'
require 'rexml/document'

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
  url = params.has_key? 'photo' ? UploadUrl : RestUrl

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

def upload path
  if File.directory?(path)
    files = Dir.entries(path) - [".", ".."]
    Dir.chdir(path) do
      files.each { |file| upload file }
    end
  else
    puts call_method({'photo' => File.new(path, 'rb')})
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

  ARGV.each { |path| upload path }
end

main
