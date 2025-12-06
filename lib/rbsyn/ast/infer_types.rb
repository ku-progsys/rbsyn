require "set"
require_relative "check_error_pass"
require "pry"
require "pry-byebug"
require_relative "../type_helper"

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

    ParentsHelper.addTypeManually(trace[:receiver].to_s)
    ParentsHelper.addTypeManually(trace[:result].to_s)
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

    meth = trace[:method]
    begin
      
      @type_errs[meth].each_with_index do |sig, ind|
        if sig[:receiver] != trace[:receiver]
          next
        end
        if trace[:except].is_a?(NoMethodError)
          #if we've already seen this error we don't need to update anything, method missing is method missing. 
          return @type_errs
        end
        
        if sig[:args].size == trace[:args].size

          sigzip = sig[:args].zip(trace[:args])
          if sigzip.all? { |old, current| current <= old || old <= current}
            # if all arguments in the old observation are comprable to the current observation
            # reduce each argument to the smallest smaller arguments will be expanding the incorrectness as incorrectness travels upwards. 
            @type_errs[meth][ind][:args] = sigzip.map {|old, current| old <= current ? old : current}
            
            return @type_errs
          end
        end
      end

      @type_errs[meth].append(trace)
      return @type_errs

    rescue Exception => e
      binding.pry
      raise e
    end
  end


  def consolidate_type_successes(trace)

    meth = trace[:method]
    begin

      @type_successes[meth].each_with_index do |sig, ind|
        if sig[:receiver] != trace[:receiver]
          next
        end 
        if sig[:args].size == trace[:args].size && ( sig[:result] <= trace[:result] || trace[:result] <= sig[:result] )
          temp = sig
          # if args are correct size and returns are comprable
          sigzip = sig[:args].zip(trace[:args])
          if !(sigzip.any? {|old, current| !(old <= current) && !(current <= old)})
            # otherwise we can consider the previous observation to be a call to an instance of this function 
            # or a more specific instance of this function (perhaps we should not fold in, but RUBY only allows one function of the same arity per reciever" 
            @type_successes[meth][ind][:args] = sigzip.map {|old, current| current <= old ? old : current}
            @type_successes[meth][ind][:result] = sig[:result] <= trace[:result] ? trace[:result] : sig[:result]
            update = @type_successes[meth][ind]
            #update RDL HERE

            RDL.type update[:receiver].to_s, meth, "(#{update[:args].map(&:to_s).join(', ')}) -> #{update[:result].to_s}"
            return @type_successes
          end
        end
      end

      @type_successes[meth].append(trace)
      update = @type_successes[meth][-1]
      RDL.type update[:receiver].to_s, meth, "(#{update[:args].map(&:to_s).join(', ')}) -> #{update[:result].to_s}"
      return @type_successes

    rescue Exception => e
      binding.pry
      raise e
    end
  end




  def check_errors(ast)
    @checker.update_reset(@type_errs, @type_successes) # resetting the checker
    @checker.process(ast) # the # of errors 
    # binding.pry if x.is_a?(RDL::Type::DynamicType)
    # @checker.update_reset(@type_errs, @type_successes) # resetting the checker
    # x = @checker.process(ast) # the # of errors 
    [@checker.errors, @checker.dynamic_components]  

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