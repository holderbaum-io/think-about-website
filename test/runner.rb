require 'minitest/autorun'

Dir.glob('./test/*_test.rb').each { |file| require file }
