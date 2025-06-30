def traverse_and_check(ast, klass, mthd, *argtypes)
    # function to remove complete candidates that are censored, VERY inefficient right now. 
    # TODO alter to use a full list of censored typed 

    if ast.children.size == 0
      return true
    end
    thisklass = nil
    thismthd = nil
    
    aargs = []
    targs = []
    if ast.type == :send
      thisklass = ast.children[0]
        if thisklass.type == :send
          thisklass = ast.children[0] 
        end
    else
      thisklass = ast.children[0]
    end

    if ast.children.size == 1
      return true
    end

    ast.children[1 ...].each do |i|

      if i.class == TypedNode

        targs.append(i.ttype)
      else
        thismthd = i
      end
    end

    if thismthd == mthd
      if thisklass.ttype.to_s == klass.to_s && argtypes.size == targs.size

        (0..targs.size).each do |i|

          if targs[i].to_s != argtypes[i].to_s

            return false
            
          end 
        end

        if thisklass.children.size > 1
          if ! traverse_and_check(thisklass, klass, mthd, *argtypes)

            return false
          end
        end
        aargs.each do |i|
          if i.children.size > 1
            if ! traverse_and_check(i, klass, mthd, *argtypes)

             return false
            end
          end
        end
        return true
      else

        return false
        
      end

    else
      return true
    end

  end

  def lex_message(error)
    # function to parse the type error from the human readable error message, requires full error not message string
    # 
    magic_kats = {
      'values' => ['true', 'false'],
      'types' =>  ['BasicType', 'DynamicType', 'TopType', 'Integer', 'str', 'bool'],
      'syntax_negatives' => ['cannot', "can't", "no"],
      'syntax_casting' => ['coerced', 'coersion', 'cast'] }

    keyword_to_kat = {}
    magic_kats.each do |category, words|
      words.each { |word| keyword_to_kat[word] = category }
    end

    pattern = /\b(#{keyword_to_kat.keys.map { |w| Regexp.escape(w) }.join('|')})\b/i

    err = error.to_s
    matches = err.scan(pattern).flatten.map do |word|
      [keyword_to_kat[word], word]
    end

    matches 

  end

  def methods_of_interest(components)
    # Stub TODO Unstub - This might just be deleted in favor of using the native components methods. 
    # format of returns should be of format: methodname =>{ :lowerbound => [all possible lower bounds in format dict{klass => _, mthd => methodname, argTypes => [all method types], retType => returnType},
    # :upperbound => [same as above but the prohibited types]}] 
    # everything will be of form stings (because the error messages are in string format) we will interr the strings as needed. 
    return {"+" => {:lowerbound => [{:klass => "BasicObject", :method => "+", :arguments => ["%dyn"], :returns => "%dyn"}], :upperbound => []},
            :missing_key => nil}

  end


  def backtrace_scrape(error)
    # function to get the possible positions of the error using the backtrace, 
    # currently only extracts parts known to occur within the 'eval' section of the code. 
    # Assumes that the top level of the error is the probable location of error. 
    # I am finding that it doesn't always include what I need so I will have it look at the message now

    bktrace = error.backtrace
    relevant = []
    bktrace.each do |i|
      if i.include?("(eval)")
        relevant.append(i.scan(/`.*?'/)[0].gsub(/^`|\'$/, ''))
        
      else
        break
      end
    end
    temp = error.to_s.scan(/`.*?'/)[0]
    temp = if temp != nil then temp.gsub(/^`|\'$/, '') else nil end
    relevant.append(temp)
    relevant

  end
  


  def extract_type_error(components, error, ast)
    
    # puts together all other error functions to get the most likely type that must be 'prohibited'

    #puts "extracting\n\n"

    #'''Note to self. I think that I might be able to infer which subformula of the code has the error assuming that the stack trace has eval_ast nested recursively
    #for each branch of the tree, that might be much much later in this process though'''
    

    methods = methods_of_interest(:components) # All known methods with dynamic types along with their respective upper and lower bounds. ??
    lexed_err = lex_message(error) # human readable error message has been tokenized into a more machine readable form here. 
    relevant_trace = backtrace_scrape(error)  
    problem_method = relevant_trace[0]  # hard coded the location of the error in the backtrace will need to create a recursive search.
    mthds_lst = methods.keys  #hard coded for now, list of all component methods that are currently known to have prohibited types. 
    method_bounds = methods[problem_method]   

    #puts lexed_err.map {|i| i[0]}
    #puts 
    #puts lexed_err.map {|i| i[1]}
    
    values = lexed_err.find_all {|i| i[0] == "value "}

    tee = ast_iterate(ast) {|i| 
                              k = i.map {|m| if m.class == TypedNode
                                              
                                                if m.children.size == 0
                                                  m.type
                                                else
                                                  m
                                                end
                                              else
                                                m
                                              end
                                            }

                              puts values[0]
                              if k.include?(problem_method.to_sym) #&& k.include?(values[0]) #hard coded the value to look for for now
                                
                                klass_of_prohibition = (i[0].type) rescue i[0].class  # assuming infix for now. 
                                prohibited_method = i[1] 
                                prohibited_args = (i[2].type) rescue i[2].class #and assuming this is the only point where there is an issue, the methodology for locating the error should be more sophistocated
                                
                                {klass: klass_of_prohibition, method: prohibited_method, args: [prohibited_args]}
                              end
                            }
    
    while true
      begin 
        returns = tee.next 
        if returns != nil
          break
        end
      rescue StopIteration
        break
      end
    end

    # I really should have an ast tree from the error message but I don't I will have it hardcoded here instead.
    # honestly not sure here, this part needs an interpreter to alter the type 
    # 
    corrected_type = {klass: :Integer, method: :+, args: [:Integer]}

    return corrected_type, returns

  end



  def ast_iterate(ast, &blk)

    # program to traverse the ast and find exact location of error.
    Enumerator.new do |y|
      
      proc = blk

      rec = ->(a, top) {

        if a.class == TypedNode
          if a.children.size > 1 # not value or unit type
            y << proc.call(a.children)
            a.children.each {|i|  rec.call(i, false)}
          end       
        end # no need for recursive call        
        return if top
      }

      rec.call(ast, true)       
                                     
    end
  end




def type_priority(suspect_types_list, ast, tenvd)

  if ast.type_suspect == 1
    return 1
  end
  stl = suspect_types_list
  if stl.size == 0
    return 0
  end

  ast = ast.to_ast
  iter = ast_iterate ast do |l|
    v = 0
    types = l.map do |i| 
      if i.class == TypedNode
        if [:true, :false].include?(i.type)
            :bool
        elsif i.type == :lvar && tenvd.keys.include?(i.children)
          tenvd[i]
        else
          i.type
        end
      else 
        i
      end
    end

    stl.each do |l|
      
      #check for match
      if l == types
        
        v = 1 # this might be wrong? that is using return
        break
      end
    end
    
    v

  end
  #end traversal block argument
  #
  value = 0

  while true
    
    begin
      value = iter.next
      if value == 1
        break
      end
    rescue StopIteration
      break
    end

  end
  
  value
  
end


def get_type_error(ast, error, tenvd, test_name = "sumTwo")
  puts "geterror called"
  #should identify all points where an error could have occurred.
  #for now will have it identify the top level error
  #
  ast = ast.to_ast

  err = backtrace_scrape(error) #top level error
  if err[0] == test_name # hard coded test name for now
    err = err[-1]
  else
    err = err[0]
  end
  #puts "Error detected is: #{err}"
  #

  pass = InferTypeErrPass.new(err.to_sym)
  pass.process(ast)
  puts "BAD TYPE: #{pass.bad_type}"

  top_store = []
  iter = ast_iterate ast do |l|

    types = nil
    if l.include?(err.to_sym)
      puts "LEVEL: #{l}"
      types = l.map do |i| 
        begin
          i.ttype
        rescue
          i
        end
      end
      types
    end
    
  end

  t = nil
  while true
    begin
      t = iter.next
      if t != nil
        break
      end
    rescue StopIteration
      break
    end
  end
  # end search for bad types
  t

end
      # extract current type tree
=begin
        if i.class == TypedNode
          if [:true, :false].include?(i.type) 
            puts "BOOL TYPE: #{i.ttype} type: #{i.type}"
            top_store.append(:bool)
            :bool
          elsif i.to_s == "lvar" && tenvd.keys.include?(i.children)
            puts "called argtype"
            top_store.append(tenvd[i])
            tenvd[i]
          elsif i.type.to_s == "send"
            puts "sendtype: #{i.ttype}"
            puts "called send type"
            if i.ttype == nil 
              i.type
            else
              i.ttype
            end
          else
            i.type
          end
        else 
          i
        end
      end
    end
=end
    

  
  # end iterator block arg
  



=begin
def correcct_method(ast, tenvd, good_types, suspect_methods, expected_ret)
  # for tests that didn't fail the type checking procedure. 
  # or perhaps

  extracted_methods = Set.new
  # we need to extract the types that we know work. 
  if ast.class == TypedNode
    if ast.type == :send # recurse
      
      klass, good_types = correct_mthds(ast.children[0], good_types, suspect_methods)
      mthd, good_types = correct_mthds(ast.children[1], good_types, suspect_methods)
      args = []
      if ast.children.size > 2 # not an empty arg method

        ast.children[2 ...].each do |i|
          a, good_types = correct_mthds(ast.children[1], good_types, suspect_methods)
          args.append(a)
        end
      end
      
      if suspect_methods.any? {|i| i == mthd} # if if the suspect methd
        good_types.add([klass, mthd] + args)
      end

      rettype = 
    end 
    

    else # must be a singleton or unitary type
      return ast.type
    end
  
  end


end
=end