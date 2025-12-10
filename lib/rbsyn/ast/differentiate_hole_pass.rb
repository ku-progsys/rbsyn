class proliferate < ::AST::Processor

  def initialize(new_types, moi, used_program_hash)
    @types_to_find
    @new_progs = []
    @moi
    @used_program_hash = used_program_hash  
    @current_moi = nil
    @expander = []
  end


  def on_send(node)

    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })

    if @moi.include?(node.children[1])
      new_sig = {}
      new_sig[:receiver] = node.children[0]
      new_sig[:method] = node.children[1]
      new_sig[:args] = node.children[2 ...]
      new_sig[:result] = node.ttype

      

      



      
    end 
    

  end


  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })
  end

end