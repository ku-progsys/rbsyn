class CheckErrorPass < ::AST::Processor
  include TypeOperations
  attr_reader :errors

  def initialize(errs, successes)

    @type_info = type_info


    @errors = 0
  end

  def update_info(type_info)
    @type_info = type_info  
  end


  def reset()
    @errors = 0
  end


  def on_send(node)


    m = @type_info[node.children[1]]

      
    trec = process(node.children[0]) 
    return :except if trec == :except    

    targs = node.children[2 ..].map {|k|

      k.is_a?(TypedNode) ? process(k) : nil # this way of traversing will collect every error. 
      
    }
    return :except if targs.include?(:except)
      
    
    signature = {:reciever => trec, 
      :args => targs}

    if m 

      # try to see if there is an error 
      m[:fail].each {|i|
   
        if matches_err(i, signature)  
          @errors += 1
          return :except
        end

      }

      # try to infer the type to pass up the tree
      m[:success].each {|i|
        #BR See note 1
        if match_success(i, signature)
          return i[:result]
        end

      }

      #puts "returned dynamic"
      return RDL::Type::DynamicType.new() # well looks like we aren't sure what the type is boys. 
    
      
    else
      mth = node.children[1]
      mthds = methods_of(trec)
      info = mthds[mth]
      tmeth = info[:type]
      begin
        tret = compute_tout(trecv, tmeth, targs)
        node.update_ttype(tret)
      rescue
        puts "error in known types"
        return :except
      end

    end

  end


  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })
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