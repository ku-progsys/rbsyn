
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
  @@preexisting = {} # AI generated: {klass => {meth => {kind => entry count}}} as of init_list
  @@blocked = {}     # AI generated: pre-window RDL entries removed by subtract, kept here (unused by the synthesizer)

  def self.init_list()
    @@parents = RDL::Globals.info.info.keys()
    @@preexisting = snapshot_rdl_info() # AI generated
  end

  # AI generated: record how many entries each class/method/kind has before the declaration window,
  # so subtract can tell pre-existing (library, schema, typedef) entries from ones declared in the window
  def self.snapshot_rdl_info() # AI generated
    RDL::Globals.info.info.each_with_object({}) { |(klass, meths), snap|
      snap[klass] = meths.each_with_object({}) { |(meth, kinds), m|
        m[meth] = kinds.each_with_object({}) { |(kind, val), k| k[kind] = val.is_a?(Array) ? val.size : :scalar }
      }
    }
  end

  # AI generated: remove every RDL entry that existed before init_list, so the synthesizer only sees
  # what was declared between init_list and subtract plus whatever type inference registers later.
  # Array-valued kinds (:type, :effect, :read, :write) are cut back to the entries added in the window;
  # a method the window did not add anything to is removed entirely.
  def self.block_preexisting_types() # AI generated
    info = RDL::Globals.info.info
    @@blocked = {}
    @@preexisting.each { |klass, meths|
      next unless info.key?(klass)
      meths.each { |meth, kinds|
        cur = info[klass][meth]
        next if cur.nil?
        added_in_window = kinds.any? { |kind, n| n != :scalar && cur[kind].is_a?(Array) && cur[kind].size > n }
        (@@blocked[klass] ||= {})[meth] = Marshal.load(Marshal.dump(cur)) rescue ((@@blocked[klass] ||= {})[meth] = cur)
        if added_in_window
          kinds.each { |kind, n| cur[kind] = cur[kind].drop(n) if n != :scalar && cur[kind].is_a?(Array) }
        else
          info[klass].delete(meth)
        end
      }
      info.delete(klass) if info[klass].empty?
    }
    @@blocked
  end

  def self.blocked() # AI generated
    @@blocked
  end

  def self.subtract()
    @@parents = RDL::Globals.info.info.keys() - @@parents
    @@parents.append("Object") unless @@parents.include?("Object")
    @@parents.append("BasicObject") unless @@parents.include?("BasicObject")
    @@parents.append("DynamicType") unless @@parents.include?("DynamicType")
    self.setFlag
    self.block_preexisting_types() # AI generated
    # >>> INSTRUMENTATION K (AI generated, remove) >>>
    if ENV["DBG_DYN"]
      warn "[K] blocked #{@@blocked.values.sum(&:size)} methods on #{@@blocked.size} classes; visible after subtract:"
      RDL::Globals.info.info.each { |klass, meths| warn "[K]   #{klass}: #{meths.map { |m, k| "#{m}#{k[:type] ? k[:type].map(&:to_s).inspect : ''}#{k[:write] ? ' w' + k[:write].inspect : ''}#{k[:read] ? ' r' + k[:read].inspect : ''}" }.join('; ')[0, 600]}" }
    end
    # <<< INSTRUMENTATION K <<<
  end


  def self.addTypeManually(typeSigStr)
    if !(typeSigStr == "nil")
      RDL.nowrap typeSigStr unless @@parents.include?(typeSigStr)
      @@parents.append(typeSigStr) unless @@parents.include?(typeSigStr)
    end
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