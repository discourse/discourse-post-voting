# frozen_string_literal: true

module Upvotes
  module PostExtension
    def self.included(base)
      base.ignored_columns = %w[vote_count]

      base.has_many :question_answer_votes, as: :votable, dependent: :delete_all
      base.has_many :question_answer_comments, dependent: :destroy
      base.validate :ensure_only_replies
    end

    def is_upvotes_topic?
      topic.is_upvotes?
    end

    def upvotes_last_voted(user_id)
      QuestionAnswerVote
        .where(votable: self, user_id: user_id)
        .order(created_at: :desc)
        .pluck_first(:created_at)
    end

    def upvotes_can_vote(user_id, direction = nil)
      direction ||= QuestionAnswerVote.directions[:up]
      !QuestionAnswerVote.exists?(votable: self, user_id: user_id, direction: direction)
    end

    def comments
      topic
        .posts
        .where(reply_to_post_number: self.post_number)
        .order('post_number ASC')
    end

    private

    def ensure_only_replies
      if will_save_change_to_reply_to_post_number? &&
          reply_to_post_number &&
          reply_to_post_number != 1 &&
          is_upvotes_topic?

        errors.add(:base, I18n.t("post.upvotes.errors.replying_to_post_not_permited"))
      end
    end
  end
end
