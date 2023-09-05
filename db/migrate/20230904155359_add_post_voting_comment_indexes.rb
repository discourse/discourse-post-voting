# frozen_string_literal: true

class AddPostVotingCommentIndexes < ActiveRecord::Migration[7.0]
  def change
    add_index :post_voting_comments, :post_id
    add_index :post_voting_comments, :user_id
    add_index :post_voting_comments, :deleted_by_id, where: "deleted_by_id IS NOT NULL"
  end
end
