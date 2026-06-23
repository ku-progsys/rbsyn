class DynamicRefineTypes < ::AST::Processor
  # THIS IS MEANING TO REMOVE THE DYNAMIC TYPE FROM FUNCTIONS THAT HAVE A DYNAMIC TYPE TARGET, THIS IS MEANT TO PREVENT EVERYTHING FROM BECOMING DYNAMIC IF WE KNOW THE TYPE OF THE EXPRESSION. IT REALLY SHOULD BE DONE ELSEWHRE THOUGH. 
  include TypeOperations

  def initialize(ctx, env)
    @ctx = ctx
    @env = env
    @moi = ctx.moi
  end

  def on_envref(node)
    # binding.pry
    ref = node.children[0]
    info = @env.get_expr(ref)
    processed = process(info[:expr])
    if processed.ttype.is_a? RDL::Type::DynamicType
      @env.update_expr(ref, info[:expr].update_ttype(processed.ttype))
      info = @env.get_expr(ref)

      if info[:expr].ttype.is_a?(RDL::Type::MethodType)
        ttype = info[:expr].ttype.ret
      else
        ttype = info[:expr].ttype
      end
      node.update_ttype(ttype)
    else
      node
    end
    
    
  end

  def on_send(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })

    trecv = node.children[0].ttype
    if trecv.to_s == "nil"
      #BR ad-hoc since this will delete nil functions. 
      return node
    end
    mth = node.children[1]
    mthds = methods_of(trecv)
    info = mthds[mth]
    tmeth = info[:type]
    targs = node.children[2..].map &:ttype
    begin
      #following form of original
      tret = compute_tout(trecv, tmeth, targs)
      node.update_ttype(tret)
    rescue
    end
    # rescue Exception => e 
    #   binding.pry
    #   compute_tout(trecv, tmeth, targs)
    # end
    

  end

  def handler_missing(node)

    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })
  end
end
