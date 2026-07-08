class GlobalTEnv < ::AST::Processor
  attr_reader :tenv

  def initialize(main_name = nil, main_type = nil, inferred = {})
    @tenv = {}
    @main_name = main_name
    @main_type = main_type
    @inferred = inferred
    @method_types = inferred.fetch(:method_types, {})
  end

  def on_def(node)
    fn_name = node.children[0]
    args = node.children[1]
    num_args = args.children.size

    if @method_types[fn_name]
      @tenv[fn_name] = @method_types[fn_name]
    elsif fn_name == @main_name && @main_type
      @tenv[fn_name] = @main_type
    else
      @tenv[fn_name] = RDL::Type::MethodType.new(
        num_args.times.map { RDL::Globals.types[:integer] },
        nil,
        RDL::Globals.types[:integer]
      )
    end
    nil
  end

  def handler_missing(node)
    node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    }
  end
end
