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
  attr_reader :lang, :url, :file

  def initialize(lang, url, file)
    @lang = lang
    @url = url
    @file = file
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

  def initialize(lang, url, file, main)
    super lang, url, file
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
  def path(file)
    File.join('pages', file)
  end

  def resolve_path(file)
    return file if File.file?(path(file))
    return resolve_path(file + '.erb') if File.file?(path(file + '.erb'))
    return resolve_path(File.join(file, 'index.html')) if File.directory?(path(file))
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

  def render_page(lang, url, file)
    if File.extname(file) == '.erb'
      template = ERB.new(File.read(path(file)))
      values = PageValues.new(lang, url, file)
      template.result(values._context)
    else
      File.read(path(file))
    end
  end

  def render_document(lang, file, url)
    type = resolve_type(file)
    if type == 'text/html'
      template = ERB.new(File.read('template.html.erb'))
      values = TemplateValues.new(lang, url, file, render_page(lang, url, file))
      Result.new(template.result(values._context), type)
    else
      Result.new(render_page(lang, url, file), type)
    end
  end

  def render_asset(file)
    type = resolve_type(file)
    Result.new(File.read(File.join('assets', file)), type)
  end

  get '/assets/*' do
    result = render_asset(params[:splat].first)
    content_type result.type
    result.content
  end

  get '/:lang/*' do
    begin
      result = render_document(params[:lang], resolve_path(params[:splat].first), params[:splat].first)
      content_type result.type
      result.content
    rescue ServerError => e
      [e.type, e.text]
    end
  end
end
