require 'sinatra/base'
require 'sinatra/reloader'

class Result
  attr_reader :content, :type

  def initialize(content, type)
    @content = content
    @type = type
  end
end

class ServerError < RuntimeError
  attr_reader :type, :text

  def initialize(type, text)
    @type = type
    @text = text
  end
end

class Server < Sinatra::Application
  def resolve_path(file)
    p :resolve_path => file
    return file if File.file? file
    return resolve_path(file + '.erb') if File.file? file + '.erb'
    return resolve_path(File.join(file, 'index.html')) if File.directory? file
    raise ServerError.new(404, "File not found: #{file}")
  end

  def resolve_type(filename)
    case File.extname(filename.gsub(/\.erb$/, ''))
    when '.css'
      'text/css'
    when '.svg'
      'image/svg+xml'
    when '.png'
      'image/png'
    else
      'text/html'
    end
  end

  def render(file)
    Result.new(File.read(file), resolve_type(file))
  end

  get '/*' do
    begin
      result = render(resolve_path(params[:splat].first))
      content_type result.type
      result.content
    rescue ServerError => e
      [e.type, e.text]
    end
  end
end
