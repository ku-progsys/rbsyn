# https://github.com/gitlabhq/gitlabhq/blob/13150a38e701080f6c64d4925c838214a3f5ef2c/spec/models/issue_spec.rb#L160-L175

require "test_helper"

describe "Gitlab" do
  it 'issue#reopen' do
    load_typedefs :stdlib, :active_record
    RDL.type Time, 'self.now', '() -> Time' # AI generated (2026-10-21): vanilla declares it; before the window so it is blocked like library methods and enters the ablation pool
    # AI generated: %dyn declaration window; only what is declared here (plus types learned during the run) is visible
    ParentsHelper.init_list() # AI generated
    RDL.type :DynamicType, :closed_at=, '(%dyn) -> %dyn', wrap: false, write: ['self'] # AI generated
    RDL.type :DynamicType, :closed_by_id=, '(%dyn) -> %dyn', wrap: false, write: ['self'] # AI generated
    RDL.type :DynamicType, :state_id=, '(%dyn) -> %dyn', wrap: false, write: ['self'] # AI generated
    RDL.type :DynamicType, :'self.available_states', '() -> %dyn', wrap: false # AI generated
    RDL.type :DynamicType, :[], '(%dyn) -> %dyn', wrap: false # AI generated
    RDL.type :DynamicType, :closed_at, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :closed_by, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :state_id, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    ParentsHelper.subtract() # AI generated

    # RDL.type Time, 'self.now', '() -> Time'  # AI altered: concrete type; the method is declared as a %dyn placeholder in the ParentsHelper window
    # RDL.type GitlabIssue, 'self.available_states', '() -> { opened: Integer, closed: Integer }'  # AI altered: concrete type; the method is declared as a %dyn placeholder in the ParentsHelper window

    # define :reopen, '(GitlabIssue) -> %bot', [GitlabIssue, Time], enable_nil: true do
    # AI altered: %dyn conversion (methods of interest = vanilla's solution + assertion calls; hashkeys = model columns)
    define :reopen, '(GitlabIssue) -> %bot', [GitlabIssue, Time], enable_nil: true, moi: [:closed_at=, :closed_by_id=, :state_id=, :available_states, :[], :closed_at, :closed_by, :state_id] do # AI generated
      spec "changes the state to closed" do
        setup {
          @user = Fabricate(:gitlab_user)
          @issue = Fabricate(:issue, state: 'closed', closed_at: Time.now, closed_by: @user)
          @prev_state = @issue.state_id
          @prev_user = @issue.closed_by
          reopen(@issue)
        }

        post { |result|
          assert { @issue.closed_at == nil }
          assert { @prev_user == @user }
          assert { @issue.closed_by == nil }
          assert { @prev_state == GitlabIssue.available_states[:closed] }
          assert { @issue.state_id == GitlabIssue.available_states[:opened] }
        }
      end

      generate_program
    end
  end
end
