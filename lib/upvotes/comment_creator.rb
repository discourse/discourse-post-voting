# frozen_string_literal: true

module Upvotes
  class CommentCreator
    def self.create(attributes)
      upvotes_comment = QuestionAnswerComment.new(attributes)

      ActiveRecord::Base.transaction do
        if upvotes_comment.save
          create_commented_notification(upvotes_comment)

          DB.after_commit do
            publish_changes(upvotes_comment)
          end
        end
      end

      upvotes_comment
    end

    def self.publish_changes(upvotes_comment)
      Scheduler::Defer.later "Publish new Q&A comment" do
        upvotes_comment.post.publish_change_to_clients!(
          :upvotes_post_commented,
          comment: QuestionAnswerCommentSerializer.new(upvotes_comment, root: false).as_json,
          comments_count: QuestionAnswerComment.where(post_id: upvotes_comment.post_id).count
        )
      end
    end

    def self.create_commented_notification(upvotes_comment)
      return if upvotes_comment.user_id == upvotes_comment.post.user_id

      Notification.create!(
        notification_type: Notification.types[:question_answer_user_commented],
        user_id: upvotes_comment.post.user_id,
        post_number: upvotes_comment.post.post_number,
        topic_id: upvotes_comment.post.topic_id,
        data: {
          upvotes_comment_id: upvotes_comment.id,
          display_username: upvotes_comment.user.username
        }.to_json,
      )

      PostAlerter.create_notification_alert(
        user: upvotes_comment.post.user,
        post: upvotes_comment.post,
        notification_type: Notification.types[:question_answer_user_commented],
        username: upvotes_comment.user.username
      )
    end
  end
end
