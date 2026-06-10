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
    "test/benchmark/noTypes/ratio_intersect_union.rb" # WORKING WITH TYPES TIMING OUT WITHOUT TYPES, FOLLOWUP NEEDED
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
  t.test_files = FileList["test/benchmark/noTypes/interleave.rb",
                          #"test/benchmark/noTypes/clamp.rb"
                          ] 
end

Rake::TestTask.new(:chunkypngcolor) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.libs << "models"
  t.test_files = FileList[
    #NOT YET WORKING WITH TYPES
    #"test/benchmark/colorBenchmarks/benchmarks/parse.rb",
    #"test/benchmark/colorBenchmarks/benchmarks/pass_bytesize.rb",
      "test/benchmark/colorBenchmarks/benchmarks/to_hex.rb"
    #WORKING WITH TYPES
    

  ]
end


Rake::TestTask.new(:mastadon) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.libs << "models"
  t.test_files = FileList[

    #"test/benchmark/mastadon/generated_spec/spec/models/concerns/account/counters_synthesis_spec.rb", # needs ability to do assignment to run. 
    # "test/benchmark/mastadon/generated_spec/spec/email_domain_blocks_benchmarks/list_function.rb", # AI GENERATED NEED TO CORRECT this one needs helper functions because it is a looping program, dont use right now. 
    #"test/benchmark/mastadon/generated_spec/spec/email_domain_blocks_benchmarks/add_function.rb", # AI GENERATED NEED TO CORRECT again requires list operations so may not be worth it. It may be worthwhile to generate tests based soley on the internals of the loops themselves though. 
    #"test/benchmark/mastadon/generated_spec/spec/email_domain_blocks_benchmarks/remove_function.rb", # AI GENERATED NEED TO CORRECT NEED skip this one needs a helper and list operations so may not be worth it. 
  ]
end


Rake::TestTask.new(:hamster) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.libs << "models"
  t.test_files = FileList[
                           #"test/benchmark/githubBenchmarks/split_at_benchmark.rb", #WORKING WITH TYPES AND WITHOUT TYPES
                           
                           #"test/benchmark/githubBenchmarks/set_delete.rb" #WORKING WITH TYPES #WORKING WITHOUT TYPES, UNSURE OF HELP OF MY SYSTEM
                           
                           #"test/benchmark/githubBenchmarks/hash_clear_benchmark.rb", # WORKING WITH TYPES, WORKING WITHOUT TYPES IF! WE DON'T IGNORE TYPE CHECK FOR RESPOND TO. BECUASE IN THIS CASE THE INSTANCE OF A TYPE MIGHT RESPOND TO BUT THE GENERIC TYPE DOESN'T
                           
                           #"test/benchmark/githubBenchmarks/hash_values_benchmark.rb", # WORKING WITH TYPES #WORKING WITHOUT TYPES, BUT THE TYPE INFERENCE DOESN'T REALLY ADD VALUE FOR THIS BENCHMARK 48 ITER TO FIND RELEVANT TYPES, 55 TO FIND SOLUTION NAIVELY
                           
                           #"test/benchmark/githubBenchmarks/hash_eql_benchmark.rb", # WORKING WITH TYPES, WORKING WITHOUT TYPES
                           
                           #"test/benchmark/githubBenchmarks/hash_get_benchmark.rb", # WORKING WITH TYPES, WORKING WITHOUT TYPES IF! WE DONT IGNORE RESPOND TO CHECK 
                           
                           #"test/benchmark/githubBenchmarks/hash_delete_benchmark.rb", # WORKING WITH TYPES, WORKING WITHOUT TYPES
                           
                           #"test/benchmark/githubBenchmarks/span_benchmark.rb", #VERY DIFFICULT ONE MIGHT NEED ASSISTANCE FORCING ASSIGNMENT OPERATIONS TO GET IT TO WORK
                           
                           #"test/benchmark/githubBenchmarks/partition_benchmark.rb", #THIS ONE LOOKS RATHER SIMILAR TO THE SPAN BENCHMARK
                           
                           "test/benchmark/githubBenchmarks/rotate_benchmark.rb", # WORKING WITH TYPES, NOT WORKING WITHOUT TYPES, THIS ONE MIGHT BE A GOOD DEMONSTRATION OF THE VALUE OF DEPENDENT TYPES, AS [].take(NONNUMERIC) WILL NEVER THROW AN ERROR BUT A FILLED LIST WILL.

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
