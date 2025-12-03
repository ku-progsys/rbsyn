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
    "test/benchmark/noTypes/sumTwo_benchmark.rb",
    #"test/benchmark/noTypes/two_specs.rb",
    #"test/benchmark/noTypes/treetest.rb", 
    #"test/benchmark/noTypes/sublist.rb", # SOLUTION REQUIRES 4 BRANCHES AND A DEPTH OF 3 MINIMUM WILL NEED LONGER TESTING TO DETERMINE SUCCESS.
    #"test/benchmark/noTypes/listorder.rb", # WORKING WITH AND WITHOUT TYPES: WARNING """(eval):2: warning: comparison '<=' after comparison""" error: NEED TO SEE IF THERE IS A WAY TO PREVENT THING <= THING <= THING DURING 
    #"test/benchmark/noTypes/interleave.rb", # WORKING WITH AND WITHOUT TYPES
    #"test/benchmark/noTypes/amount_intersect.rb", # WORKING WITH AND WITHOUT TYPES
    #"test/benchmark/noTypes/ratio_intersect_union.rb" # WORKING WITH TYPES TIMING OUT WITHOUT TYPES, FOLLOWUP NEEDED
    ]


end

Rake::TestTask.new(:githubBenchmarks) do |t|

  t.libs << "test"
  t.libs << "lib"
  t.libs << "models"
  t.test_files = FileList["test/benchmark/githubBenchmarks/curry_guards.rb"
    ]

end

Rake::TestTask.new(:twospecs) do |t|

  t.libs << "test"
  t.libs << "lib"
  t.libs << "models"
  t.test_files = FileList["test/benchmark/noTypes/two_specs.rb"] 
end


Rake::TestTask.new(:hamster) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.libs << "models"
  t.test_files = FileList[
                           "test/benchmark/githubBenchmarks/split_at_benchmark.rb", #WORKING WITH TYPES THIS ONE REVEALS SOME ERROR WITH THE TYPE INFERENCE SYSTEM
                           #"test/benchmark/githubBenchmarks/set_delete.rb" #WORKING WITH TYPES
                           #"test/benchmark/githubBenchmarks/hash_clear_benchmark.rb", # WORKING WITH TYPES
                           #"test/benchmark/githubBenchmarks/hash_values_benchmark.rb", # WORKING WITH TYPES 
                           #"test/benchmark/githubBenchmarks/hash_eql_benchmark.rb", # WORKING WITH TYPES
                           #"test/benchmark/githubBenchmarks/hash_get_benchmark.rb", # WORKING WITH TYPES
                           #"test/benchmark/githubBenchmarks/hash_delete_benchmark.rb", # WORKING WITH TYPES



                           #"test/benchmark/githubBenchmarks/span_benchmark.rb", #VERY DIFFICULT ONE MIGHT NEED ASSISTANCE FORCING ASSIGNMENT OPERATIONS TO GET IT TO WORK
                           #"test/benchmark/githubBenchmarks/partition_benchmark.rb", #THIS ONE LOOKS RATHER SIMILAR TO THE SPAN BENCHMARK
                           #"test/benchmark/githubBenchmarks/rotate_benchmark.rb", # NOT YET WORKING WITH TYPES LIKELY TOO LARGE OF A SPEC

                          ]
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
