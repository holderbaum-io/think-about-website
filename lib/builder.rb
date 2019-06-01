require 'renderer'
require 'fileutils'

class Builder
  def initialize(source_dir, target_dir)
    @source_dir = source_dir
    @target_dir = target_dir
    @renderer = Renderer.new(@source_dir)
  end

  def run
    Dir['pages/**/*'].each do |page|
      next if page.start_with? 'pages/blog'
      next if File.directory? page
      build_page File.join(@target_dir), page
    end

    Dir['pages/blog/*'].each do |page|
      next if File.directory? page
      build_page @target_dir, page.gsub(/\.md$/, '.html')
    end

    FileUtils.cp_r(File.join(@source_dir, 'assets'), @target_dir)
  end

  private

  def build_page(target_dir, page)
    file = page.gsub(/\.erb$/, '').gsub(%r{^pages/}, '')
    file = '' if file == 'index.html'
    result = @renderer.render(file)
    target_path = File.join(target_dir, result.filename)
    FileUtils.mkdir_p(File.dirname(target_path))
    File.write(target_path, result.content)
  end
end
