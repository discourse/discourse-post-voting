# frozen_string_literal: true

module PostVoting
  class CommentCreator
    def self.create(attributes)
      qa_comment = QuestionAnswerComment.new(attributes)

      ActiveRecord::Base.transaction do
        if qa_comment.save
          create_commented_notification(qa_comment)

          DB.after_commit do
            publish_changes(qa_comment)
          end
        end
      end

      qa_comment
    end

    def self.publish_changes(qa_comment)
      Scheduler::Defer.later "Publish new Q&A comment" do
        qa_comment.post.publish_change_to_clients!(
          :qa_post_commented,
          comment: QuestionAnswerCommentSerializer.new(qa_comment, root: false).as_json,
          comments_count: QuestionAnswerComment.where(post_id: qa_comment.post_id).count
        )
      end
    end

    def self.create_commented_notification(qa_comment)
      return if qa_comment.user_id == qa_comment.post.user_id

      Notification.create!(
        notification_type: Notification.types[:question_answer_user_commented],
        user_id: qa_comment.post.user_id,
        post_number: qa_comment.post.post_number,
        topic_id: qa_comment.post.topic_id,
        data: {
          qa_comment_id: qa_comment.id,
          display_username: qa_comment.user.username
        }.to_json,
      )

      PostAlerter.create_notification_alert(
        user: qa_comment.post.user,
        post: qa_comment.post,
        notification_type: Notification.types[:question_answer_user_commented],
        username: qa_comment.user.username
      )
    end
  end
end
