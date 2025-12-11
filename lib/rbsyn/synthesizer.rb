COVARIANT = :+
CONTRAVARIANT = :-
TRUE_POSTCOND = Proc.new { |result| 
  result == true }

ENV['COUNTER'] = '0'
def debug(var, *conds, message: "") 
  
  if ENV['DEBUG'] == 'PRY' || ENV['DEBUG'] == 'PRINT'
    
    if conds.all? {|m| var.include?(m)}
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
    @ctx.type_info = InferTypes.new(@ctx.moi) # type finding class
    #@type_info = InferTypes.new(@ctx.moi) # type finding class
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


    update_types_pass = RefineTypesPass.new
    progconds = @ctx.preconds.zip(@ctx.postconds, @ctx.desc).map { |precond, postcond, desc|
      @ctx.logger.debug("Finding sln for subspec: #{desc}")
      #binding.pry
      prog = prog_cache.find_prog(precond, postcond)
      #binding.pry
      if prog.nil?

        env = LocalEnvironment.new
        prog_ref = env.add_expr(s(@ctx.functype.ret, :hole, 0, {variance: CONTRAVARIANT}))
        prog_ref = env.add_expr(s(RDL::Type::DynamicType.new(), :hole, 0, {variance: CONTRAVARIANT}))
        seed = ProgWrapper.new(@ctx, s(@ctx.functype.ret, :envref, prog_ref), env)
        seed.look_for(:type, @ctx.functype.ret)


        prog = generate(seed, [precond], [postcond], false) 
        prog_cache.add(prog)

        @ctx.logger.debug("Synthesized program:\n#{format_ast(prog.to_ast)}")
        @ctx.logger.debug("In AST FORM: #{prog.to_ast}")
      else

        @ctx.logger.debug("Found program in cache:\n#{format_ast(prog.to_ast)}")
      end
      raise Exception
      
      env = LocalEnvironment.new
      branch_ref = env.add_expr(s(RDL::Globals.types[:bool], :hole, 0, {bool_consts: false}))
      seed = ProgWrapper.new(@ctx, s(RDL::Globals.types[:bool], :envref, branch_ref), env)
      bool_or_any = RDL::Type::UnionType.new(RDL::Globals.types[:bool], RDL::Globals.types[:any])

      seed.look_for(:type, bool_or_any)
      @ctx.logger.debug("Searching for branch")
      branches = generate(seed, [precond], [TRUE_POSTCOND], true) 
      cond = BoolCond.new
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
    raise RbSynError, "No candidates found"
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
