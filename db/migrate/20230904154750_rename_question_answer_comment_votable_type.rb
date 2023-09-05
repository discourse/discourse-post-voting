# frozen_string_literal: true

class RenameQuestionAnswerCommentVotableType < ActiveRecord::Migration[7.0]
  def up
    execute <<~SQL
      UPDATE question_answer_votes
      SET votable_type = 'PostVotingComment'
      WHERE votable_type = 'QuestionAnswerComment'
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
