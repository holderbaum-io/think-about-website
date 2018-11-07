require 'erb'
require 'kramdown'
require 'yaml'

class Renderer
  def initialize(source_dir = nil)
    @source_dir = source_dir
  end

  def render(lang, url)
    file = resolve_path(url)
    type = resolve_type(file)
    if type == 'text/html'
      template = ERB.new(File.read('template.html.erb'))
      values = TemplateValues.new(lang, url, file, render_page(lang, url, file))
      Result.new(template.result(values._context), url, type)
    else
      Result.new(render_page(lang, url, file), url, type)
    end
  end

  def render_asset(file)
    type = resolve_type(file)
    Result.new(File.read(File.join('assets', file)), file, type)
  end

  private

  def path(file)
    File.join('pages', file)
  end

  def dir?(path)
    File.directory? path
  end

  def file?(path)
    File.file? path
  end

  def resolve_path(file)
    return file if file?(path(file))
    return resolve_path(file + '.erb') if file?(path(file + '.erb'))
    return resolve_path(File.join(file, 'index.html')) if dir?(path(file))
    raise RenderError.new(404, "File not found: #{file}")
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
end

class Renderer
  class Result
    attr_reader :content, :type

    def initialize(content, filename, type)
      @content = content
      @filename = filename
      @type = type
    end

    def filename
      if @filename == ''
        'index.html'
      else
        @filename
      end
    end
  end
end

class Renderer
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

    def t(key)
      file = File.join('content', 'translations.yml')
      result = YAML.safe_load(File.read(file))[lang]
      key.split('.').each do |k|
        result = result.fetch(k)
      end
      result
    end

    def data(key)
      nodes = key.split('.')
      filename = nodes.shift
      file = File.join 'data', filename + '.json'
      result = JSON.parse File.read file
      nodes.each do |k|
        result = result.fetch(k)
      end
      result
    end

    def feature?(type)
      ENV.fetch("FEATURE_#{type.to_s.upcase}", false)
    end

    def _context
      binding
    end
  end
end

class Renderer
  class TemplateValues < Values
    attr_reader :main

    def initialize(lang, url, file, main)
      super lang, url, file
      @main = main
    end
  end
end

class Renderer
  class PageValues < Values
  end
end

class Renderer
  class RenderError < RuntimeError
    attr_reader :type, :text

    def initialize(type, text)
      @type = type
      @text = text
    end

    def message
      "#{type}: #{text}"
    end
  end
end
