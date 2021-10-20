# frozen_string_literal: true

module QuestionAnswer
  module PostExtension
    def self.included(base)
      base.ignored_columns = %w[vote_count]
      base.after_create :qa_update_vote_order, if: :qa_enabled

      base.has_many :question_answer_votes
    end

    def qa_vote_count(fields = custom_fields)
      if vote_count = fields['qa_vote_count']
        [*vote_count].first.to_i
      else
        0
      end
    end

    def qa_enabled
      ::Topic.qa_enabled(topic)
    end

    def qa_update_vote_order
      ::Topic.qa_update_vote_order(topic_id)
    end

    def qa_last_voted(user_id)
      QuestionAnswerVote
        .where(post_id: self.id, user_id: user_id)
        .order(created_at: :desc)
        .pluck_first(:created_at)
    end

    def qa_can_vote(user_id)
      SiteSetting.qa_tl_allow_multiple_votes_per_post ||
        !QuestionAnswerVote.exists?(post_id: self.id, user_id: user_id)
    end

    def comments
      topic
        .posts
        .where(reply_to_post_number: self.post_number)
        .order('post_number ASC')
    end
  end
end
