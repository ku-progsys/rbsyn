class GlobalTEnv < ::AST::Processor
  attr_reader :tenv

  def initialize
    @tenv = {}
  end

  def on_def(node)
    fn_name = node.children[0]
    args = node.children[1]
    num_args = args.children.size
    @tenv[fn_name] = RDL::Type::MethodType.new(num_args.times.map { RDL::Globals.types[:integer] },
                                               nil,
                                               RDL::Globals.types[:integer])
    nil
  end

  def handler_missing(node)
    node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    }
  end
end
