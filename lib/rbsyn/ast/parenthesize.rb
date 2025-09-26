class Parens < ::AST::Processor
  include TypeOperations
  require_relative "../ast"


  def initialize(methods)
    @methods = methods
  end

  def on_send(node)

    processed = node.updated(nil, node.children.map { |k|
        k.is_a?(TypedNode) ? process(k) : k
        })

    if node.is_a?(TypedNode) && @methods.include?(node.children[1])

      TypedNode.new(:begin, :begin, processed)
    end

    
  end

  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })
  end
end
