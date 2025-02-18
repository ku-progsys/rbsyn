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
    handler_missing(node)
    @tenv.pop
  end

  def on_lvasgn(node)
    @tenv[-1][node.children[0]] = RDL::Globals.types[:integer]
    handler_missing(node)
  end

  def on_kwbegin(node)
    @tenv << {}
    handler_missing(node)
    @tenv.pop
  end

  def on_block(node)
    @tenv << {}
    args = node.children[1].children
    args.each { |arg|
      @tenv[-1][arg.children[0]] = RDL::Globals.types[:integer]
    }
    handler_missing(node)
    @tenv.pop
  end

  def on_hole(node)
    out = @tenv[0].map { |k,v| "#{k}: #{v}" }.join(" ")
    out2 = collapse_tenv().map { |k,v| "#{k}: #{v}" }.join(", ")
    puts "Current TEnv: { #{out} }"
    puts "  ^- Current LEnv: { #{out2} }"
  end

  def handler_missing(node)
    node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    }
  end

  def collapse_tenv()
    @tenv.reduce(:merge)
  end
end
