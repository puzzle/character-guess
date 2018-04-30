require 'pry'
require_relative 'lib/api'

desc 'Starts a repl console and requires the gem'
task :console do
  Pry.start
end

desc 'Remove downloaded api files'
task :clear do
  Dir.glob('public/*/').each do |dir|
    sh "rm -rf #{dir}"
  end
end

namespace :pull do
  %w(people vehicles starships).each do |api|
    desc "Pull down #{api}"
    task api do
      Api.new(api).pull
    end
  end
end

task :default => [:console]
