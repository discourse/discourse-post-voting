# frozen_string_literal: true

require "migration/table_dropper"

class RenameQuestionAnswerVoteTable < ActiveRecord::Migration[7.0]
  def up
    unless table_exists?(:post_voting_votes)
      Migration::TableDropper.read_only_table(:question_answer_votes)
      execute <<~SQL
        CREATE TABLE post_voting_votes
        (LIKE question_answer_votes INCLUDING ALL);
      SQL

      execute <<~SQL
        INSERT INTO post_voting_votes
        SELECT *
        FROM question_answer_votes
      SQL

      execute <<~SQL
        ALTER SEQUENCE question_answer_votes_id_seq
        RENAME TO post_voting_votes_id_seq
      SQL

      execute <<~SQL
        ALTER SEQUENCE post_voting_votes_id_seq
        OWNED BY post_voting_votes.id
      SQL

      add_index :post_voting_votes,
                %i[votable_type votable_id user_id],
                unique: true,
                name: "post_voting_votes_votable_type_and_votable_id_and_user_id_idx"
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
