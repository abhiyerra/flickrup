#!/usr/bin/env ruby

# flickrup.rb - A utility to upload photos to Flickr.

require 'rubygems'
require 'yaml'
require 'rubygems'
require 'md5'
require 'json'
require 'optparse'

module FlickrUp
  CONFIG_FILE = "flickrup.yml"

  REST_URL = 'http://api.flickr.com/services/rest/'
  UPLOAD_URL = 'http://api.flickr.com/services/upload/'

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
    url = params.has_key?('photo') ? UPLOAD_URL : REST_URL

    params['api_key'] = @config['api_key']
    params['auth_token'] = @config['auth_token'] if @config.has_key? 'auth_token'
    params['format'] = 'json'
    params['nojsoncallback'] = 1
    params['api_sig'] = gen_sig params

    req = params.collect do |k,v|
      "-F #{k}=#{v.kind_of?(File) ? '@' : ''}'#{v.kind_of?(File) ? v.path : v}'"
    end.join(' ')

    result = `curl -s #{req} #{url}`

    JSON.parse(result)
  end

  def load_config
    begin
      @config = YAML::load_file CONFIG_FILE
    rescue
      puts "Failed to load config"
      exit
    end
  end

  def write_config
    open(CONFIG_FILE, 'w') { |out| YAML::dump(@config, out) }
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
      opts.on('--set [SET]', '-s', String, 'Show pictures of sets') do |set_id|
        set = call_method('method' => 'flickr.photosets.getInfo', 'photoset_id' => set_id)
        set_name = set['photoset']['title']['_content']

        photos = call_method('method' => 'flickr.photosets.getPhotos', 'photoset_id' => set_id)
        photo_ids = photos['photoset']['photo'].map { |po| po['id'] }

        begin
          Dir.mkdir(set_name)
        rescue Exception => e
          puts "Dir #{set_name} already exists"
        end

        Dir.chdir(set_name)

        photo_ids.each do |photo_id|
          photo_info = call_method('method' => 'flickr.photos.getInfo', 'photo_id' => photo_id)
          photo = photo_info['photo']

          cmd = %{wget -O "#{photo['title']['_content']}.jpg" http://farm#{photo['farm']}.static.flickr.com/#{photo['server']}/#{photo['id']}_#{photo['originalsecret']}_o.jpg}
          puts cmd
          `#{cmd}`
        end
      end
      opts.on('--sets', '-S', 'List the sets') do
        sets = call_method('method' => 'flickr.photosets.getList')
        sets['photosets']['photoset'].each do |photoset|
          puts "#{photoset['id']} #{photoset['title']['_content']}"
        end
      end

    end.parse!

    ARGV.each { |path| upload path, options } if upload.eql? true
  end
end

include FlickrUp
main
