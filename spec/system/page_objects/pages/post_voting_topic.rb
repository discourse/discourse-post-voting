# frozen_string_literal: true
module PageObjects
  module Pages
    class PostVotingTopic < PageObjects::Pages::Topic
      POST_VOTING_CONTROLS = ".topic-avatar .post-voting-post"
      POST_COMMENTS = ".post-voting-comments"
      ADD_COMMENT_BUTTON = "#{POST_COMMENTS} button.post-voting-comment-add-link"
      SUBMIT_COMMENT_BUTTON = "#{POST_COMMENTS} button.post-voting-comments-menu-composer-submit"

      def post_vote_count(post_number)
        find("#post_#{post_number} #{POST_VOTING_CONTROLS} .post-voting-post-toggle-voters")
      end

      def find_comment(post_number, comment_number)
        find("#post_#{post_number} .post-voting-comment:nth-child(#{comment_number})")
      end

      def upvote(post_number)
        find("#post_#{post_number} #{POST_VOTING_CONTROLS} .post-voting-button-upvote").click
        self
      end

      def downvote(post_number)
        find("#post_#{post_number} #{POST_VOTING_CONTROLS} .post-voting-button-downvote").click
        self
      end

      def click_add_comment(post_number)
        find("#post_#{post_number} #{ADD_COMMENT_BUTTON}").click
        self
      end

      def click_submit_comment(post_number)
        find("#post_#{post_number} #{SUBMIT_COMMENT_BUTTON}").click
        self
      end

      def fill_comment(post_number, content)
        find("#post_#{post_number} .post-voting-comment-composer-textarea").fill_in(with: content)
        self
      end
    end
  end
end
