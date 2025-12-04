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
    return left.reject { |k, _| [:result, :except].include?(k) } == right.reject { |k, _| [:result, :except].include?(k) }
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
    consolidate_types(trace, true)
    @type_errs

  end


  def update_success(trace)

    consolidate_types(trace)
    @type_successes
    #@type_successes[trace[:method]].each{|i|
    
    #   if compare_hashes(i, trace)
    #     return
    #   end
    # }
    
    # @updated = true
    #@type_successes[trace[:method]].append(trace)
      

  end

  def consolidate_types(trace, err=false)
    # trace form: {method, reciever, args, result, exception}
    # require 'pry'
    # require 'pry-byebug'
    # binding.pry
    begin
      if trace[:except].is_a?(NoMethodError)
        #binding.pry
        types = @type_errs[trace[:method]].each_with_index.filter_map {|val, ind| [val, ind] if val[:receiver] <= trace[:receiver] ||  trace[:receiver] <= val[:receiver]} 
        if types == []
          @type_errs[trace[:method]].append(trace)
          return @type_errs
        elif types[0][0][:receiver] <= trace[:receiver]
          @type_errs[trace[:method]][types[0][1]][:receiver] = trace[:receiver]
          return @type_errs
        else
          return @type_errs
        end
    
      end
      type_list =  err ? @type_errs : @type_successes
      type_list[trace[:method]].each_with_index do |sig, ind|
        newtrace = {method: trace[:method]}
        arg_union = true
        
        if sig[:receiver] <= trace[:receiver]
          newtrace[:receiver] = trace[:receiver]
        elsif trace[:receiver] <= sig[:receiver]
          newtrace[:receiver] = sig[:receiver]
        else
          next
        end
        ############
        if err
          newtrace[:result] = nil
        else
          if sig[:result] <= trace[:result]
            newtrace[:result] = trace[:result]
          elsif trace[:result] <= sig[:result]
            newtrace[:result] = sig[:result]
          else
            next
          end
        end
        ############  
        if sig[:args].size != trace[:args].size
          next
        else
          newtrace[:args] = []
          sig[:args].zip(trace[:args]).each do |s, t|
            if s <= t
              newtrace[:args].append t
            elsif t <= s
              newtrace[:args].append t
            else
              newtrace[:args].append RDL::Type::UnionType.new(s,t)
            end
          end
        end
        ###########
        
        if err && sig[:excep].to_s != trace[:except].to_s
          newtrace[:multi_exept] = [sig[:except], trace[:except]]
        end
        newtrace[:except] = sig[:except]
        if err
          @type_errs[trace[:method]].delete_at(ind)
          @type_errs[trace[:method]].append(newtrace)
        else
          @type_successes[trace[:method]].delete_at(ind)
          @type_successes[trace[:method]].append(newtrace)
          RDL.type newtrace[:receiver].to_s, newtrace[:method], "(#{newtrace[:args].map {|i| i.to_s}.join(', ')}) -> #{newtrace[:result].to_s}"
        end
        #############
        if err 
          return @type_errs
        else
          return @type_successes
        end

      end


      if err 
        @type_errs[trace[:method]].append(trace)
        return @type_errs
      else
        @type_successes[trace[:method]].append(trace)
        return @type_successes
      end
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