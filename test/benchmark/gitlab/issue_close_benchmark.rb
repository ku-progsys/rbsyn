# https://github.com/gitlabhq/gitlabhq/blob/13150a38e701080f6c64d4925c838214a3f5ef2c/spec/models/issue_spec.rb#L145-L158

require "test_helper"

describe "Gitlab" do
  it 'issue#close' do
    load_typedefs :stdlib, :active_record
    # AI generated: %dyn declaration window; only what is declared here (plus types learned during the run) is visible
    ParentsHelper.init_list() # AI generated
    RDL.type :DynamicType, :state_id=, '(%dyn) -> %dyn', wrap: false, write: ['self'] # AI generated
    RDL.type :DynamicType, :'self.available_states', '() -> %dyn', wrap: false # AI generated
    RDL.type :DynamicType, :[], '(%dyn) -> %dyn', wrap: false # AI generated
    RDL.type :DynamicType, :closed_at=, '(%dyn) -> %dyn', wrap: false, write: ['self'] # AI generated
    RDL.type :DynamicType, :'self.now', '() -> %dyn', wrap: false # AI generated
    RDL.type :DynamicType, :state_id, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :closed_at, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    ParentsHelper.subtract() # AI generated

    # RDL.type Time, 'self.now', '() -> Time'  # AI altered: concrete type; the method is declared as a %dyn placeholder in the ParentsHelper window
    # RDL.type GitlabIssue, 'self.available_states', '() -> { opened: Integer, closed: Integer }'  # AI altered: concrete type; the method is declared as a %dyn placeholder in the ParentsHelper window

    # define :close, '(GitlabIssue) -> %bot', [GitlabIssue, Time] do
    # AI altered: %dyn conversion (methods of interest = vanilla's solution + assertion calls; hashkeys = model columns)
    define :close, '(GitlabIssue) -> %bot', [GitlabIssue, Time], moi: [:state_id=, :available_states, :[], :closed_at=, :now, :state_id, :closed_at] do # AI generated
      spec "changes the state to closed" do
        setup {
          @issue = Fabricate(:issue)
          @prev_state = @issue.state_id
          close(@issue)
        }

        post { |result|
          assert { @prev_state == GitlabIssue.available_states[:opened] }
          assert { @issue.state_id == GitlabIssue.available_states[:closed] }
          assert { @issue.closed_at != nil }
        }
      end

      generate_program
    end
  end
end
