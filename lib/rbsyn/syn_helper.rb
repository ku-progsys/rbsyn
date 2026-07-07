
require "pry"
require 'pry-byebug'
require 'parser/current'
require "set"
require_relative 'ast/infer_types'
require_relative 'debugger'
require_relative 'complex_error'
#require_relative "proliferate_pass"




def duplicates(list)
  t = TTypePrint.new()
  counts = Hash.new(0)
  
  list.each do |item| 
    counts[t.process(item).to_a.join(" ")] += 1
    t.reset()
  end
  counts.select { |_, n| n > 1 }
end


def test_ordering(worklist)
  is_sorted = worklist.each_cons(2).all? { |a, b| a.inferred_errors <= b.inferred_errors }
  if !is_sorted
    raise "Not sorted"
  end
end


def discard_impossible_types(generated, type)
  
  generated.select { |prog_wrap|
    prog_wrap.ttype <= type
  }
end

def read_asts(astlist)
  puts "LIST SIZE: #{astlist.size}"
  astlist.each do |i|
    puts "----------------\n"
    puts i.to_ast
    puts "TYPE: #{i.ttype}"
    puts "----------------\n"
  end
end

module SynHelper
  include TypeOperations
  
  def generate(seed_hole, preconds, postconds, return_all=false, add_dyn: false, type_search_depth: 120 )

    if add_dyn 
      ENV['ADD_DYN'] = "TRUE"
    else
      ENV['ADD_DYN'] = 'FALSE'
    end

    correct_progs = []
    work_list = [seed_hole,]
    basehashlist = []
    counter = 0

    until work_list.empty?
      # ENV["COUNT"] = (ENV["COUNT"].to_i + 1).to_s
      # if ENV["COUNT"]=="351"
      #   binding.pry
      # end
      if counter >= type_search_depth && add_dyn
        raise NameError, "done checking for types at count: #{counter}"
      end
      counter += 1
      # puts "counter: #{counter}"
      # puts counter
      work_list = work_list.sort { |a, b| comparator(a, b) }
      base = work_list.shift


      if basehashlist.include? base.typehash
        next
      end
      basehashlist << base.typehash
      effect_needed = [] 

      # if ENV["INSPECT"]=="T" && (ENV["COND"].nil? || base.to_ast.to_s == ENV["COND"])
      #   puts "COUNT: #{counter}\n"
      #   puts "BASE:\n#{base.to_ast}"
      #   # binding.pry
      # end
      # if ENV["COUNT"] == "350"
      #   binding.pry
      # end
      # binding.pry
      # if counter == 1
      #   binding.pry
      # end
      # if ENV["MAN"]=="T"
      #   puts "555555555"
      #   puts base.to_ast 
      #   puts "**********"
      #   puts base.ttype
      #   puts "%%%%%%%%%%%%"
      #   work_list.each {|i| puts i.to_ast; puts "\n----#{i.to_ast.ttype}-----\n";};
      #   binding.pry
      # end
      generated = base.build_candidates()
      evaluable = generated.reject &:has_hole?
      tempbool = false

      if ENV["INSPECT"]=="T" && (ENV["COND"].nil? || base.to_ast.to_s == ENV["COND"])
        ENV["COUNT"] = (ENV["COUNT"].to_i + 1).to_s
        File.open("test_output.txt", "a") do |f|
          f.write "\n----------------\n"
          f.write "TTYPES\n"
          generated.each do |i| f.write "#{i.to_ast.ttype}\n" end
          f.write "\nPROGS\n\n"
          f.write "LOCAL_COUNT: #{counter}\n"
          f.write "GLOBAL_COUNT: #{ENV["COUNT"]}\n\n"
          f.write "BASE_AFTER:\n#{base.to_ast}\n"
          f.write "BASETYPE: #{base.to_ast.ttype}\n"
          f.write "SIZE WORK_LIST: #{work_list.size}\n"
          f.write "SIZE generated: #{generated.size}\n"
          f.write "EVALUABLE#: #{evaluable.size}\n"
          f.write "\n-------------------------\n"
          
        end
      end
      
      evaluable.each { |prog_wrap|
        res = 1
        klass = 1
        passes = 1
        # puts "TESTING: \n#{prog_wrap.to_ast} \nof TTYPE: #{prog_wrap.to_ast.ttype}"
        #puts Unparser.unparse(prog_wrap.to_ast)
        tempbool = false

        test_outputs = preconds.zip(postconds).map { |precond, postcond|
          begin
            #arg0 << arg1.take(arg2) << arg1.drop(arg2)
            #puts Unparser.unparse(prog_wrap.to_ast)

            #debug(Unparser.unparse(prog_wrap.to_ast()), "arg0 << arg1.drop")
            # binding.pry
            res, klass = eval_ast_second(@ctx, prog_wrap.to_ast, precond)
          rescue RbSynError => err
            raise err
          rescue TypeError => err
            tempbool = true
            break
          rescue StandardError => err
            tempbool = true
            next
          rescue ComplexError => err
            tempbool = true
            next
          rescue SyntaxError => err
            # really this shouldn't happen, our generator shouldn't be attempting to create ill formed formulae, but right now I don't have a workaround for some ad hoc constructs.  
            tempbool = true
            next
          end

          begin
            klass.instance_eval {
              @params = postcond.parameters.map &:last
            }
            passes = klass.instance_exec res, &postcond
           
            passes

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
          rescue ComplexError => e 
            next
          end
          
        }
        #BLOCK END

        
        if tempbool
          # type error encountered in a complete program, we should not add back to the worklist
          next
        end
        # passes all tests
        #debug(Unparser.unparse(prog_wrap.to_ast), "arg1.take(arg2)")
        if test_outputs.all? true && !add_dyn
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
      
      newsuccess = @ctx.type_info.newsuccess
      newerror = @ctx.type_info.newerror
      newtypes = @ctx.type_info.get_reset_newtypes

      # if newsuccess
      #   work_list.map {|prog_wrap|
      #     proliferate = Proliferate.new(newtypes, @ctx.moi)
      #     x = proliferate(prog_wrap, newtypes, godelhash)} 
      #     work_list.concat(Array(x)) unless x.nil?
      # end

      if newsuccess
        work_list.map {|prog_wrap|
          prog_wrap.inferred_errors, prog_wrap.dynamic_components = @ctx.type_info.check_errors(prog_wrap)
        }
      end

      remainder_holes.map {|prog_wrap|
        prog_wrap.inferred_errors, prog_wrap.dynamic_components = @ctx.type_info.check_errors(prog_wrap)
      }
 
      remainder_holes.push(*effect_needed)


      # Note: Invariant here is that the last candidate in the work list is
      # always a just hole, with next possible call chain length. If the
      # work_list is empty and we have all correct programs that means we have
      # all correct programs up that length
      if !correct_progs.empty? && return_all && !add_dyn
        return correct_progs
      end
      
      work_list = [*work_list, *remainder_holes].sort { |a, b| comparator(a, b) }
#      test_ordering(work_list)
      work_list
    end
    log = "Type Sucesses"
    @ctx.type_info.type_successes.each {|i, j| 
      j.each { |k|  
        log = log + "\n--- #{@ctx.type_info.type_to_s(k)}"
      }
    }
    log2 = "Type Failures"
    @ctx.type_info.type_errs.each do |i, j|
      j.each { |k|
        log2 = log2 + "\n--- #{@ctx.type_info.type_to_s(k)}"
      }
    end

    raise RbSynError, "No candidates found" + "\n\n" + log + "\n\n" + log2 + "\n\n"

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
          if a.dynamic_components < b.dynamic_components
            1
          elsif a.dynamic_components > b.dynamic_components
            -1
          elsif a.dynamic_components == b.dynamic_components
            if a.ttype == @ctx.functype.ret
              -1
            elsif b.ttype == @ctx.functype.ret
              1
            else
              0
            end
          end
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
