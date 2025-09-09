require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.libs << "models"
  t.test_files = FileList["test/unit/*_test.rb"]
end

Rake::TestTask.new(:bench) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.libs << "models"
  t.test_files = FileList["test/benchmark/**/*_benchmark.rb"]
end

Rake::TestTask.new(:smallbench) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.libs << "models"
  t.test_files = FileList["test/benchmark/synthetic/user_exists_benchmark.rb",
                          "test/benchmark/discourse/activate_benchmark.rb",
                          "test/benchmark/gitlab/discussion_build_benchmark.rb",
                          "test/benchmark/diaspora/user_process_invite_acceptence_benchmark.rb"]
end

Rake::TestTask.new(:typecheck) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.libs << "models"
  t.test_files = FileList["test/typecheck.rb"]
end

Rake::TestTask.new(:notypes) do |t|

  t.libs << "test"
  t.libs << "lib"
  t.libs << "models"
  t.test_files = FileList["test/benchmark/noTypes/sumTwo_benchmark.rb"]

end

Rake::TestTask.new(:twospecs) do |t|

  t.libs << "test"
  t.libs << "lib"
  t.libs << "models"
  t.test_files = FileList["test/benchmark/noTypes/two_specs.rb"]

end


Rake::TestTask.new(:notypes_nobug) do |t|

  t.libs << "test"
  t.libs << "lib"
  t.libs << "models"
  t.test_files = FileList["test/benchmark/noTypes/sumTwo_nobug.rb"]
end
                          
task :default => [] do
  Rake::Task[:typecheck].execute
  Rake::Task[:test].execute
  Rake::Task[:bench].execute
end
