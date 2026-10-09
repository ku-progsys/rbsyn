class TrackerRewrite < ::AST::Processor
  # Since the formal parameters might have more general types than the passed arguments we need to replace them with the more generic type when inferring types
  # This will track the list of those arguments and pass the list plus a numeric tracking system into the inference wrapper. 
  include TypeOperations
  require_relative "../ast"
  #require_relative "./universal_dispatcher"
  attr_accessor :tracelist
  def initialize(methods, typelist)
    @methods = methods
    @count = 0
    @tracelist = {}
    @typelist = typelist
    @flag = 0
    @num_child =0
  end


  def on_hash(node)
    # # binding.pry
    # lnum_child = @num_child
    # knowntypes = []
    # node.updated(nil, node.children.map { |k|
    #     k.is_a?(TypedNode) ? process(k) : k
    #     })
    # if @flag
    # AI
    lnum_child = @num_child
    knowntypes = []
    newnode = node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })
    if @flag
      node.children.each do |p|
        # if p is_a?(TypedNode) && node.type == :pair 
        if p.is_a?(TypedNode) && p.type == :pair #<- AI Suggestion
          # binding.pry
          if p.children[1].is_a?(TypedNode) && p.children[1].type == :lvar
            #knowntypes << @typelist[p.children[1]]
            #AI removal + replace
            knowntypes << @typelist[p.children[1].children[0]]
          else
            knowntypes << nil 
          end
        end
      end 
      @tracelist[(@count + lnum_child)] = knowntypes
      # @count += 1 <- AI SUGGESTION ON_SEND OWNS THE COUNTER?
    end
      # node
      newnode #AI
  end


  # end
  # 
  #=> s(:begin,
  # s(:send,
  #   s(:ivar, :@dummyclass), :w_instrument,
  #   s(:lvar, DiasporaUser(id: integer, username: string, invited_by_id: integer, confirm_email_token: string, email: string, unconfirmed_email: string)),
  #   s(:sym, :exists?),
  #   s(:hash,
  #     s(:pair,
  #       s(:sym, :id),
  #       s(:nil)))))

  def on_send(node)
    @num_child = 0 
    @flag = false
    lflag = false
    if node.is_a?(TypedNode) && @methods.include?(node.children[1])
      @flag = true
      lflag = @flag
      lnum_child = @num_child 
      knowntypes = []
      # newnode = node.updated(nil, ([TypedNode.new(:ivar, :ivar, :@dummyclass)] + [:w_instrument] + [node.children[0]] + [TypedNode.new(:sym, :sym, node.children[1])] + node.children[2 .. ]).map { |k|
      #   @num_child = lnum_child + 0.1; k.is_a?(TypedNode) ? process(k) : k; @flag = lflag; k 
      # })
      # AI altered: the block above returned the original child k, discarding process(k), so a moi call nested
      # inside another moi call was never wrapped in w_instrument even though it had taken a tracelist slot;
      # at runtime every later instrumented call then read the wrong slot (wrong receiver/argument types)
      newnode = node.updated(nil, ([TypedNode.new(:ivar, :ivar, :@dummyclass)] + [:w_instrument] + [node.children[0]] + [TypedNode.new(:sym, :sym, node.children[1])] + node.children[2 .. ]).map { |k| # AI generated
        @num_child = lnum_child + 0.1; processed = k.is_a?(TypedNode) ? process(k) : k; @flag = lflag; processed # AI generated
      }) # AI generated

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
      @num_child = 0 
      @flag = false
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
