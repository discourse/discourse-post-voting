# frozen_string_literal: true

require 'rails_helper'

describe QuestionAnswer::VoteManager do
  fab!(:user)  { Fabricate(:user) }
  fab!(:post)  { Fabricate(:post) }
  fab!(:up) { QuestionAnswerVote.directions[:up] }
  fab!(:down) { QuestionAnswerVote.directions[:down] }

  describe '.vote' do
    it 'can create an upvote' do
      QuestionAnswer::VoteManager.vote(post, user, direction: up)

      expect(QuestionAnswerVote.exists?(post: post, user: user, direction: up))
        .to eq(true)

      expect(post.qa_vote_count).to eq(1)
    end

    it 'can create a downvote' do
      QuestionAnswer::VoteManager.vote(post, user, direction: down)

      expect(QuestionAnswerVote.exists?(post: post, user: user, direction: down))
        .to eq(true)

      expect(post.qa_vote_count).to eq(-1)
    end
  end

  describe '.remove_vote' do
    it "should remove a user's upvote" do
      vote = QuestionAnswer::VoteManager.vote(post, user, direction: up)

      QuestionAnswer::VoteManager.remove_vote(vote.post, vote.user)

      expect(QuestionAnswerVote.exists?(id: vote.id)).to eq(false)
      expect(vote.post.qa_vote_count).to eq(0)
    end

    it "should remove a user's upvote" do
      vote = QuestionAnswer::VoteManager.vote(post, Fabricate(:user), direction: up)
      vote_2 = QuestionAnswer::VoteManager.vote(post, Fabricate(:user), direction: up)
      vote_3 = QuestionAnswer::VoteManager.vote(post, user, direction: down)

      expect do
        QuestionAnswer::VoteManager.remove_vote(post, user)
      end.to change { vote.post.reload.qa_vote_count }.from(1).to(2)

      expect(QuestionAnswerVote.exists?(id: vote_3.id)).to eq(false)
    end
  end
end