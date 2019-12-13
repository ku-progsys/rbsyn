class HoleVisitor < ::AST::Processor
  def on_hole(node)
    # TODO: change this
    return Parser::AST::Node.new(:int, [2])
  end

  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a? Parser::AST::Node ? process(k) : k
    })
  end
end
