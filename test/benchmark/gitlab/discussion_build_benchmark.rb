# https://github.com/gitlabhq/gitlabhq/blob/13150a38e701080f6c64d4925c838214a3f5ef2c/spec/models/issue_spec.rb#L160-L175

require "test_helper"

describe "Gitlab" do
  it 'discussion#build' do
    load_typedefs :stdlib, :active_record
    # AI generated: %dyn declaration window; only what is declared here (plus types learned during the run) is visible
    ParentsHelper.init_list() # AI generated
    RDL.type :DynamicType, :'self.new', '() -> %dyn', wrap: false # AI generated
    RDL.type :DynamicType, :save, '() -> %dyn', wrap: false, write: ['*'] # AI generated
    RDL.type :DynamicType, :notes=, '(%dyn) -> %dyn', wrap: false, write: ['self'] # AI generated
    RDL.type :DynamicType, :noteable_id=, '(%dyn) -> %dyn', wrap: false, write: ['self'] # AI generated
    RDL.type :DynamicType, :id, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :is_a?, '(%dyn) -> %dyn', wrap: false # AI generated
    RDL.type :DynamicType, :notes, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :count, '() -> %dyn', wrap: false # AI generated
    RDL.type :DynamicType, :first_note, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    RDL.type :DynamicType, :noteable, '() -> %dyn', wrap: false, read: ['self'] # AI generated
    ParentsHelper.subtract() # AI generated
    # RDL.type Array, :first, '() -> t', wrap: false  # AI altered: concrete type; the method is declared as a %dyn placeholder in the ParentsHelper window
    # RDL.type GitlabDiscussion, 'self.new', '() -> GitlabDiscussion', wrap: false  # AI altered: concrete type; the method is declared as a %dyn placeholder in the ParentsHelper window
    # RDL.type GitlabDiscussion, :noteable, '() -> GitlabMergeRequest', wrap: false, read: ['GitlabDiscussion']  # AI altered: concrete type; the method is declared as a %dyn placeholder in the ParentsHelper window

    # define :build, '(Array<GitlabNote>, GitlabMergeRequest) -> GitlabDiscussion', [GitlabDiscussion, GitlabMergeRequest, GitlabNote], prog_size: 30 do
    # AI altered: %dyn conversion (methods of interest = vanilla's solution + assertion calls; hashkeys = model columns)
    define :build, '(Array<GitlabNote>, GitlabMergeRequest) -> GitlabDiscussion', [GitlabDiscussion, GitlabMergeRequest, GitlabNote], prog_size: 30, moi: [:new, :save, :notes=, :noteable_id=, :id, :is_a?, :notes, :count, :first_note, :noteable] do # AI generated
      spec 'returns a discussion of the right type' do
        setup {
          @first_note = Fabricate(:diff_note_on_merge_request)
          @merge_request = @first_note.noteable
          second_note = Fabricate(:diff_note_on_merge_request, in_reply_to: @first_note)
          build([@first_note, second_note], @merge_request)
        }

        post { |discussion|
          assert { discussion.is_a? GitlabDiscussion }
          assert { discussion.notes.count == 2 }
          assert { discussion.first_note == @first_note }
          assert { discussion.noteable == @merge_request }
        }
      end

      generate_program
    end
  end
end
