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
    trace = {:method => meth,:receiver => RDL::Type::NominalType.new(receiver.class.to_s),
      :args => args.map {|i| RDL::Type::NominalType.new(i.class.to_s)}, :result => nil, :except => nil}
      
    begin
      # puts "params"
      # puts "#params: #{receiver.method(meth).parameters}"
      result = receiver.public_send(meth, *args)
      
    rescue TypeError => e
      if !@set_exception 

      #   puts "type error for : #{meth}"
      #   binding.pry
      #   ENV["MYFLAG"]="TRUE"

        trace[:except] = e
        update_errlist(trace)
        @set_exception = true
      end
      raise e
      #this is technically something that you should put in. 
    rescue NoMethodError => e
      if !@set_exception 

          puts "noMethodError for #{meth} over #{receiver.class}"
           
          ENV["MYFLAG"]="TRUE"
      #    puts "Locals: #{e.local_variables.inspect}"
      #    binding.pry

        trace[:except] = e
        trace[:args] = :ALL
        update_errlist(trace)
        @set_exception = true
      end
      raise e

    rescue NameError => e
      if !@set_exception 
        if e.to_s.downcase.include?("undefined method")
          puts "noMethodError for #{meth} over #{receiver.class}"
          ENV["MYFLAG"]="TRUE"
      #    puts "Locals: #{e.local_variables.inspect}"
      #    binding.pry
          trace[:except] = e
          trace[:args] = :ALL
          update_errlist(trace)
        end
        @set_exception = true
      end
      raise e
    rescue ArgumentError => e
       if !@set_exception 
 
        puts "ArgumentError for #{meth}"
        binding.pry
        ENV["MYFLAG"]="TRUE"
  
        trace[:except] = e
        trace[:args] = :ALL
        update_errlist(trace)
        @set_exception = true
      end
      raise e
    rescue StandardError => e
      if !@set_exception 

        puts "standard error for : #{meth}"
        binding.pry
        ENV["MYFLAG"]="TRUE"
      

        trace[:except] = e
        update_errlist(trace)
        @set_exception = true
      end
      raise e
    end

    
    ENV["MYFLAG"]="TRUE"
    
    
    trace[:result] = RDL::Type::NominalType.new(result.class.to_s)
    update_success(trace)
    result

  end


  def update_errlist(trace)

    @type_errs[trace[:method]].each{|i|

      if compare_hashes(i, trace)
        return
      end
    }

    @updated = true
    @type_errs[trace[:method]].append(trace)

  end


  def update_success(trace)


    @type_successes[trace[:method]].each{|i|
    
      if compare_hashes(i, trace)
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
      t = " #{t} => :exception"
    end

    t
  end

end