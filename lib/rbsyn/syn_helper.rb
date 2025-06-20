require 'parser/current'
module SynHelper
  include TypeOperations

  def traverse_and_check(ast, klass, mthd, *argtypes)


    if ast.children.size == 0
      return true
    end
    thisklass = nil
    thismthd = nil
    
    aargs = []
    targs = []
    if ast.type == :send
      thisklass = ast.children[0]
        if thisklass.type == :send
          thisklass = ast.children[0] 
        end
    else
      thisklass = ast.children[0]
    end

    if ast.children.size == 1
      return true
    end

    ast.children[1 ...].each do |i|

      if i.class == TypedNode

        targs.append(i.ttype)
      else
        thismthd = i
      end
    end

    if thismthd == mthd
      if thisklass.ttype.to_s == klass.to_s && argtypes.size == targs.size

        (0..targs.size).each do |i|

          if targs[i].to_s != argtypes[i].to_s

            return false
            
          end 
        end

        if thisklass.children.size > 1
          if ! traverse_and_check(thisklass, klass, mthd, *argtypes)

            return false
          end
        end
        aargs.each do |i|
          if i.children.size > 1
            if ! traverse_and_check(i, klass, mthd, *argtypes)

             return false
            end
          end
        end
        return true
      else

        return false
        
      end

    else
      return true
    end

  end

  def generate(seed_hole, preconds, postconds, return_all=false)
    correct_progs = []

    work_list = [seed_hole]
    until work_list.empty?
      base = work_list.shift
      effect_needed = []
      generated = base.build_candidates
      evaluable = generated.reject &:has_hole?
      flag = false
      counterbad =0
      countergood = 0
      evaluable.each { |prog_wrap|
        test_outputs = preconds.zip(postconds).map { |precond, postcond|
          begin

            if flag
              puts "Now testing: #{Unparser.unparse(prog_wrap.to_ast)} for censored type."
              temp = traverse_and_check( prog_wrap.to_ast, :Integer, :+, :Integer)
              if ! temp
                puts "bad example removed: #{Unparser.unparse(prog_wrap.to_ast)}\n\n"
                counterbad += 1
                next
              else
                puts "is fine: #{Unparser.unparse(prog_wrap.to_ast)}\n\n"
                countergood += 1
              end
            end
            

            res, klass = eval_ast(@ctx, prog_wrap.to_ast, precond)
          rescue RbSynError => err
            raise err
          rescue StandardError => err
            puts "StandardError for prog: #{Unparser.unparse(prog_wrap.to_ast)}"
            puts "Error raised was: #{err}\n\n"
            puts "Correcting Type For further iterations (Stub for now)"
            counterbad += 1
            RDL.remove_type :BasicObject, :+
            RDL.type :BasicObject, :+, "(Integer) -> Integer"
            flag = true

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
          puts "Number of ill typed dynamic programs removed: #{counterbad} out of #{countergood + counterbad} tested"
          correct_progs << prog_wrap
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
    end
    raise RbSynError, "No candidates found"
  end

  def comparator(a, b)
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
  end
end
