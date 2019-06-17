require 'uri'

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
    true
  end

  def is_event?
    true
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
