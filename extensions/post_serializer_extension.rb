# frozen_string_literal: true

module QuestionAnswer
  module PostSerializerExtension
    def comments
      (@topic_view.comments[object.post_number] || []).map do |post|
        QaCommentPostSerializer.new(post, scope: scope, root:false).as_json
      end
    end

    def include_comments?
      @topic_view && qa_enabled
    end

    def comments_count
      @topic_view.comments_counts&.dig(object.id) || 0
    end

    def include_comments_count?
      @topic_view && qa_enabled
    end

    def qa_disable_like
      return true if SiteSetting.qa_disable_like_on_answers
      return !!category.qa_disable_like_on_questions if object.post_number == 1
      return !!category.qa_disable_like_on_comments if object.reply_to_post_number
      retrun !!category.qa_disable_like_on_answers
    end

    alias_method :include_qa_disable_like?, :include_comments?

    def qa_enabled
      @topic_view ? @topic_view.qa_enabled : object.qa_enabled
    end

    private

    def topic
      @topic_view ? @topic_view.topic : object.topic
    end

    def category
      topic.category
    end
  end
end
