class CheckErrorPass < ::AST::Processor

  attr_reader :contains_type

  def initialize(err)

    @err = err
    @contains_type = false

  end

  def on_send(node)
    @err.each do |k|
      
      meth = k[1]
      if node.children[1] == meth
        trecv = node.children[0].ttype
        targs = node.children[2..].map { |i| i.ttype }
        temp_type = [trecv, meth, *targs] 

        
        if temp_type == k

          @contains_type = true


        end
      end
    end

    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })

  end

  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })
  end
end


