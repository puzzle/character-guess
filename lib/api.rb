require 'json'
require 'open-uri'
require 'pathname'

class Api
  attr_reader :api

  def initialize(api)
    @api = api
  end

  def pull
    prepare_directory

    json = fetch_json(api)
    json.each do |object|
      fetch_image(object['image'])
    end

    write_pretty(json)
  end

  def prepare_directory
    raise "#{public_path} exists" if public_path.exist?
    FileUtils.mkdir_p(images)
  end

  def fetch_json(path)
    JSON.parse(fetch(path))
  end

  def fetch(path)
    open("#{host}/#{path}").read
  end

  def fetch_image(path)
    destination = images.join(path)
    destination.write(fetch(path))
  end

  def images
    public_path.join('images')
  end

  def write_pretty(json)
    public_path.join('list.json').write(JSON.pretty_generate(json))
  end

  def public_path
    @public_path ||= Pathname.new(File.expand_path("../../public/#{api}", __FILE__))
  end

  def host
    'http://swapi.glitch.me'
  end
end
