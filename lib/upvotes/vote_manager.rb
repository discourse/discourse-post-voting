# frozen_string_literal: true

module Upvotes
  class VoteManager
    def self.vote(obj, user, direction: nil)
      direction ||= QuestionAnswerVote.directions[:up]

      ActiveRecord::Base.transaction do
        existing_vote = QuestionAnswerVote.find_by(
          user: user,
          votable: obj,
          direction: QuestionAnswerVote.reverse_direction(direction)
        )

        count_change =
          if existing_vote
            QuestionAnswerVote.directions[:up] == direction ? 2 : -2
          else
            QuestionAnswerVote.directions[:up] == direction ? 1 : -1
          end

        existing_vote.destroy! if existing_vote

        vote = QuestionAnswerVote.create!(
          user: user,
          votable: obj,
          direction: direction
        )

        vote_count = (obj.qa_vote_count || 0) + count_change

        obj.update!(qa_vote_count: vote_count)

        DB.after_commit do
          publish_changes(obj, user, vote_count, direction)
        end

        vote
      end
    end

    def self.remove_vote(obj, user)
      ActiveRecord::Base.transaction do
        vote = QuestionAnswerVote.find_by(votable: obj, user: user)
        direction = vote.direction
        vote.destroy!
        count_change = QuestionAnswerVote.directions[:up] == direction ? -1 : 1
        vote_count = obj.qa_vote_count + count_change
        obj.update!(qa_vote_count: vote_count)

        DB.after_commit do
          publish_changes(obj, user, vote_count, nil)
        end
      end
    end

    def self.can_undo(post, user)
      return true if post.upvotes_last_voted(user.id).blank?
      window = SiteSetting.upvotes_undo_vote_action_window.to_i
      window.zero? || post.upvotes_last_voted(user.id).to_i > window.minutes.ago.to_i
    end

    def self.publish_changes(obj, user, vote_count, direction)
      if obj.is_a?(Post)
        obj.publish_change_to_clients!(:upvotes_post_voted,
          upvotes_user_voted_id: user.id,
          upvotes_vote_count: vote_count,
          upvotes_user_voted_direction: direction,
          upvotes_has_votes: QuestionAnswerVote.exists?(votable: obj)
        )
      end
    end
  end
end
