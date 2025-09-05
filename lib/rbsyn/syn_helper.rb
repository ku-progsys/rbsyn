def log(int)
  puts "Here location #{int}"
end


require 'parser/current'
require "set"
module SynHelper
  include TypeOperations
  #require_relative 'error_assess'
  #require_relative 'ast/check_error_pass'
  #require_relative 'ast/infer_correct_types'
  require_relative 'ast/infer_types'
  


  def generate(seed_hole, preconds, postconds, return_all=false)

    
    
    #Methods of interest MOI
    moi = [:+,] #BR <<< methods of interest hard coded for now. 

    type_info = InferTypes.new(moi)

    #hash of possible types and restrictions over methods of interest (MOI)

    correct_progs = []
    work_list = [seed_hole]

    until work_list.empty?

      base = work_list.shift

      effect_needed = []  

=begin
      if ENV["bug"] == "true"
        puts "\npopped: \n#{base.to_ast}\nof correctness level: #{base.inferred_errors}"
        puts "worklist size: #{work_list.size}"


        if base.to_ast.to_s == "(send\n  (int 0) :!)"
          #work_list = work_list.sort { |a, b| comparator(a, b) }
          until work_list.empty?
            k = work_list.shift
            puts "inferr: #{k.inferred_errors}"
          end
        end

        work_list.each {|i| 
          
          if i.inferred_errors < 10000
            puts "errs: #{i.inferred_errors}"
            puts i.to_ast
          end
        }

      end
=end

      generated = base.build_candidates()
      #puts "---------------------------"
      evaluable = generated.reject &:has_hole?

      evaluable.each { |prog_wrap|
   
        #BLOCK BEGIN
        test_outputs = preconds.zip(postconds).map { |precond, postcond|
          begin
            res, klass = eval_ast_second(@ctx, prog_wrap.to_ast, precond, type_info)

          rescue RbSynError => err

            raise err
          rescue TypeError => err

            next
          rescue StandardError => err

            next
          end

          begin
            klass.instance_eval {
              @params = postcond.parameters.map &:last
            }
            klass.instance_exec res, &postcond
          rescue AssertionError => e
            orig_prog = prog_wrap.dup
            prog_wrap.passed_asserts = e.passed_count
            prog_wrap.look_for(:effect, e.read_set)
            effect_needed << prog_wrap

            # also possible failure from the residual read effect
            if orig_prog.looking_for == :teffect && !(orig_prog.target.size == 1 || orig_prog.target[0] == '')
              orig_prog.passed_asserts = e.passed_count
              orig_prog.look_for(:teffect, orig_prog.target)
              effect_needed << orig_prog
            end

          rescue RbSynError => e

            raise e
          rescue StandardError => e
            next
          end
          
        }
        #BLOCK END

        # passes all tests
        if test_outputs.all? true
          #puts "Number of ill typed dynamic programs removed: #{counterbad} out of #{countergood + counterbad} tested"
          correct_progs << prog_wrap

          #puts "SLN FOUND!!!: #{prog_wrap.to_ast}\n with return type: #{prog_wrap.to_ast.ttype}\n\n"
          puts "CORRECT TYPES: "

          #prog_wrap.expression = prog_wrap.to_ast.updated(:Integer)
          #puts "new type :#{prog_wrap.ctx.tenv}"
          
          type_info.type_successes.each {|i, j| 

            j.each { |k|
          
            puts "\n-----------------------\n#{type_info.type_to_s(k)}\n-------------------------\n"

            }
          
          }
          puts  "\n--------------------------------\nRESTRICTED TYPES:\n\n"
          

          type_info.type_errs.each do |i, j|
            j.each { |k|
              puts "--------------------\n#{type_info.type_to_s(k)}\n--------------------"
            }
          end
          puts "\n\n"

          return prog_wrap unless return_all
        elsif ENV.key? 'DISABLE_EFFECTS'

          prog_wrap.passed_asserts = 0
          prog_wrap.inferred_errors = 10000 #BR This is my addition this 
          prog_wrap.look_for(:effect, ['*'])
          effect_needed << prog_wrap

        end

      }
      # done evaluating complete programs

      remainder_holes = generated.select { |prog_wrap|
        prog_wrap.has_hole? &&
        prog_wrap.prog_size <= @ctx.max_prog_size 
        
      }

      remainder_holes.map {|prog_wrap|
        prog_wrap.inferred_errors = type_info.check_errors(prog_wrap)
      }

      remainder_holes.push(*effect_needed)


      # Note: Invariant here is that the last candidate in the work list is
      # always a just hole, with next possible call chain length. If the
      # work_list is empty and we have all correct programs that means we have
      # all correct programs up that length
      if !correct_progs.empty? && return_all
        return correct_progs
      end

      work_list = [*work_list, *remainder_holes].sort { |a, b| comparator(a, b) }
      #work_list = work_list.sort { |a, b| comparator(a, b) }
      #puts "\n\nworklist" 
      #work_list.each do |i|
      #  puts i.to_ast
      #end

      #puts work_list.map {|i| ["solved: #{i.passed_asserts}", "size: #{i.prog_size}", "suspect: #{i.inferred_errors}"]}
      work_list
    end
    raise RbSynError, "No candidates found"
  end

  def comparator(a, b)

    if a.inferred_errors > b.inferred_errors
      1
    elsif a.inferred_errors < b.inferred_errors
      -1
    elsif a.passed_asserts < b.passed_asserts
      1
    elsif a.passed_asserts == b.passed_asserts
      if a.prog_size < b.prog_size
        -1
      elsif a.prog_size == b.prog_size
        0
      else
        1
      end
    else
      -1
    end
  end

end
