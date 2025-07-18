require 'parser/current'
require "set"
module SynHelper
  include TypeOperations
  require_relative 'error_assess'
  require_relative 'ast/check_error_pass'

  def generate(seed_hole, preconds, postconds, return_all=false)
    
    tenvdict = @ctx.tenv.map {|k, v|
      [k, v.name.to_sym]
    }.to_h

    suspect_types = Set.new
    correct_progs = []

    work_list = [seed_hole]
    until work_list.empty?
      base = work_list.shift
      effect_needed = []
      generated = base.build_candidates

      generated.each do |i| # this should be done in the generate section instead

        pass = CheckErrorPass.new(suspect_types)
        pass.process(i)
        if pass.contains_type
          i.type_suspect += 1
        end
        
      end

      evaluable = generated.reject &:has_hole?
      #counterbad =0
      #countergood = 0

      evaluable.each { |prog_wrap|
        test_outputs = preconds.zip(postconds).map { |precond, postcond|
          begin

            res, klass = eval_ast(@ctx, prog_wrap.to_ast, precond)
          rescue RbSynError => err

            raise err
          rescue TypeError => err

            pass = CheckErrorPass.new(suspect_types) # don't want to test programs that have a known error. 
            pass.process(prog_wrap)
            
            if !pass.contains_type
              restricted_type = get_type_error(prog_wrap, err, tenvdict) #look for and get the new type error. 
              suspect_types.add(restricted_type) # add to the list of restricted types.                
                # for each of the existing partial programs, if there is a new type in the suspect types list, remove it.          
              generated.each do |i|

                if i.type_suspect < 1  # no point in updating if it already has an error THIS MIGHT BE A MISTAKE RETURN TO SEE
                  pass = CheckErrorPass.new([restricted_type])

                  pass.process(i)
                  if pass.contains_type
                    i.type_suspect += 1
                  end
                end  
              end

            end

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

        if test_outputs.all? true
          #puts "Number of ill typed dynamic programs removed: #{counterbad} out of #{countergood + counterbad} tested"
          correct_progs << prog_wrap
          puts "FOUND SOLUTION, RESTRICTED TYPES:"

          suspect_types.each do |i|
            puts "--------------------"
            puts i
            puts "--------------------"
          end


          return prog_wrap unless return_all
        elsif ENV.key? 'DISABLE_EFFECTS'
          prog_wrap.passed_asserts = 0
          prog_wrap.look_for(:effect, ['*'])
          effect_needed << prog_wrap
        end

      }


      remainder_holes = generated.select { |prog_wrap|
        prog_wrap.has_hole? &&
        prog_wrap.prog_size <= @ctx.max_prog_size }
      remainder_holes.push(*effect_needed)

      # Note: Invariant here is that the last candidate in the work list is
      # always a just hole, with next possible call chain length. If the
      # work_list is empty and we have all correct programs that means we have
      # all correct programs up that length
      if !correct_progs.empty? && return_all
        return correct_progs
      end

      work_list = [*work_list, *remainder_holes].sort { |a, b| comparator(a, b) }
      #puts work_list.map {|i| ["solved: #{i.passed_asserts}", "size: #{i.prog_size}", "suspect: #{i.type_suspect}"]}
      work_list 
    end
    raise RbSynError, "No candidates found"
  end
=begin
  def comparator(a, b)
    if a.type_suspect > b.type_suspect
      1
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
=end
  def comparator(a, b)
    #puts "comparitor"
    #puts "a: #{a.type_suspect}\nb: #{b.type_suspect}\n"
    if a.type_suspect > b.type_suspect
      #puts "reordered"
      1
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
