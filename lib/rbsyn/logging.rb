
# logging.rb


def logf(func, names, *args)
    flag = ENV['LOG']
    unless flag && flag.downcase == 'false'
        t = names.split(",").map(&:strip)
        puts "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n------------\nCALLED >>>#{func}<<< WITH ARGS:"

        (0 ... t.size).each do |i|
            puts "#{t[i]}:\n#{args[i]}\n"
            if args[i].respond_to?(:each)
                if args[i].size == 0
                    puts "ISEMPTY"
                else
                    puts ">>>>>>    SUBCONTAINS:+++++++++"
                    args[i].each do |k|
                        puts ">>>>>>    #{k}\n>>>>>>    ++++++++++"
                    end
                    puts ">>>>>>    END SUBCONTAINS++++++++"
                end
            end
            puts "-----------------"
        end
        puts"END >>>#{func}<<< LOGGING\n-----------------\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n"
    end
end


def callf(func, names, *args)
    flag = ENV['LOG']
    unless flag && flag.downcase == 'false'
        t = names.split(",").map(&:strip)
        puts "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n------------\nCALLING >>>#{func}<<< WITH ARGS:"
        
        (0 ... t.size).each do |i|
            puts "#{t[i]}:\n#{args[i]}\n"
            if args[i].respond_to?(:each)
                if args[i].size == 0
                    puts "ISEMPTY"
                else
                    puts ">>>>>>    SUBCONTAINS:+++++++++"
                    args[i].each do |k|
                        puts ">>>>>  #{k}\n>>>>>>   ++++++++++"
                    end
                    puts ">>>>>>    END SUBCONTAINS++++++++"
                end
            end
            puts "-----------------"
        end
        puts"END >>>#{func}<<< CALLING LOGGING\n-----------------\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n"
    end
end