# frozen_string_literal: true

module QuestionAnswer
  module PostSerializerExtension
    def actions_summary
      summaries = super.reject { |s| s[:id] == PostActionType.types[:vote] }

      return summaries unless self.qa_enabled

      user = scope.current_user
      summary = {
        id: PostActionType.types[:vote],
        count: object.qa_vote_count
      }

      if user
        voted =
          if @topic_view
            @topic_view.user_voted_posts(user).include?(object.id)
          else
            QuestionAnswerVote.exists?(post_id: object.id, user_id: user.id)
          end

        if voted
          summary[:acted] = true
          summary[:can_undo] = QuestionAnswer::Vote.can_undo(object, user)
        else
          summary[:can_act] = true
        end
      end

      summary.delete(:count) if summary[:count].zero?

      if summary[:can_act] || summary[:count]
        summaries + [summary]
      else
        summaries
      end
    end

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

    def qa_enabled
      @topic_view ? @topic_view.qa_enabled : object.qa_enabled
    end
  end
end
