# frozen_string_literal: true

require "migration/table_dropper"

class RenameQuestionAnswerCommentTable < ActiveRecord::Migration[7.0]
  def up
    unless table_exists?(:post_voting_comments)
      Migration::TableDropper.read_only_table(:question_answer_comments)
      execute <<~SQL
        CREATE TABLE post_voting_comments
        (LIKE question_answer_comments INCLUDING ALL);
      SQL

      execute <<~SQL
        INSERT INTO post_voting_comments
        SELECT *
        FROM question_answer_comments
      SQL

      execute <<~SQL
        ALTER SEQUENCE question_answer_comments_id_seq
        RENAME TO post_voting_comments_id_seq
      SQL

      execute <<~SQL
        ALTER SEQUENCE post_voting_comments_id_seq
        OWNED BY post_voting_comments.id
      SQL
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
