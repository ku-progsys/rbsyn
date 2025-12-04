require "set"
require_relative "check_error_pass"
require "pry"
require "pry-byebug"

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

  def compare_hashes(left, right)
    begin
      return left.reject { |k, _| [:except].include?(k) } == right.reject { |k, _| [:except].include?(k) }
    rescue Exception => e
      binding.pry
    end
  end

  def reset_instrumentation()
    @updated = false
    @typestack = []
    @set_exception = false
  end

  def w_instrument(receiver, meth, *args)

    # trace form: {method, reciever, args, result, exception}
    trace = {:method => meth,:receiver => RDL::Type::NominalType.new(receiver.class.to_s),
      :args => args.map {|i| RDL::Type::NominalType.new(i.class.to_s)}, :result => nil, :except => nil} # why is this nominal type this might need to change because of generics 
      
    begin

      # puts "constants: \n\n"
      # puts reciever.instance_variable_get(:columns_hash)
      # receiver.instance_variables.each do |i|
      #   puts i
      # end
      # puts "\n\n\n\n"
      result = receiver.public_send(meth, *args)
      
    rescue TypeError => e
      if !@set_exception 

        trace[:except] = e
        update_errlist(trace)
        @set_exception = true
      end
      raise e
      #this is technically something that you should put in. 
    rescue NoMethodError => e # BR TODO TEST THIS NEW FUNCITONALITY
      if !@set_exception 
           



        trace[:except] = e
        trace[:args] = :ALL
        update_errlist(trace)
        @set_exception = true
      end
      raise e

    rescue NameError => e 
      if !@set_exception 
        if e.to_s.downcase.include?("undefined method")
      

          trace[:except] = e
          trace[:args] = :ALL
          update_errlist(trace)
        end
        @set_exception = true
      end
      raise e

    rescue ArgumentError => e 
       if !@set_exception  
  
        trace[:except] = e
        trace[:args] = :ALL
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

    # @type_errs[trace[:method]].each{|i|

    #   if compare_hashes(i, trace)
    #     return
    #   end
    # }

    # @updated = true
    # @type_errs[trace[:method]].append(trace)
    #194
    consolidate_type_errors(trace)
    @type_errs
    #176

  end


  def update_success(trace)

    consolidate_type_successes(trace)
    @type_successes
    # @type_successes[trace[:method]].each{|i|
    
    #   if compare_hashes(i, trace)
    #     return
    #   end
    # }
    
    # @updated = true
    # @type_successes[trace[:method]].append(trace)
      

  end

  def consolidate_type_errors(trace)
    # trace form: {method:, reciever:, args: [], result: , except: = nil}
    # require 'pry'
    # require 'pry-byebug'
    # binding.pry
    meth = trace[:method]
    begin
      if trace[:except].is_a?(NoMethodError)

        types = @type_errs[meth].each_with_index.filter_map {|val, ind| [val, ind] if  trace[:receiver] <= val[:receiver] || val[:receiver] <= trace[:receiver]} 
        #if new error observation is a subtype of original error observation 
        # Check if new Method Missing observation is related to any existing obsrvations
        if types == []
          @type_errs[meth].append(trace)
          return @type_errs
        else
          val, ind = types[0]
        
          if val[:receiver] <= trace[:receiver]
            # if current observation is supertype of existing observation
            # do nothing, error types propogate upward
            return @type_errs
          elsif trace[:receiver] <= val[:receiver]
            # if current observation is subtype of existing observation
            # replace existing entry as we can now force the error lower
            @type_errs[meth][ind] = trace
            return @type_errs
          else
            raise Exception "Wow something bad here!"
          end
        end
      end
      ##############
      
      #################
      @type_errs[meth].filter {|i| i[:receiver] == trace[:receiver]}.each_with_index do |sig, ind|
        
        if sig[:args].size != trace[:args].size
          next
        else

          if sig[:args].zip(trace[:args]).all? { |old, current| current <= old}
            # if arguments are all subtypes of original observaion
            # narrow the args as errors propigate upward and this will
            # make the error type encompass more
            @type_errs[meth][ind][:args] = trace[:args] 
            return @type_errs
          elsif sig[:args].zip(trace[:args]).all? { |old, current| old <= current}
            # if they are all supertypes this observation falls within 
            # already seen behavior
            return @type_errs
          else
            # look at next observation
            next
          end
        end
        ###########

      end
      # no arguments matched

      @type_errs[meth].append(trace)
      return @type_errs

    rescue Exception => e
      binding.pry
      raise e
    end
  end


  def consolidate_type_successes(trace)
    begin
      meth = trace[:method]
      @type_successes[meth].filter {|i| i[:receiver] == trace[:receiver]}.each_with_index do |sig, ind|
          
        if sig[:args].size != trace[:args].size
            next
        elsif sig[:result] <= trace[:result]
          # if the previously observed result is the same or subtype of current observations result
          
          sigzip = sig[:args].zip(trace[:args])
          if sigzip.any? {|old, current| !(old <= current)}
            # if any arguments are incomprable or smaller in the current observation
            # either this needs to be treated as a subtype funciton (may still be able to be absorbed?)
            # or it is incomparable. 
            next
          else
            @type_successes[meth][ind][:args] = sigzip.map {|old, current| current <= old ? old : current}
          end

        elsif trace[:result] <= sig[:result]
          # if the prev observed result is a super or the same type
          # either 
          sigzip = sig[:args].zip(trace[:args])
          if sigzip.any? {|old, current| !(current <= old)}
            # it is a call which is a subtype 
            # or has incompararable types both seen in this guard
            next
          else
            # or it is already a subtype of what we have observed. 
            return @type_successes
          end
        end

      end

      @type_successes[trace[:method]].append(trace)
      return @type_successes

    rescue Exception => e
      binding.pry
      raise e
    end
  
  end




  def check_errors(ast)
    @checker.update_reset(@type_errs, @type_successes) # resetting the checker
    @checker.process(ast) # the # of errors 
    @checker.errors

  end


  def type_to_s(type)
  

    t = type[:receiver].to_s 
    
    if !type[:method].nil?
      t = "#{t} :#{type[:method]}"
    end 
    
    if type[:args] == :ALL
      t = "#{t} => #{type[:args].to_s}"
    
    else 
      type[:args].each {|i|
      t = "#{t} => #{i.to_s}"
      }
    end

    if !type[:result].nil?
      t = "#{t} => #{type[:result].to_s}"
    end


    if !type[:except].nil?
      t = " #{t} => :except"
    end

    t
  end

end