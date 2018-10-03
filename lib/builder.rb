require 'renderer'
require 'fileutils'

class Builder
  def initialize(source_dir, target_dir)
    @source_dir = source_dir
    @target_dir = target_dir
  end

  def run
    renderer = Renderer.new(@source_dir)
    languages = %w[en de]

    languages.each do |lang|
      Dir['pages/**'].each do |page|
        file = page.gsub(/\.erb$/, '').gsub(%r{^pages/}, '')
        result = renderer.render(lang, file)
        target_path = File.join(@target_dir, lang, result.filename)
        FileUtils.mkdir_p(File.dirname(target_path))
        File.write(target_path, result.content)
      end
    end

    FileUtils.cp_r(File.join(@source_dir, 'assets'), @target_dir)
  end
end
