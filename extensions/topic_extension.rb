# frozen_string_literal: true

module QuestionAnswer
  module TopicExtension
    def self.included(base)
      base.extend(ClassMethods)
    end

    def reload(options = nil)
      @answers = nil
      @comments = nil
      @last_answerer = nil
      super(options)
    end

    def answers
      @answers ||= begin
        posts
          .where(reply_to_post_number: nil)
          .where.not(post_number: 1)
          .order(post_number: :asc)
      end
    end

    def answer_count
      answers.count
    end

    def last_answered_at
      return unless answers.present?

      answers.last[:created_at]
    end

    def comments
      @comments ||= begin
        QuestionAnswerComment.joins(:post).where("posts.topic_id = ?", self.id)
      end
    end

    def last_commented_on
      return unless comments.present?

      comments.last.created_at
    end

    def last_answer_post_number
      return unless answers.any?

      answers.last.post_number
    end

    def last_answerer
      return unless answers.any?

      @last_answerer ||= User.find(answers.last[:user_id])
    end

    def qa_enabled
      Topic.qa_enabled(self)
    end

    # class methods
    module ClassMethods
      # rename to something like qa_user_votes?
      def qa_votes(topic, user)
        return nil if !user || !SiteSetting.qa_enabled

        # This is a very inefficient way since the performance degrades as the
        # number of voted posts in the topic increases.
        QuestionAnswerVote
          .joins("INNER JOIN posts ON posts.id = question_answer_votes.votable_id")
          .where(user: user, votable_type: 'Post')
          .where("posts.topic_id = ?", topic.id)
      end

      def qa_enabled(topic)
        return false unless SiteSetting.qa_enabled
        return false if !topic
        return false if topic.category && topic.category.topic_id == topic.id

        tags = topic.tags.map(&:name)
        !(tags & SiteSetting.qa_tags.split('|')).empty?
      end
    end
  end
end
