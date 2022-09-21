# frozen_string_literal: true

require 'rails_helper'

describe QuestionAnswerVote do
  fab!(:topic) { Fabricate(:topic, subtype: Topic::UPVOTES_SUBTYPE) }
  fab!(:topic_post) { Fabricate(:post, topic: topic) }
  fab!(:post) { Fabricate(:post, topic: topic) }
  fab!(:user) { Fabricate(:user) }
  fab!(:post_1) { Fabricate(:post, topic: topic, user: user) }
  fab!(:tag) { Fabricate(:tag) }

  before do
    SiteSetting.upvotes_enabled = true
  end

  context 'validations' do
    context 'posts' do
      it 'ensures votes cannot be created when QnA is disabled' do
        SiteSetting.upvotes_enabled = false

        upvotes_vote = QuestionAnswerVote.new(votable: post, user: user, direction: QuestionAnswerVote.directions[:up])

        expect(upvotes_vote.valid?).to eq(false)

        expect(upvotes_vote.errors.full_messages).to contain_exactly(
          I18n.t("post.upvotes.errors.upvotes_not_enabled")
        )
      end

      it 'ensures that only posts in reply to other posts cannot be voted on' do
        post.update!(post_number: 2, reply_to_post_number: 1)

        upvotes_vote = QuestionAnswerVote.new(votable: post, user: user, direction: QuestionAnswerVote.directions[:up])

        expect(upvotes_vote.valid?).to eq(false)

        expect(upvotes_vote.errors.full_messages).to contain_exactly(
          I18n.t("post.upvotes.errors.voting_not_permitted")
        )
      end

      it 'ensures that votes can only be created for valid polymorphic types' do
        upvotes_vote = QuestionAnswerVote.new(votable: post.topic, user: user, direction: QuestionAnswerVote.directions[:up])

        expect(upvotes_vote.valid?).to eq(false)
        expect(upvotes_vote.errors[:votable_type].present?).to eq(true)
      end

      it 'ensures that self voting is not allowed' do
        upvotes_vote = QuestionAnswerVote.new(votable: post_1, user: user, direction: QuestionAnswerVote.directions[:up])

        expect(upvotes_vote.valid?).to eq(false)
        expect(upvotes_vote.errors.full_messages).to contain_exactly(
          I18n.t("post.upvotes.errors.self_voting_not_permitted")
        )
      end
    end

    context 'comments' do
      fab!(:upvotes_comment) { Fabricate(:upvotes_comment, post: post) }

      it 'ensures vote cannot be created on a comment when QnA is disabled' do
        SiteSetting.upvotes_enabled = false
        upvotes_comment.reload

        upvotes_vote = QuestionAnswerVote.new(votable: upvotes_comment, user: user, direction: QuestionAnswerVote.directions[:up])

        expect(upvotes_vote.valid?).to eq(false)

        expect(upvotes_vote.errors.full_messages).to contain_exactly(
          I18n.t("post.upvotes.errors.upvotes_not_enabled")
        )
      end

      it 'ensures vote cannot be created on a comment when it is a downvote' do
        upvotes_vote = QuestionAnswerVote.new(votable: upvotes_comment, user: user, direction: QuestionAnswerVote.directions[:down])

        expect(upvotes_vote.valid?).to eq(false)

        expect(upvotes_vote.errors.full_messages).to contain_exactly(
          I18n.t("post.upvotes.errors.comment_cannot_be_downvoted")
        )
      end
    end
  end

  describe '#direction' do
    it 'ensures inclusion of values' do
      upvotes_vote = QuestionAnswerVote.new(votable: post, user: user)

      upvotes_vote.direction = 'up'

      expect(upvotes_vote.valid?).to eq(true)

      upvotes_vote.direction = 'down'

      expect(upvotes_vote.valid?).to eq(true)

      upvotes_vote.direction = 'somethingelse'

      expect(upvotes_vote.valid?).to eq(false)
    end
  end
end
