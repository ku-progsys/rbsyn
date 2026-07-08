class LocalTEnv < ::AST::Processor
  attr_reader :tenv

  def initialize(gtenv, main_name = nil, main_type = nil, inferred = {})
    @tenv = []
    @tenv << gtenv.dup
    @main_name = main_name
    @main_type = main_type
    @inferred = inferred
    @method_types = inferred.fetch(:method_types, {})
  end

  def on_def(node)
    @tenv << {}
    fn_name = node.children[0]
    args = node.children[1].children

    if @method_types[fn_name]
      mtype = @method_types[fn_name]
      args.each_with_index { |arg, i|
        t = mtype.args[i] if mtype.args
        @tenv[-1][arg.children[0]] = t || RDL::Globals.types[:integer]
      }
    elsif fn_name == @main_name && @main_type
      args.each_with_index { |arg, i|
        t = @main_type.args[i] if @main_type.args
        @tenv[-1][arg.children[0]] = t || RDL::Globals.types[:integer]
      }
    else
      args.each { |arg|
        @tenv[-1][arg.children[0]] = RDL::Globals.types[:integer]
      }
    end

    n = handler_missing(node)
    @tenv.pop
    n
  end

  def on_lvasgn(node)
    n = handler_missing(node)
    rhs_type = n.children[1]&.ttype || RDL::Globals.types[:top]
    @tenv[-1][node.children[0]] = rhs_type
    n
  end

  def on_kwbegin(node)
    @tenv << {}
    n = handler_missing(node)
    @tenv.pop
    n
  end

  def on_block(node)
    @tenv << {}
    args = node.children[1].children
    args.each { |arg|
      @tenv[-1][arg.children[0]] = RDL::Globals.types[:top]
    }
    n = handler_missing(node)
    @tenv.pop
    n
  end

  def on_hole(node)
    tenv = collapse_tenv
    TypedNode.new(node.ttype, :hole, 0, {ltenv: tenv })
  end

  def handler_missing(node)
    children = node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    }
    TypedNode.new(node.ttype, node.type, *children)
  end

  def collapse_tenv()
    @tenv.reduce(:merge)
  end
end
