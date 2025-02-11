class LocalTEnv < ::AST::Processor
  attr_reader :tenv

  def initialize(gtenv)
    @tenv = gtenv.dup
  end

  def on_def(node)
    args = node.children[1].children
    args.each { |arg|
      @tenv[arg.children[0]] = RDL::Globals.types[:integer]
    }
    handler_missing(node)
    nil
  end

  def on_hole(node)
    out = @tenv.map { |k,v| "#{k}: #{v}" }.join(" ")
    puts "Current TEnv: #{out}"
  end

  def handler_missing(node)
    node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    }
  end
end
