require "set"
require_relative "check_error_pass"

class InferTypes

  attr_reader :type_errs, :type_successes, :moi

  def initialize(moi)
    @moi = moi
    @type_errs = {}
    @type_successes = {}
    moi.each do |i|
      @type_errs[i] = []
      @type_successes[i] = []
    end
    @typestack = []
    @checker = CheckErrorPass.new(@type_errs, @type_successes)
    @updated = false
    @set_exception = false
  end


  def reset_instrumentation()
    @updated = false
    @typestack = []
    @set_exception = false
  end



  def w_instrument(receiver, meth, *args)
    trace = {:method => meth,:receiver => RDL::Type::NominalType.new(receiver.class.to_s),
      :args => args.map {|i| RDL::Type::NominalType.new(i.class.to_s)}, :result => nil, :except => nil}
      
    begin
      result = receiver.public_send(meth, *args)
      
    rescue TypeError => e
      if !@set_exception 
        trace[:except] = e
        update_errlist(trace)
        @set_exception = true
      end
      raise e
    rescue StandardError => e
      if !@set_exception 
        trace[:except] = e
        update_errlist(trace)
        @set_exception = true
      end
      raise e
    end

      trace[:result] = RDL::Type::NominalType.new(result.class.to_s)
      update_success(trace)
      result

  end


  def update_errlist(trace)

    @type_errs[trace[:method]].each{|i|
  
      if type_to_s(i) == type_to_s(trace)
        return
      end
    }
  
    @updated = true
    @type_errs[trace[:method]].append(trace)

  end


  def update_success(trace)


    @type_successes[trace[:method]].each{|i|
  
      if type_to_s(i) == type_to_s(trace)
        return
      end
    }
  
    @updated = true
    @type_successes[trace[:method]].append(trace)
      

  end


  def check_errors(ast)
    @checker.update_reset(@type_errs, @type_successes)
    @checker.process(ast) # the # of errors 
    @checker.errors

  end


  def type_to_s(type)
  

    t = type[:receiver].to_s 
    
    if !type[:method].nil?
      t = "#{t} :#{type[:method]}"
    end 
    

    type[:args].each {|i|
      t = "#{t} => #{i.to_s}"
    }

    if !type[:result].nil?
      t = "#{t} => #{type[:result].to_s}"
    end


    if !type[:except].nil?
      t = " #{t} => :exception"
    end

    t
  end

end