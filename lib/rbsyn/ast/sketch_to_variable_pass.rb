class SketchToVariablePass < ::AST::Processor
  include AST
  attr_reader :hole_vars

  def initialize
    @methods = []
    @hole_counter = 0
    @hole_vars = {}
  end

  def on_send(node)
    if node.children[0].nil? && node.children[1] == :_?
      # Create a variable for the placeholder instead of a hole
      var_name = "rbsyn_hole_#{@hole_counter}".to_sym
      @hole_counter += 1
      new_node = s(RDL::Type::TopType.new, :lvar, var_name)
      @hole_vars[var_name] = RDL::Type::TopType.new
      new_node
    else
      handler_missing(node)
    end
  end

  def on_def(node)
    @methods << node.children[0]
    @tenv = {}
    @ret = RDL::Type::TopType.new
    new_nodes = node.children.map { |k|
      k.is_a?(Parser::AST::Node) ? process(k) : k
    }
    meth_type = RDL::Type::MethodType.new(@tenv.values, nil, @ret)
    TypedNode.new(meth_type, node.type, *new_nodes)
  end

  def on_args(node)
    node.children.each { |arg|
      @tenv[arg.children[0]] = RDL::Type::TopType.new
    }
    node
  end

  def handler_missing(node)
    # This is used when parsing Sketches, so all nodes are untyped hence an instance of Parser::AST::Node
    TypedNode.new(RDL::Type::TopType.new, node.type,
      *node.children.map { |k|
        k.is_a?(Parser::AST::Node) ? process(k) : k
      })
  end
end
