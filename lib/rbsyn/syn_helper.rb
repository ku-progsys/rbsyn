
require "pry"
require 'pry-byebug'
require 'parser/current'
require "set"
require_relative 'ast/infer_types'

def test_ordering(worklist)
  is_sorted = worklist.each_cons(2).all? { |a, b| a.inferred_errors <= b.inferred_errors }
  if !is_sorted
    raise "Not sorted"
  end
end

module SynHelper
  include TypeOperations
  
  
  def generate(seed_hole, preconds, postconds, return_all=false)


    correct_progs = []
    work_list = [seed_hole]
#   templist = []
    until work_list.empty?
      work_list = work_list.sort { |a, b| comparator(a, b) }

      base = work_list.shift
      #binding.pry
      effect_needed = []  

      generated = base.build_candidates()
      
      evaluable = generated.reject &:has_hole?
      tempbool = false

      evaluable.each { |prog_wrap|
        tempbool = false
        #BLOCK BEGIN
        test_outputs = preconds.zip(postconds).map { |precond, postcond|
          begin
            res, klass = eval_ast_second(@ctx, prog_wrap.to_ast, precond)

            if ENV["TESTON"] == '1'
              resparen, klassparen = eval_ast(@ctx, prog_wrap.to_ast, precond)
            
              if resparen != res
                raise TestException.new("AST interpretation methods not the same:\n
                Output with tracking AST: #{resparen}\n Output without tracking AST #{res}\n
                Non-Parenthesized AST:\n#{prog_wrap.to_ast}\n")
              end

            end
          rescue RbSynError => err
            raise err
          rescue TypeError => err
#           templist.append(prog_wrap)
            tempbool = true
            break
          rescue StandardError => err
            #templist.append(prog_wrap)
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

            if orig_prog.looking_for == :teffect && !(orig_prog.target.size == 1 || orig_prog.target[0] == '')
              orig_prog.passed_asserts = e.passed_count
              orig_prog.look_for(:teffect, orig_prog.target)
              effect_needed << orig_prog
            end

          rescue RbSynError => e
            raise e

          rescue StandardError => e
            #templist.append(prog_wrap)
            next
          end
          
        }
        #BLOCK END
        if tempbool
          #type error encountered this expression should not be added back into the worklist for 
          #further effect expansions. 
          next
        end
        # passes all tests
        if test_outputs.all? true
          correct_progs << prog_wrap
          return prog_wrap unless return_all

        elsif ENV.key? 'DISABLE_EFFECTS'
          prog_wrap.passed_asserts = 0
          prog_wrap.inferred_errors = 10000 #BR This is my addition this 
          prog_wrap.look_for(:effect, ['*'])
#          if templist.include?(prog_wrap)
#             raise "Program with type error getting into worklist"
#          end
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
