class InferCorrectPass < ::AST::Processor
  include TypeOperations
  require "set"

  attr_reader :gtlist

  def initialize(meths, gtlist)
    @gtlist = gtlist
    @meth = meths
  end

  def on_send(node)

    node.updated(nil, node.children.map { |k|
    k.is_a?(TypedNode) ? process(k) : k
    }) # start by updating the type of children bottom up????

    trecv = node.children[0].ttype
    mth = node.children[1]
    mthds = methods_of(trecv)
    info = mthds[mth]
    targs = node.children[2..].map { |i| i.ttype}

    begin 
      tret = info[:type][0].ret # <<< Here is where we will need to update tret in cases where the type is %dyn BR TODO (probably will require I pass the expected type down
    # as well.)
    rescue
    end

    if @meth.include?(mth)
      # here is where we update the bad types if this is the method we are searching for.  
      @gtlist.add([trecv, @meth, *targs, tret])

      if [trecv, @meth, *targs, tret].map {|i| i.to_s} == ["true or false", "[:+]", "Integer", "Integer"]
        puts "problem here: #{node}\n\n"
      end
    end

    begin
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
