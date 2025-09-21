class TrackerRewrite < ::AST::Processor
  include TypeOperations
  require_relative "../ast"
  #require_relative "./universal_dispatcher"
  def initialize(methods)
    @methods = methods
 
  end

  def on_send(node)
    
    if node.is_a?(TypedNode) && @methods.include?(node.children[1])
      
      node.updated(nil, ([TypedNode.new(:ivar, :ivar, :@dummyclass)] + [:w_instrument] + [node.children[0]] + [TypedNode.new(:sym, :sym, node.children[1])] + node.children[2 .. ]).map { |k|
        k.is_a?(TypedNode) ? process(k) : k
      })

    else

      node.updated(nil, node.children.map { |k|
        k.is_a?(TypedNode) ? process(k) : k
        })
    end

  end

  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })

  end
end
