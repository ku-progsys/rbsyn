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
      # extend Assertions  # AI altered: inference runs also observe moi calls inside the spec's assertions
      extend InstrumentedAssertions # AI generated
    }
    bind = klass.instance_eval { binding }
    ctx.curr_binding = bind 
    DBUtils.reset
    ctx.reset_func.call unless ctx.reset_func.nil?
    if ast.to_s.include?("hash")
      #binding.pry
    end
    rewriter = TrackerRewrite.new(ctx.moi, ctx.tenv)
    
    begin
      ast = rewriter.process(ast)
    rescue Exception => e 
      puts "EXCEPTION"
      puts ast
      binding.pry
    end
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
      # if x == "def confirm_email(arg0, arg1)\n  (@dummyclass.w_instrument(arg0, :email=, (@dummyclass.w_instrument(nil, :!=, arg0))))\n  true\nend"
      #   ENV["FLAGFLAG"] = "T"
      #   puts "INCLUDES NIL:? #{ RDL::Globals.info.info.keys.include?("nil")}"
      #   binding.pry
      # end
      klass.instance_eval x 
      klass.instance_variable_set(:@dummyclass, ctx.type_info)
      ctx.type_info.reset_instrumentation(tracelist)
      result = klass.instance_eval(&precond) unless precond.nil?
      if ENV["MANFLAG"]== "T"
        binding.pry
      end
    rescue Exception => e
      if ENV["MANFLAG"]== "T"
        binding.pry
      end
      if e.is_a?(SyntaxError)
        binding.pry
      end
      raise e
    end
    if RDL::Globals.info.info.keys.include?("nil")
      binding.pry
    end
    
    [result, klass]
  end


end
