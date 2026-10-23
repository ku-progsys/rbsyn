# disabled last test because no way to test it

require "test_helper"

describe "Diaspora" do
  it "pod#schedule_check_if_needed" do
    # load_typedefs :stdlib, :ar_update

    # RDL.type DiasporaPod, 'self.status_codes', '() -> { unchecked: Integer, no_errors: Integer, net_failed: Integer }', wrap: false
    # RDL.type Integer, :!=, '(Integer) -> %bool', wrap: false
    # RDL.type Integer, :==, '(Integer) -> %bool', wrap: false

    ParentsHelper.init_list()
    RDL.type :DynamicType, :'self.status_codes', '() -> %dyn', wrap: false # you probably need to add functionallity to handle the .self and only check the components. 
    RDL.type :DynamicType, :!=, '(%dyn) -> %dyn', wrap: false
    RDL.type :DynamicType, :==, '(%dyn) -> %dyn', wrap: false

    #MANUALLY ADDED vv
    RDL.type :DynamicType, :update!, "(%dyn) -> %dyn", wrap: false, write: ['self']
    # RDL.type :DynamicType, :status, '() -> %dyn', wrap: false  # AI altered: getter needs its read effect
    RDL.type :DynamicType, :status, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :[], '(%dyn) -> %dyn', wrap: false # AI generated: vanilla's solution uses DiasporaPod.status_codes.[](:unchecked)
    # AI generated: methods the assertions call (!!@pod.reload.scheduled_check == ...)
    RDL.type :DynamicType, :reload, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :scheduled_check, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :!, '() -> %dyn', wrap: false # AI generated
    ParentsHelper.subtract()

    # define :schedule_check_if_needed, "(DiasporaPod) -> %bool", [DiasporaPod], prog_size: 50, moi: [:!=, :==, :update!, :"self.status_codes", :status] do
    # AI altered: calls are written DiasporaPod.status_codes, so the moi name is :status_codes (:"self.status_codes" never matches
    # a call); added :[]; added hashkeys (all DiasporaPod columns) so update!(scheduled_check: true) can be built
    # define :schedule_check_if_needed, "(DiasporaPod) -> %bool", [DiasporaPod, {hashkeys: [:id, :updated_at, :scheduled_check, :status]}], prog_size: 50, moi: [:!=, :==, :update!, :status_codes, :status, :[], :reload, :scheduled_check, :!] do # AI generated
    # AI altered: symbols the solution needs as bare arguments are given as constant components (depth-0 fills)
    define :schedule_check_if_needed, "(DiasporaPod) -> %bool", [DiasporaPod, :unchecked, :no_errors, {hashkeys: [:id, :updated_at, :scheduled_check, :status]}], prog_size: 50, moi: [:!=, :==, :update!, :status_codes, :status, :[], :reload, :scheduled_check, :!] do # AI generated
      spec "schedules the pod for the next check if it is offline" do
        setup {
          @pod = Fabricate(:pod, status: :net_failed)
          schedule_check_if_needed(@pod)
        }

        post { |result|
          assert { !!@pod.reload.scheduled_check == true}
        }
      end

      spec "does nothing if the pod unchecked" do
        setup {
          @pod = Fabricate(:pod)
          schedule_check_if_needed(@pod)
        }

        post { |result|
          assert { !!@pod.scheduled_check == false }
        }
      end

      spec "does nothing if the pod is online" do
        setup {
          @pod = Fabricate(:pod, status: :no_errors)
          schedule_check_if_needed(@pod)
        }

        post { |result|
          assert { !!@pod.scheduled_check == false }
        }
      end

      # spec "does nothing if the pod is scheduled for the next check" do
      #   setup {
      #     @pod = Fabricate(:pod, status: :no_errors, scheduled_check: true)
      #     @old_updated = @pod.updated_at
      #     schedule_check_if_needed(@pod)
      #   }

      #   post { |result|
      #     assert { @pod.updated_at == @old_updated }
      #   }
      # end

      generate_program
    end
  end
end
