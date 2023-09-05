# frozen_string_literal: true

class PostVotingCommentSerializer < ApplicationSerializer
  attributes :id,
             :user_id,
             :name,
             :username,
             :created_at,
             :raw,
             :cooked,
             :post_voting_vote_count,
             :user_voted

  attr_accessor :comments_user_voted

  def name
    object.user&.name
  end

  def username
    object.user&.username
  end

  def user_voted
    if @comments_user_voted
      @comments_user_voted[object.id]
    else
      scope.present? && object.votes.exists?(user: scope.user)
    end
  end

  def post_voting_vote_count
    object.qa_vote_count
  end
end
