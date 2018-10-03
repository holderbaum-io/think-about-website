$LOAD_PATH.unshift(File.expand_path(File.join('..', 'lib'), __dir__))
require 'builder'
require 'fileutils'

source_dir = Dir.pwd
target_dir = File.join(Dir.pwd, 'result')
FileUtils.mkdir_p target_dir

builder = Builder.new(source_dir, target_dir)
builder.run
