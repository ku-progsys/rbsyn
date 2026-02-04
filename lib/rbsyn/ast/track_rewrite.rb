class TrackerRewrite < ::AST::Processor
  include TypeOperations
  require_relative "../ast"
  #require_relative "./universal_dispatcher"
  attr_accessor :tracelist
  def initialize(methods, typelist)
    @methods = methods
    @count = 0
    @tracelist = {}
    @typelist = typelist
  end

  def on_send(node)

    if node.is_a?(TypedNode) && @methods.include?(node.children[1])
      knowntypes = []
      newnode = node.updated(nil, ([TypedNode.new(:ivar, :ivar, :@dummyclass)] + [:w_instrument] + [node.children[0]] + [TypedNode.new(:sym, :sym, node.children[1])] + node.children[2 .. ]).map { |k|
        k.is_a?(TypedNode) ? process(k) : k
      })

      [newnode.children[2], *newnode.children[4..]].each do |chld|
        if chld.is_a?(TypedNode)
          if chld.type == :lvar
            knowntypes.append(@typelist[chld.children[0]])
          else
            knowntypes.append(nil)
          end
        end
      end
      @tracelist[@count] = knowntypes.clone
      @count += 1
      newnode
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
