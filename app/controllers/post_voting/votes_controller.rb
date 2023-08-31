# frozen_string_literal: true

module PostVoting
  class VotesController < ::ApplicationController
    before_action :ensure_logged_in
    before_action :find_vote_post, only: %i[create destroy voters]
    before_action :ensure_can_see_post, only: %i[create destroy voters]
    before_action :ensure_post_voting_enabled, only: %i[create destroy]

    def create
      ensure_can_vote(@post)

      if PostVoting::VoteManager.vote(@post, current_user, direction: vote_params[:direction])
        render json: success_json
      else
        render json: failed_json, status: 422
      end
    end

    def create_comment_vote
      comment = find_comment
      ensure_can_see_comment!(comment)
      ensure_can_vote(comment)

      if PostVoting::VoteManager.vote(
           comment,
           current_user,
           direction: QuestionAnswerVote.directions[:up],
         )
        render json: success_json
      else
        render json: failed_json, status: 422
      end
    end

    def destroy
      if !Topic.post_voting_votes(@post.topic, current_user).exists?
        raise Discourse::InvalidAccess.new(
                nil,
                nil,
                custom_message: "vote.error.user_has_not_voted",
              )
      end

      if !PostVoting::VoteManager.can_undo(@post, current_user)
        msg =
          I18n.t(
            "vote.error.undo_vote_action_window",
            count: SiteSetting.post_voting_undo_vote_action_window.to_i,
          )

        render_json_error(msg, status: 403)

        return
      end

      if PostVoting::VoteManager.remove_vote(@post, current_user)
        render json: success_json
      else
        render json: failed_json, status: 422
      end
    end

    def destroy_comment_vote
      comment = find_comment
      ensure_can_see_comment!(comment)

      if !QuestionAnswerVote.exists?(votable: comment, user: current_user)
        raise Discourse::InvalidAccess.new(
                nil,
                nil,
                custom_message: "vote.error.user_has_not_voted",
              )
      end

      if PostVoting::VoteManager.remove_vote(comment, current_user)
        render json: success_json
      else
        render json: failed_json, status: 422
      end
    end

    VOTERS_LIMIT = 20

    def voters
      # TODO: Probably a site setting to hide/show voters
      voters =
        User
          .joins(:question_answer_votes)
          .where(question_answer_votes: { votable_id: @post.id, votable_type: "Post" })
          .order("question_answer_votes.created_at DESC")
          .select("users.*", "question_answer_votes.direction")
          .limit(VOTERS_LIMIT)

      render_json_dump(voters: serialize_data(voters, BasicVoterSerializer))
    end

    private

    def vote_params
      params.permit(:post_id, :comment_id, :direction)
    end

    def find_vote_post
      if params[:vote].present?
        post_id = vote_params[:post_id]
      else
        params.require(:post_id)
        post_id = params[:post_id]
      end

      @post = Post.find_by(id: post_id)

      raise Discourse::NotFound unless @post
    end

    def ensure_can_see_post
      @guardian.ensure_can_see!(@post)
    end

    def ensure_post_voting_enabled
      raise Discourse::InvalidAccess.new unless @post.is_post_voting_topic?
    end

    def find_comment
      comment = QuestionAnswerComment.find_by(id: vote_params[:comment_id])
      raise Discourse::NotFound if comment.blank?
      comment
    end

    def ensure_can_see_comment!(comment)
      @guardian.ensure_can_see!(comment.post)
    end

    def ensure_can_vote(votable)
      raiseError("post.post_voting.errors.vote_archived_topic") if votable.topic.archived?

      raiseError("post.post_voting.errors.vote_closed_topic") if votable.topic.closed?

      if votable.user_id == current_user.id
        raiseError("post.post_voting.errors.self_voting_not_permitted")
      end

      if votable.class.name == "Post"
        direction = vote_params[:direction] || QuestionAnswerVote.directions[:up]
        if QuestionAnswerVote.exists?(
             votable: votable,
             user_id: current_user.id,
             direction: direction,
           )
          raiseError("vote.error.one_vote_per_post")
        elsif !PostVoting::VoteManager.can_undo(votable, current_user)
          raiseError(
            "vote.error.undo_vote_action_window",
            { count: SiteSetting.post_voting_undo_vote_action_window.to_i },
          )
        end

        if votable.class.name == "QuestionAnswerComment" &&
             QuestionAnswerVote.exists?(votable: votable, user: current_user)
          raiseError("vote.error.one_vote_per_comment")
        end
      end
    end

    private

    def raiseError(error_message, error_message_params = nil)
      raise Discourse::InvalidAccess.new(
              nil,
              nil,
              custom_message: error_message,
              custom_message_params: error_message_params,
            )
    end
  end
end
