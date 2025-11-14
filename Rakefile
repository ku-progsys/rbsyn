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
  t.test_files = FileList["test/benchmark/synthetic/user_exists_benchmark.rb"]
                          # "test/benchmark/discourse/activate_benchmark.rb",
                          # "test/benchmark/gitlab/discussion_build_benchmark.rb",
                          # "test/benchmark/diaspora/user_process_invite_acceptence_benchmark.rb"]
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
  t.test_files = FileList[#"test/benchmark/noTypes/clamp.rb",
    #'test/benchmark/noTypes/gets_num_connections.rb',
    #"test/benchmark/noTypes/sumTwo_benchmark.rb",
    #"test/benchmark/noTypes/two_specs.rb",
    #"test/benchmark/noTypes/treetest.rb",
    #"test/benchmark/noTypes/sublist.rb", # NOT WORKING WITH TYPES BUT SOLUTION REQUIRES 4 BRANCHES AND A DEPTH OF 3 MINIMUM
    #"test/benchmark/noTypes/listorder.rb", # WORKING WITH TYPES AT LEAST WITHOUT TYPES IS TAKING FOREVER AND REVEALING A """(eval):2: warning: comparison '<=' after comparison""" error
    "test/benchmark/noTypes/interleave.rb", # WORKING WITH AND WITHOUT TYPES
    #"test/benchmark/noTypes/amount_intersect.rb", # WORKING WITH AND WITHOUT TYPES
    #"test/benchmark/noTypes/ratio_intersect_union.rb"
    ]


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
  t.test_files = FileList["test/benchmark/noTypes/sumTwo_nobug.rb"]
end
                          
task :default => [] do
  Rake::Task[:typecheck].execute
  Rake::Task[:test].execute
  Rake::Task[:bench].execute
end
