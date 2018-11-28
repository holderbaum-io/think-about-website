require 'renderer'
require 'fileutils'

class Builder
  def initialize(source_dir, target_dir)
    @source_dir = source_dir
    @target_dir = target_dir
    @renderer = Renderer.new(@source_dir)
  end

  def run
    languages = %w[en de]

    languages.each do |lang|
      Dir['pages/*'].each do |page|
        next if File.directory? page
        build_page File.join(@target_dir, lang), lang, page
      end
    end

    Dir['pages/blog/*'].each do |page|
      next if File.directory? page
      build_page @target_dir, 'en', page.gsub(/\.md$/, '.html')
    end

    FileUtils.cp_r(File.join(@source_dir, 'assets'), @target_dir)
  end

  private

  def build_page(target_dir, lang, page)
    file = page.gsub(/\.erb$/, '').gsub(%r{^pages/}, '')
    file = '' if file == 'index.html'
    result = @renderer.render(lang, file)
    target_path = File.join(target_dir, result.filename)
    FileUtils.mkdir_p(File.dirname(target_path))
    File.write(target_path, result.content)
  end
end
