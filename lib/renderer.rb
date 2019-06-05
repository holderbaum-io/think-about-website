require 'erb'
require 'fastimage'
require 'kramdown'
require 'oga'
require 'uri'
require 'yaml'
require 'json'
require 'cgi'

class Renderer
  AVG_WPS = 200.0

  def initialize(source_dir = nil)
    @source_dir = source_dir
  end

  def render(url)
    file = resolve_path(url)
    type = resolve_type(file)
    if type == 'text/html' || type == 'text/markdown'
      type = 'text/html'
      template = ERB.new(File.read(template_for(file)))
      page = render_page(url, file)
      values = TemplateValues.new(url, file, page.content, page.meta)
      values.renderer = self
      Result.new(template.result(values._context), url, type)
    else
      page = render_page(url, file)
      Result.new(page.content, url, type)
    end
  end

  def template_for(file)
    if file.start_with? 'blog/'
      'template-blog.html.erb'
    else
      'template.html.erb'
    end
  end

  def base_url
    'https://think-about.io'
  end

  def render_asset(file)
    type = resolve_type(file)
    Result.new(File.read(File.join('assets', file)), file, type)
  end

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
    return file.gsub(/\.html$/, '.md') if file?(path(file).gsub(/\.html$/, '.md'))
    return resolve_path(file + '.erb') if file?(path(file + '.erb'))
    return resolve_path(File.join(file, 'index.html')) if dir?(path(file))
    raise RenderError.new(404, "File not found: #{file}")
  end

  def resolve_type(filename)
    case File.extname(filename.gsub(/\.erb$/, ''))
    when '.js'
      'application/javascript'
    when '.css'
      'text/css'
    when '.svg'
      'image/svg+xml'
    when '.png'
      'image/png'
    when '.md'
      'text/html'
    else
      'text/html'
    end
  end

  def render_page(url, file)
    result = RenderedPage.new

    if File.extname(file) == '.erb'
      template = ERB.new(File.read(path(file)))
      values = PageValues.new(url, file)
      values.renderer = self
      result.content = template.result(values._context)
    elsif File.extname(file) == '.md'
      text = File.read(path(file))
      doc = Kramdown::Document.new(text, input: 'MetadataKramdown')
      result.content = doc.to_html
      result.meta = {}
      parsed = Oga.parse_html(result.content)
      result.meta[:minutes] = (text.scan(/[[:alnum:]]+/).count / AVG_WPS).ceil
      result.meta[:abstract] = parsed.xpath('p[1]').text
      result.meta[:slug] = File.basename(file, '.md')
      result.meta[:img] = "/assets/images/blog/#{result.meta[:slug]}/header.png"
      result.meta[:link] = "/blog/#{result.meta[:slug]}.html"
      result.meta[:url] = "#{base_url}/blog/#{result.meta[:slug]}.html"
      doc.root.metadata.each do |k, v|
        result.meta[k.to_sym] = v
      end
      result.meta[:date] = result.meta[:date].strftime('%B %-d')
    else
      result.content = File.read(path(file))
    end

    result
  end
end

class Renderer
  class RenderedPage
    attr_accessor :content
    attr_writer :meta

    def meta
      @meta ||= {}
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
    attr_reader :url, :file
    attr_accessor :locals, :renderer

    def initialize(url, file)
      @url = url
      @file = file
      @locals = {}
    end

    def lang
      raise 'DEPRECATED!'
      'en'
    end

    def partial(key, locals = {})
      copy = dup
      copy.locals = locals
      ERB.new(File.read("partials/#{key}.html.erb")).result(copy._context)
    end

    def content(key)
      text = File.read("content/en/#{key}.md")
      Kramdown::Document.new(text).to_html
    end

    def images(glob)
      Dir[glob].sort.each.map do |filepath|
        thumb = File.dirname(filepath) + '/thumb/' + File.basename(filepath)
        size = FastImage.size(filepath)
        {
          basename: File.basename(filepath),
          path: '/' + filepath,
          thumb: '/' + thumb,
          width: size[0],
          height: size[1]
        }
      end
    end

    def blog_posts
      results = []
      Dir['pages/blog/*.md'].each do |page|
        result = renderer.render_page(
          page.gsub(/\.md$/, '.html'),
          page.gsub(%r{^pages/}, '')
        )
        is_draft = !result.meta[:draft].nil?

        if feature? :preview
          results << result
        elsif !is_draft
          results << result
        end
      end
      results.sort_by { |p| Date.parse(p.meta[:date]) }.reverse
    end

    def t(key, values = {})
      file = File.join('content', 'translations.yml')
      result = YAML.safe_load(File.read(file))['en']
      key.split('.').each do |k|
        result = result.fetch(k, nil)
        raise "Can't find translation key: #{key}" if result.nil?
      end
      if values.empty?
        result
      else
        result % values
      end
    end

    def data(key)
      nodes = key.split('.')
      filename = nodes.shift
      file = File.join 'data', filename + '.json'
      result = JSON.parse File.read(file), symbolize_names: true
      nodes.each do |k|
        result = result.fetch(k.to_sym)
      end
      result
    end

    def feature?(type)
      ENV.fetch("FEATURE_#{type.to_s.upcase}", false)
    end

    def _context
      binding
    end

    def encode(string)
      URI::encode string
    end
  end
end

class Renderer
  class TemplateValues < Values
    attr_reader :main, :meta

    def initialize(url, file, main, meta = {})
      super url, file
      @main = main
      @meta = meta
    end

    def is_blog_post?
      file.start_with?('/blog/', 'blog/') && file.end_with?('md')
    end

    def is_event?
      file.start_with?('/events/', 'events/')
    end

    def is_talk_details?
      file.match(%r{speakies/[a-zA-Z0-9_]+\.html\.erb$})
    end

    def is_landing_page?
      url.empty? || url == 'index.html' || url == '/index.html' || url == '/'
    end

    def filename
      File.basename file
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
