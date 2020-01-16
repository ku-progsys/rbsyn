module SynHelper
  include TypeOperations

  def generate(seed_hole, preconds, args, postconds, return_all=false)
    correct_progs = []

    work_list = [seed_hole]
    until work_list.empty?
      ast = work_list.shift
      pass1 = ExpandHolePass.new @ctx
      expanded = pass1.process(ast)
      expand_map = pass1.expand_map.map { |i| i.times.to_a }
      generated_asts = expand_map[0].product(*expand_map[1..]).map { |selection|
        pass2 = ExtractASTPass.new(selection)
        pass2.process(expanded)
      }

      # puts generated_asts

      evaluable = generated_asts.reject { |ast| NoHolePass.has_hole? ast }
      reasons = {}
      evaluable.each { |ast|
        test_outputs = preconds.zip(args, postconds).map { |precond, arg, postcond|
          res, klass = eval_ast(@ctx, ast, arg, precond) rescue next
          begin
            klass.instance_exec res, &postcond
          rescue AssertionError => e
            passed = klass.instance_eval { puts @count }
            reasons[passed] = e
          rescue Exception
            nil
          end
        }

        if test_outputs.all?
          correct_progs << ast
          return ast unless return_all
        end
      }

      unless reasons.empty?
        highest_pass = reasons.keys.max
        # TODO: what to do with the programs where less assertions passed?
        reason = reasons[highest_pass]

        # read set of test becomes functions write set and vice versa
        write_set = reason.read_set
        read_set = reason.write_set
      end

      remainder_holes = generated_asts.select { |ast|
        NoHolePass.has_hole?(ast) &&
        ProgSizePass.prog_size(ast) <= @ctx.max_prog_size }

      # Note: Invariant here is that the last candidate in the work list is
      # always a just hole, with next possible call chain length. If the
      # work_list is empty and we have all correct programs that means we have
      # all correct programs up that length
      if !correct_progs.empty? && return_all
        return correct_progs
      end

      work_list = [*work_list, *remainder_holes]
    end
    raise RuntimeError, "No candidates found"
  end
end
