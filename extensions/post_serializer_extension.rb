# frozen_string_literal: true

module Upvotes
  module PostSerializerExtension
    def self.included(base)
      base.attributes(
        :upvotes_vote_count,
        :upvotes_user_voted_direction,
        :upvotes_has_votes,
        :comments,
        :comments_count,
      )
    end

    def upvotes_vote_count
      object.qa_vote_count
    end

    def include_upvotes_vote_count?
      object.is_upvotes_topic?
    end

    def comments
      (@topic_view.comments[object.id] || []).map do |comment|
        serializer = QuestionAnswerCommentSerializer.new(comment, scope: scope, root: false)
        serializer.comments_user_voted = @topic_view.comments_user_voted
        serializer.as_json
      end
    end

    def include_comments?
      @topic_view && object.is_upvotes_topic?
    end

    def comments_count
      @topic_view.comments_counts&.dig(object.id) || 0
    end

    def include_comments_count?
      @topic_view && object.is_upvotes_topic?
    end

    def upvotes_user_voted_direction
      @topic_view.posts_user_voted[object.id]
    end

    def include_upvotes_user_voted_direction?
      @topic_view && object.is_upvotes_topic? && @topic_view.posts_user_voted.present?
    end

    def upvotes_has_votes
      @topic_view.posts_voted_on.include?(object.id)
    end

    def include_upvotes_has_votes?
      @topic_view && object.is_upvotes_topic?
    end

    private

    def topic
      @topic_view ? @topic_view.topic : object.topic
    end
  end
end
