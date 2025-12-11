class DynamicRefineTypes < ::AST::Processor
  include TypeOperations

  def initialize(ctx, env)
    @ctx = ctx
    @env = env
    @moi = ctx.moi
  end

  def on_envref(node)

    ref = node.children[0]
    info = @env.get_expr(ref)
    if info[:expr].ttype.is_a? RDL::Type::DynamicType
      @env.update_expr(ref, process(info[:expr]))
      info = @env.get_expr(ref)
    end
    x = node.update_ttype(info[:expr].ttype)
    x
  end

  def on_send(node)
    binding.pry
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })

    trecv = node.children[0].ttype
    mth = node.children[1]
    mthds = methods_of(trecv)
    info = mthds[mth]
    tmeth = info[:type]
    targs = node.children[2..].map &:ttype
    
    begin
      tret = compute_tout(trecv, tmeth, targs)
      node.update_ttype(tret)
    rescue
    end
  end

  def handler_missing(node)

    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })
  end
end
