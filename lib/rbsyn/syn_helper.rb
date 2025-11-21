
require "pry"
require 'pry-byebug'
require 'parser/current'
require "set"
require_relative 'ast/infer_types'


def debug(var, *conds) 
  
  if ENV['DEBUG'] == 'SILENCE'
    return
  end

  
  
  if conds.all? {|m| var.include?(m)}
    if ENV['DEBUGFILES'] == "T"
      puts __FILE__
    end
    puts "DEBUG NOTICE # #{ENV['COUNTER']}\n"
    ENV['COUNTER'] = (ENV['COUNTER'].to_i + 1).to_s
    puts var
    binding.pry
  end
end

def test_ordering(worklist)
  is_sorted = worklist.each_cons(2).all? { |a, b| a.inferred_errors <= b.inferred_errors }
  if !is_sorted
    raise "Not sorted"
  end
end

module SynHelper
  include TypeOperations
  
  def generate(seed_hole, preconds, postconds, return_all=false)
    #puts "\n\n\n------------------------------\n\n\n"
    correct_progs = []
    work_list = [seed_hole]

    until work_list.empty?
      work_list = work_list.sort { |a, b| comparator(a, b) }
      base = work_list.shift
      effect_needed = []  

      generated = base.build_candidates()
      evaluable = generated.reject &:has_hole?

      tempbool = false
      
      puts base.to_ast
      puts "{{{{{{{{{{{}}}}}}}}}}}"

      evaluable.each { |prog_wrap|
        puts Unparser.unparse(prog_wrap.to_ast)
        tempbool = false

        test_outputs = preconds.zip(postconds).map { |precond, postcond|
          begin
            
            res, klass = eval_ast_second(@ctx, prog_wrap.to_ast, precond)
          rescue RbSynError => err
            raise err
          rescue TypeError => err
            tempbool = true
            break
          rescue StandardError => err
            tempbool = true
            next
          end

          begin
            klass.instance_eval {
              @params = postcond.parameters.map &:last
            }
            x = klass.instance_exec res, &postcond
            #debug((Unparser.unparse(prog_wrap.to_ast)), "+")
            x

          rescue AssertionError => e
            orig_prog = prog_wrap.dup
            prog_wrap.passed_asserts = e.passed_count
            prog_wrap.look_for(:effect, e.read_set)
            effect_needed << prog_wrap

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

        debug(Unparser.unparse(prog_wrap.to_ast), "new")
        
        if tempbool
          # type error encountered, we should not add to the worklist
          next
        end
        # passes all tests
        if test_outputs.all? true
            #puts "correct program \n#{format_ast(prog_wrap.to_ast)}"

            correct_progs << prog_wrap
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
        prog_wrap.inferred_errors = @ctx.type_info.check_errors(prog_wrap)
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
#      test_ordering(work_list)
      work_list
    end
    raise RbSynError, "No candidates found"
  end

  def comparator(a, b)

    if a.inferred_errors > b.inferred_errors
      1
    elsif a.inferred_errors == b.inferred_errors


      if a.passed_asserts < b.passed_asserts
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


    else
      -1
    end
  end

end
