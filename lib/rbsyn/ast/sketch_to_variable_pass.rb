class SketchToVariablePass < ::AST::Processor
  include AST
  attr_reader :hole_vars

  def initialize(main_name = nil, main_type = nil, inferred = {})
    @main_name = main_name
    @main_type = main_type
    @methods = []
    @hole_counter = 0
    @hole_vars = {}
    @inferred = inferred
    @hole_types = inferred.fetch(:hole_types, {})
  end

  def on_send(node)
    if node.children[0].nil? && node.children[1] == :_?
      var_name = "rbsyn_hole_#{@hole_counter}".to_sym
      @hole_counter += 1
      hole_type = @hole_types[var_name]
      hole_type = nil if hole_type == RDL::Globals.types[:nil]
      hole_type ||= RDL::Globals.types[:integer]
      @hole_vars[var_name] = hole_type
      s(hole_type, :hole, 0, {})
    else
      handler_missing(node)
    end
  end

  def on_def(node)
    @methods << node.children[0]
    @tenv = {}
    @ret = RDL::Globals.types[:integer]
    new_nodes = node.children.map { |k|
      k.is_a?(Parser::AST::Node) ? process(k) : k
    }
    meth_type = RDL::Type::MethodType.new(@tenv.values, nil, @ret)
    TypedNode.new(meth_type, node.type, *new_nodes)
  end

  def on_args(node)
    fn_name = @methods.last
    node.children.each_with_index { |arg, idx|
      arg_name = arg.children[0]
      if @main_type && fn_name == @main_name
        t = @main_type.args[idx] if @main_type.args && @main_type.args[idx]
        @tenv[arg_name] = t || RDL::Globals.types[:integer]
      else
        @tenv[arg_name] = RDL::Globals.types[:integer]
      end
    }
    node
  end

  def type_for_node(node)
    case node.type
    when :int then RDL::Globals.types[:integer]
    when :str then RDL::Globals.types[:string]
    when :true, :false then RDL::Globals.types[:bool]
    when :nil then RDL::Globals.types[:nil]
    when :sym then RDL::Globals.types[:symbol]
    else RDL::Globals.types[:top]
    end
  end

  def handler_missing(node)
    TypedNode.new(type_for_node(node), node.type,
      *node.children.map { |k|
        k.is_a?(Parser::AST::Node) ? process(k) : k
      })
  end
end
