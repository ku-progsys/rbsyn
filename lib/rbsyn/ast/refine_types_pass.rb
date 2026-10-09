class RefineTypesPass < ::AST::Processor
  include TypeOperations

  def on_send(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })

    trecv = node.children[0].ttype
    mth = node.children[1]
    mthds = methods_of(trecv)
    info = mthds[mth]
    # AI generated: with library types blocked, a call can have no signature for this receiver
    # (e.g. nil != arg1 when != was only learned on DiasporaUser/String); keep the node's type as is,
    # matching the rescue below that ignores compute_tout failures
    return node if info.nil? || info[:type].nil? # AI generated
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
