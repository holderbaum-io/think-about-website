require 'sinatra/base'
require 'sinatra/reloader'
require 'erb'
require 'kramdown'

class Result
  attr_reader :content, :type

  def initialize(content, type)
    @content = content
    @type = type
  end
end

class Values
  attr_reader :lang
  def initialize(lang)
    @lang = lang
  end

  def partial(key)
    ERB.new(File.read("partials/#{key}.html.erb")).result(_context)
  end

  def content(key)
    text = File.read("content/#{lang}/#{key}.md")
    Kramdown::Document.new(text).to_html
  end

  def _context
    binding
  end
end

class TemplateValues < Values
  attr_reader :main

  def initialize(lang, main)
    super lang
    @main = main
  end
end

class PageValues < Values
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

  def render_page(file)
    if File.extname(file) == '.erb'
      template = ERB.new(File.read(file))
      lang = File.split(file).first
      values = PageValues.new(lang)
      template.result(values._context)
    else
      File.read(file)
    end
  end

  def render_document(file)
    type = resolve_type(file)
    if type == 'text/html'
      template = ERB.new(File.read('template.html.erb'))
      lang = File.split(file).first
      values = TemplateValues.new(lang, render_page(file))
      Result.new(template.result(values._context), type)
    else
      Result.new(render_page(file), type)
    end
  end

  get '/*' do
    begin
      result = render_document(resolve_path(params[:splat].first))
      content_type result.type
      result.content
    rescue ServerError => e
      [e.type, e.text]
    end
  end
end
