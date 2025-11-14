class LocalTEnv < ::AST::Processor
  attr_reader :tenv

  def initialize(gtenv)
    @tenv = []
    @tenv << gtenv.dup
  end

  def on_def(node)
    @tenv << {}
    args = node.children[1].children
    args.each { |arg|
      @tenv[-1][arg.children[0]] = RDL::Globals.types[:integer]
    }
    n = handler_missing(node)
    @tenv.pop
    n
  end

  def on_lvasgn(node)
    n = handler_missing(node)
    @tenv[-1][node.children[0]] = RDL::Globals.types[:integer]
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
      @tenv[-1][arg.children[0]] = RDL::Globals.types[:integer]
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
