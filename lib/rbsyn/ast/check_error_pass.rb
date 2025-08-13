class CheckErrorPass < ::AST::Processor
  include TypeOperations
  attr_reader :errors

  def initialize(errs, successes)

    @type_errs = errs
    @type_successes = successes
    @errors = 0

  end

  def update_reset(type_errs, type_successes)
    @type_errs = type_errs
    @type_successes = type_successes
    @errors = 0
  end


  def on_send(node)
    
    mth = node.children[1]
    trecv = process(node.children[0]) 
    return "error" if trecv.to_s == "error" 

    targs = node.children[2 ..].map {|k|

      k.is_a?(TypedNode) ? process(k) : nil # this way of traversing will collect every error. 
      
    }
    return "error" if targs.map {|i| i.to_s}.include?("error")
    
    signature = {:reciever => trecv, 
      :args => targs}


    if @type_successes.keys.include?(mth)
        # try to see if there is an error 
      @type_errs[mth].each {|i|
    
        if matches_err(i, signature)  
          @errors += 1
          return "error"
        end

      }

        # try to infer the type to pass up the tree
      @type_successes[mth].each {|i|
        #BR See note 1
        if match_success(i, signature)
          return i[:result]
        end

      }

      return RDL::Type::DynamicType.new() # if we havent gotten to this point yet
      
    else

      mthds = methods_of(trecv)
      info = mthds[mth]
      tmeth = info[:type]

      begin
        tret = compute_tout(trecv, tmeth, targs)
        #node.update_ttype(tret)  # uncomment if you would like the type to be updated with the emperical  types
        return tret
      rescue Exception => e
        puts "error in known types: #{e}"
        return "error"
      end
    end
  end


  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })

    return node.ttype
  end


  def match_success(template, signature)

    if template[:args].size != signature[:args]
      return false
    elsif !(signature[:reciever] <= template[:reciever])
      return false
    end  

    template[:args].zip(signature[:args]).each {|t,s|
      if !(s <= t)
        return false
      end
    }
    
    return true

  end


  def matches_err(template, signature)

    dyn = RDL::Type::DynamicType.new()

    if template[:args].size != signature[:args]
      return false
      
    elsif !(signature[:reciever] >= template[:reciever]) && signature[:reciever] != dyn
      return false
    end  

    template[:args].zip(signature[:args]).each {|t,s|
      if !(s >= t) && s != dyn
        return false
      end
    }

    return true
  end
end


#BR NOTE 1: # we may need to do successes first as we might want to prioritize exploration rather than pruning when we are dealing with 
        # cases where the restrictions conflict with the successes