require_relative "./ast/track_rewrite"
#require_relative "./ast/parenthesize"
require_relative "./complex_error"
require 'unparser'
require 'parser/current'
require 'pry'
require 'pry-byebug'

module AST
  def s(ttype, type, *children)
    TypedNode.new( ttype, type, *children )
  end

  def eval_ast(ctx, ast, precond) #modified by me to parenthesize

    max_args = ctx.functype.args.size

    args = max_args.times.map { |i| "arg#{i}".to_sym }
    klass = Class.new
    klass.instance_eval {
      @count = 0
      @passed_count = 0
      @ctx = ctx
      extend Assertions
    }

    bind = klass.instance_eval { binding }

    ctx.curr_binding = bind

    DBUtils.reset

    ctx.reset_func.call unless ctx.reset_func.nil?
    

    #rewriter = Parens.new(ctx.moi)
    func = s(ctx.functype, :def, ctx.mth_name,
      s(RDL::Globals.types[:top], :args, *args.map { |arg|
        s(RDL::Globals.types[:top], :arg, arg)
      }), ast)



    klass.instance_eval Unparser.unparse(func)

    result = klass.instance_eval(&precond) unless precond.nil?

    [result, klass]
  end


  def eval_ast_not_parenthesized(ctx, ast, precond)

    max_args = ctx.functype.args.size

    args = max_args.times.map { |i| "arg#{i}".to_sym }
    klass = Class.new
    klass.instance_eval {
      @count = 0
      @passed_count = 0
      @ctx = ctx
      extend Assertions
    }

    bind = klass.instance_eval { binding }
    

    ctx.curr_binding = bind

    DBUtils.reset

    ctx.reset_func.call unless ctx.reset_func.nil?

    func = s(ctx.functype, :def, ctx.mth_name,
      s(RDL::Globals.types[:top], :args, *args.map { |arg|
        s(RDL::Globals.types[:top], :arg, arg)
      }), ast)

    klass.instance_eval Unparser.unparse(func)

    result = klass.instance_eval(&precond) unless precond.nil?

    [result, klass]
  end


  def eval_ast_second(ctx, ast, precond)

    max_args = ctx.functype.args.size
    args = max_args.times.map { |i| "arg#{i}".to_sym }
    klass = Class.new
    klass.instance_eval {
      @count = 0
      @passed_count = 0
      @ctx = ctx
      extend Assertions
    }
    bind = klass.instance_eval { binding }
    ctx.curr_binding = bind 
    DBUtils.reset
    ctx.reset_func.call unless ctx.reset_func.nil?
    rewriter = TrackerRewrite.new(ctx.moi, ctx.tenv)

    ast = rewriter.process(ast)
    tracelist = rewriter.tracelist

    func = s(ctx.functype, :def, ctx.mth_name,
    s(RDL::Globals.types[:top], :args, *args.map { |arg|
      s(RDL::Globals.types[:top], :arg, arg)
    }), ast)

    # if ENV['FLAG'] == '2'
    #   binding.pry
    # end
    begin
      x = Unparser.unparse(func)
      klass.instance_eval x 
      klass.instance_variable_set(:@dummyclass, ctx.type_info)
      ctx.type_info.reset_instrumentation(tracelist)
      result = klass.instance_eval(&precond) unless precond.nil?
    rescue Exception => e
      if e.is_a?(SyntaxError)
        binding.pry
      end
      raise e
    end
    
    [result, klass]
  end


end
