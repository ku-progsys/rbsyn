
# finish this later


# def extract_params(klass, name)

#    # 1) class attribute-like: a zero-arg singleton method defined directly on the class
#   if klass.singleton_methods(false).map(&:to_sym).include?(name)
#     m = klass.method(name) rescue nil
#     return "" if m && m.parameters.empty?
#   end

#   # 2) class (singleton) method (including inherited)
#   if klass.respond_to?(name)
#     begin
#       m = klass.method(name) rescue nil
#       return m.parameters
#     rescue
#       return None
#     end

#   end

#   # 3) instance attribute-like: a zero-arg instance method defined directly on the class
#   if klass.instance_methods(false).map(&:to_sym).include?(name)
#     um = klass.instance_method(name) rescue nil
#     return "" if um && um.parameters.empty?
#   end

#   # 4) instance method (including inherited)
#   if klass.instance_methods.map(&:to_sym).include?(name)
#     um = klass.instance_method(name) rescue nil
#     return nil unless um
#     return fmt.call(um.parameters)
#   end

#   nil
# end

include RDL::Globals
class ParentsHelper
  
  @@parents = []
  @@flag = false

  def self.init_list()
    @@parents = RDL::Globals.info.info.keys()
  end

  def self.subtract()
    @@parents = RDL::Globals.info.info.keys() - @@parents
    @@parents.append("Object") unless @@parents.include?("Object")
    @@parents.append("BasicObject") unless @@parents.include?("BasicObject")
    @@parents.append("DynamicType") unless @@parents.include?("DynamicType")
    self.setFlag
  end


  def self.addTypeManually(typeSigStr)
    RDL.nowrap typeSigStr unless @@parents.include?(typeSigStr)
    @@parents.append(typeSigStr) unless @@parents.include?(typeSigStr)
     
    return
  end


  def self.getParents()
    if @@flag
      return @@parents
    else 
      return RDL::Globals.info.info.keys()
    end
  end

  def self.setFlag()
    @@flag = true
  end
  
end