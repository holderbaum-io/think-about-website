require 'uri'
require 'fastimage'
require 'yaml'

# Activate and configure extensions
# https://middlemanapp.com/advanced/configuration/#configuring-extensions

activate :autoprefixer do |prefix|
  prefix.browsers = 'last 2 versions'
end

# Layouts
# https://middlemanapp.com/basics/layouts/

# Per-page layout changes
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

# With alternative layout
# page '/path/to/file.html', layout: 'other_layout'

# Proxy pages
# https://middlemanapp.com/advanced/dynamic-pages/

schedule = File.read 'data/events/2019/schedule.json'
JSON.parse(schedule, symbolize_names: true).each do |_day, talks|
  talks.each do |talk|
    slug = talk[:person_slug]
    next if slug.nil?
    proxy("/events/2019/speakies/#{slug}.html",
          '/events/2019/speakies/template.html',
          locals: { talk: talk },
          ignore: true)
  end
end

# proxy(
#   '/this-page-has-no-template.html',
#   '/template-file.html',
#   locals: {
#     which_fake_page: 'Rendering a fake page with a local variable'
#   },
# )

# Helpers
# Methods defined in the helpers block are available in templates
# https://middlemanapp.com/basics/helper-methods/

helpers do
  def is_landing_page?
    current_page.url == '/'
  end

  def is_event?
    current_page.url =~ %r{^/events/.+\.html}
  end

  def encode(string)
    URI::encode string
  end

  def blogdate(article)
    article.date.strftime('%b %d')
  end

  def blogimg(article)
    "/images/blog/#{article.slug}/header.png"
  end

  def social_url(article)
    'https://' + social_domain + article.url
  end

  def social_img(article)
    'https://' + social_domain + blogimg(article)
  end

  def social_domain
    'think-about.io'
  end

  def images(glob)
    captions = YAML.safe_load(File.read('data/captions.yaml'))
    Dir[glob].sort.each.map do |filepath|
      caption = captions.fetch filepath, ''
      path = filepath.gsub(/^source/, '')
      thumb = File.dirname(path) + '/thumb/' + File.basename(filepath)
      size = FastImage.size(filepath)
      {
        basename: File.basename(path),
        path:  path,
        thumb: thumb,
        caption: caption,
        width: size[0],
        height: size[1]
      }
    end
  end

  def markdown(text)
    Kramdown::Document.new(text).to_html
  end
end

activate :blog do |blog|
  blog.prefix = 'blog'
  # blog.sources = 'articles/{year}-{month}-{day}-{title}.html.markdown'
  blog.permalink = '{title}.html'
  blog.layout = 'article'
end

# Build-specific configuration
# https://middlemanapp.com/advanced/configuration/#environment-specific-settings

configure :build do
  activate :minify_css
  activate :minify_javascript
end
