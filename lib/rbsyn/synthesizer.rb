COVARIANT = :+
CONTRAVARIANT = :-
TRUE_POSTCOND = Proc.new { |result| 
  result == true }

ENV['COUNTER'] = '0'
def debug(var, *conds, message: "") 
  
  if ENV['DEBUG'] == 'PRY' || ENV['DEBUG'] == 'PRINT'
    
    if conds.all? {|m|  if m.is_a?(String)
                          var.include?(m)
                        elsif m.is_a?(Regexp)
                          var.match(m)
                        else
                          false
                        end
                      }
      puts "DEBUG # #{ENV['COUNTER']} in file: #{__FILE__}\n#{message}\n"
      ENV['COUNTER'] = (ENV['COUNTER'].to_i + 1).to_s
      puts var
      puts "-----------------------\n"
      if ENV['DEBUG'] == 'PRY'
        binding.pry
      end
    end
  end
end

class Synthesizer
  # require "pry"
  # require 'pry-byebug'
  require_relative 'ast/infer_types'
  include AST
  include SynHelper
  include Utils

  def initialize(ctx)
    @ctx = ctx
    @ctx.type_info = InferTypes.new(@ctx.moi, @ctx.exclude) # type finding class
    #@type_info = InferTypes.new(@ctx.moi) # type finding class
  end

  def print_inferred_types 
    # >>> INSTRUMENTATION K2 (AI generated, remove) >>>
    if ENV["DBG_DYN"]
      RDL::Globals.info.info.each { |klass, meths|
        next if klass.include?("DynamicType")
        warn "[K2] #{klass}: #{meths.map { |m, k| "#{m}#{k[:type] ? k[:type].size.to_s + 'sig' : ''}#{k[:write] ? ' w' + k[:write].inspect : ''}#{k[:read] ? ' r' + k[:read].inspect : ''}" }.join('; ')[0, 700]}"
      }
    end
    # <<< INSTRUMENTATION K2 <<<
    log = "\nTYPE SUCCESSES\n|||||||||||||||||||||||||||||||||||||||||||||||||||||||\n"
    @ctx.type_info.type_successes.each {|i, j| 
      j.each { |k|
        log = log + "\n--- #{@ctx.type_info.type_to_s(k)}"
      }
    }
    log2 = "\nTYPE FAILURES\n|||||||||||||||||||||||||||||||||||||||||||||||||||||||\n"

    @ctx.type_info.type_errs.each do |i, j|
      j.each { |k|
        log2 = log2 + "\n--- #{@ctx.type_info.type_to_s(k)}"
      }
    end
      
    @ctx.logger.debug(log)
    @ctx.logger.debug(log2 + "\n")
    @ctx.logger.debug("|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||\n")
  end

  def run

    if ENV.key? 'EFFECT_PREC'
      eff_prec = ENV['EFFECT_PREC'].strip.to_i
    else
      eff_prec = 0
    end
    change_effect_precision(eff_prec)

    @ctx.load_tenv!
    prog_cache = ProgCache.new @ctx

    @ctx.logger.debug("MOI: #{@ctx.moi}")

    if !ENV["ITERS"].nil?
      inference_iterations = ENV["ITERS"].to_i
    else
      inference_iterations = 19
    end
    # update_types_pass = RefineTypesPass.new  # AI altered: replaced by RefineTypesV2 (same behaviour without dynamic:)
    update_types_pass = RefineTypesV2.new # AI generated
    spec_guard = SpecTypeGuard.new(@ctx) # AI generated: decides per spec whether an inference pass is needed
    spec_index = -1 # AI generated
    progconds = @ctx.preconds.zip(@ctx.postconds, @ctx.desc).map { |precond, postcond, desc|
      @ctx.logger.debug("Finding sln for subspec: #{desc}")
      spec_index += 1 # AI generated
      use_inference, guard_reasons = ENV.key?("INFERENCE_EVERY_PASS") ? [true, ["INFERENCE_EVERY_PASS set"]] : spec_guard.decide(spec_index, precond, postcond) # AI generated
      @ctx.logger.debug("Spec type guard: #{use_inference ? 'inference pass' : 'typed only'} (#{guard_reasons.join('; ')})") # AI generated
      #binding.pry
      prog = prog_cache.find_prog([precond], [postcond])
      
      if prog.nil?

        # AI altered: the block below moved into program_search (same code), which also implements the spec type guard
        # env = LocalEnvironment.new
        # prog_ref_one = env.add_expr(s(@ctx.functype.ret, :hole, 0, {variance: CONTRAVARIANT}))
        # seed = ProgWrapper.new(@ctx, s(@ctx.functype.ret, :envref, prog_ref_one), env)
        # seed.look_for(:type, @ctx.functype.ret)
        #
        #
        # if @ctx.moi != []
        #   begin
        #      
        #     @ctx.logger.debug("Inferring Types with #{inference_iterations*(@ctx.moi.size)} iterations")
        #     prog = generate(seed, [precond], [postcond], false, add_dyn: true, type_search_depth: (@ctx.moi.size)*inference_iterations) 
        #   rescue NameError => e 
        #     @ctx.logger.debug("Inference Complete")
        #     print_inferred_types()
        #     env = LocalEnvironment.new
        #     prog_ref_one = env.add_expr(s(@ctx.functype.ret, :hole, 0, {variance: CONTRAVARIANT}))
        #     seed = ProgWrapper.new(@ctx, s(@ctx.functype.ret, :envref, prog_ref_one), env)
        #     seed.look_for(:type, @ctx.functype.ret)
        #     prog = generate(seed, [precond], [postcond], false, add_dyn: false) 
        #   end
        #
        # else
        #   prog = generate(seed, [precond], [postcond], false, add_dyn: false) 
        # end
        prog = program_search(precond, postcond, inference_iterations, use_inference) # AI generated
        prog_cache.add(prog)

        @ctx.logger.debug("Synthesized program:\n#{format_ast(prog.to_ast)}")
        @ctx.logger.debug("In AST FORM: #{prog.to_ast}")
      else

        @ctx.logger.debug("Found program in cache:\n#{format_ast(prog.to_ast)}")
      end
      
      
      
      # AI altered: the block below moved into branch_search (same code), which also implements the spec type guard
      # env = LocalEnvironment.new
      # branch_ref = env.add_expr(s(RDL::Globals.types[:bool], :hole, 0, {bool_consts: false}))
      # seed = ProgWrapper.new(@ctx, s(RDL::Globals.types[:bool], :envref, branch_ref), env)
      # bool_or_any = RDL::Type::UnionType.new(RDL::Globals.types[:bool], RDL::Globals.types[:any])
      # seed.look_for(:type, bool_or_any)
      # @ctx.logger.debug("Searching for branch")
      # if @ctx.moi != []
      #   begin
      #     @ctx.logger.debug("Inferring Types for branch search with #{inference_iterations*(@ctx.moi.size)} iterations")
      #     # binding.pry
      #     branches = generate(seed, [precond], [TRUE_POSTCOND], true, add_dyn: true, type_search_depth: (@ctx.moi.size)*inference_iterations) 
      #   rescue NameError =>e 
      #     @ctx.logger.debug("Inference Complete, resuming branch search")
      #       env = LocalEnvironment.new
      #       branch_ref = env.add_expr(s(RDL::Globals.types[:bool], :hole, 0, {bool_consts: false}))
      #       seed = ProgWrapper.new(@ctx, s(RDL::Globals.types[:bool], :envref, branch_ref), env)
      #       bool_or_any = RDL::Type::UnionType.new(RDL::Globals.types[:bool], RDL::Globals.types[:any])
      #       seed.look_for(:type, bool_or_any)
      #       branches = generate(seed, [precond], [TRUE_POSTCOND], true)
      #   end
      # else
      #   @ctx.logger.debug("Searching for branch with no type inference.")
      #   branches = generate(seed, [precond], [TRUE_POSTCOND], true) 
      # end
      @ctx.logger.debug("Searching for branch") # AI generated (kept from the block above)
      branches = branch_search(precond, inference_iterations, use_inference) # AI generated
      
      cond = BoolCond.new
      branches.each { |b| warn "[BR] branch=#{b.to_ast.to_s.gsub(/\s+/, ' ')[0, 250]} ttype=#{b.to_ast.ttype}" } if ENV["DBG_DYN"] # INSTRUMENTATION BR (AI generated, remove)
      branches.each { |b| cond << update_types_pass.process(b.to_ast) }

      @ctx.logger.debug("Synthesized branch: #{format_ast(cond.to_ast)}")
      @ctx.logger.debug("\n\\\\\\\\\\\\\\\\\\\\\\\\\n\n")
      k = ProgTuple.new(@ctx, prog, cond, [precond], [postcond])
      k
    }
    @ctx.logger.debug("Initial Candidates Generated")
    #binding.pry
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
      
    @ctx.logger.debug(log)
    @ctx.logger.debug(log2 + "\n")

 
    # if there is only one generated, there is nothing to merge, we return the first synthesized program


    return progconds[0].prog if progconds.size == 1
    

    # progconds = merge_same_progs(progconds).map { |progcond| [progcond] }
    progconds.map! { |progcond| [progcond] } #in-place version of map

    # TODO: we need to merge only the program with different body
    # (same programs with different branch conditions are wasted work?)
    completed = progconds.reduce { |merged_prog, progcond| # inject and reduce are aliases if no memo object is passed the first element becomes the vairable folded over. 

      results = []
      merged_prog.each { |mp|
        
        progcond.each { |pp|

          possible = (mp + pp)

          possible.map &:prune_branches
          
          results.push(*possible)

        }
      }
      
      
      results = ELIMINATION_ORDER.inject(results) { |memo, strategy| strategy.eliminate memo }
      results.sort { |a, b| flat_comparator(a, b) }
    }

    completed.each { |progcond|

      ast = progcond.to_ast
      test_outputs = @ctx.preconds.zip(@ctx.postconds).map { |precond, postcond|
        begin

          res, klass = eval_ast(@ctx, ast, precond)

        rescue RbSynError => err
          raise err
        rescue StandardError => err
          next
        end

        begin
          klass.instance_eval { @params = postcond.parameters.map &:last }
          klass.instance_exec res, &postcond
        
        rescue AssertionError => e
          nil
        rescue RbSynError => e
          raise e
        rescue StandardError => e
          nil
        end
        
      }

      return ast if test_outputs.all? true
    }
    puts "NO CANDIDATES FOUND "


    raise RbSynError, "No candidates found"
  end

  # AI generated: fresh root holes (generate rewrites a candidate's environment while expanding it)
  def new_program_seed # AI generated
    env = LocalEnvironment.new
    prog_ref_one = env.add_expr(s(@ctx.functype.ret, :hole, 0, {variance: CONTRAVARIANT}))
    seed = ProgWrapper.new(@ctx, s(@ctx.functype.ret, :envref, prog_ref_one), env)
    seed.look_for(:type, @ctx.functype.ret)
    seed
  end

  def new_branch_seed # AI generated
    env = LocalEnvironment.new
    branch_ref = env.add_expr(s(RDL::Globals.types[:bool], :hole, 0, {bool_consts: false}))
    seed = ProgWrapper.new(@ctx, s(RDL::Globals.types[:bool], :envref, branch_ref), env)
    bool_or_any = RDL::Type::UnionType.new(RDL::Globals.types[:bool], RDL::Globals.types[:any])
    seed.look_for(:type, bool_or_any)
    seed
  end

  # AI generated: the program search from run (same code as before) plus the spec type guard. With use_inference
  # false it runs typed only, falling back to the inference path if the typed search runs out of candidates.
  def program_search(precond, postcond, inference_iterations, use_inference) # AI generated
    return generate(new_program_seed, [precond], [postcond], false, add_dyn: false) if @ctx.moi == []
    unless use_inference
      begin
        return generate(new_program_seed, [precond], [postcond], false, add_dyn: false)
      rescue RbSynError => e
        raise e unless e.message.start_with?("No candidates")
        @ctx.logger.debug("Typed-only program search ran out of candidates, falling back to an inference pass")
      end
    end
    begin
      @ctx.logger.debug("Inferring Types with #{inference_iterations*(@ctx.moi.size)} iterations")
      generate(new_program_seed, [precond], [postcond], false, add_dyn: true, type_search_depth: (@ctx.moi.size)*inference_iterations)
    rescue NameError => e
      @ctx.logger.debug("Inference Complete")
      print_inferred_types()
      generate(new_program_seed, [precond], [postcond], false, add_dyn: false)
    end
  end

  # AI generated: the branch search from run (same code as before) plus the spec type guard, as program_search
  def branch_search(precond, inference_iterations, use_inference) # AI generated
    if @ctx.moi == []
      @ctx.logger.debug("Searching for branch with no type inference.")
      return generate(new_branch_seed, [precond], [TRUE_POSTCOND], true)
    end
    unless use_inference
      begin
        return generate(new_branch_seed, [precond], [TRUE_POSTCOND], true)
      rescue RbSynError => e
        raise e unless e.message.start_with?("No candidates")
        @ctx.logger.debug("Typed-only branch search ran out of candidates, falling back to an inference pass")
      end
    end
    begin
      @ctx.logger.debug("Inferring Types for branch search with #{inference_iterations*(@ctx.moi.size)} iterations")
      generate(new_branch_seed, [precond], [TRUE_POSTCOND], true, add_dyn: true, type_search_depth: (@ctx.moi.size)*inference_iterations)
    rescue NameError => e
      @ctx.logger.debug("Inference Complete, resuming branch search")
      generate(new_branch_seed, [precond], [TRUE_POSTCOND], true)
    end
  end

  def flat_comparator(a, b)
    if ProgSizePass.prog_size(a.to_ast, nil) < ProgSizePass.prog_size(b.to_ast, nil)
      1
    elsif ProgSizePass.prog_size(a.to_ast, nil) == ProgSizePass.prog_size(b.to_ast, nil)
      0
    else
      -1
    end
  end
end
