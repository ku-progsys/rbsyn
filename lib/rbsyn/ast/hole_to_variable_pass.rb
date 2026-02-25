class HoleToVariablePass < ::AST::Processor
  include AST
  attr_reader :hole_vars

  def initialize
    @hole_counter = 0
    @hole_vars = {}
  end

  def on_hole(node)
    var_name = "rbsyn_hole_#{@hole_counter}".to_sym
    @hole_counter += 1
    new_node = s(node.ttype, :lvar, var_name)
    @hole_vars[var_name] = node.ttype
    new_node
  end

  def handler_missing(node)
    return node unless node.is_a?(Parser::AST::Node)
    new_children = node.children.map { |child|
      child.is_a?(Parser::AST::Node) ? process(child) : child
    }
    node.updated(nil, new_children)
  end
end
