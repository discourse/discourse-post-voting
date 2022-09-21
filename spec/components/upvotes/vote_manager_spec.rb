# frozen_string_literal: true

require 'rails_helper'

describe Upvotes::VoteManager do
  fab!(:user)  { Fabricate(:user) }
  fab!(:user_2)  { Fabricate(:user) }
  fab!(:user_3)  { Fabricate(:user) }
  fab!(:topic) { Fabricate(:topic, subtype: Topic::UPVOTES_SUBTYPE) }
  fab!(:topic_post) { Fabricate(:post, topic: topic) }
  fab!(:post)  { Fabricate(:post, topic: topic) }
  fab!(:up) { QuestionAnswerVote.directions[:up] }
  fab!(:down) { QuestionAnswerVote.directions[:down] }

  before do
    SiteSetting.upvotes_enabled = true
  end

  describe '.vote' do
    it 'can create an upvote' do
      message = MessageBus.track_publish("/topic/#{post.topic_id}") do
        Upvotes::VoteManager.vote(post, user, direction: up)
      end.first

      expect(QuestionAnswerVote.exists?(votable: post, user: user, direction: up))
        .to eq(true)

      expect(post.qa_vote_count).to eq(1)

      expect(message.data[:id]).to eq(post.id)
      expect(message.data[:upvotes_user_voted_id]).to eq(user.id)
      expect(message.data[:upvotes_vote_count]).to eq(1)
      expect(message.data[:upvotes_user_voted_direction]).to eq(up)
      expect(message.data[:upvotes_has_votes]).to eq(true)
    end

    it 'can create a downvote' do
      message = MessageBus.track_publish("/topic/#{post.topic_id}") do
        Upvotes::VoteManager.vote(post, user, direction: down)
      end.first

      expect(QuestionAnswerVote.exists?(votable: post, user: user, direction: down))
        .to eq(true)

      expect(post.qa_vote_count).to eq(-1)

      expect(message.data[:id]).to eq(post.id)
      expect(message.data[:upvotes_user_voted_id]).to eq(user.id)
      expect(message.data[:upvotes_vote_count]).to eq(-1)
      expect(message.data[:upvotes_user_voted_direction]).to eq(down)
      expect(message.data[:upvotes_has_votes]).to eq(true)
    end

    it 'can change an upvote to a downvote' do
      Upvotes::VoteManager.vote(post, user, direction: up)
      Upvotes::VoteManager.vote(post, user_2, direction: up)
      Upvotes::VoteManager.vote(post, user, direction: down)

      expect(post.qa_vote_count).to eq(0)
    end

    it 'can change a downvote to upvote' do
      Upvotes::VoteManager.vote(post, user, direction: down)
      Upvotes::VoteManager.vote(post, user_2, direction: down)
      Upvotes::VoteManager.vote(post, user_3, direction: down)
      Upvotes::VoteManager.vote(post, user, direction: up)

      expect(post.qa_vote_count).to eq(-1)
    end
  end

  describe '.remove_vote' do
    it "should remove a user's upvote" do
      vote = Upvotes::VoteManager.vote(post, user, direction: up)

      message = MessageBus.track_publish("/topic/#{post.topic_id}") do
        Upvotes::VoteManager.remove_vote(vote.votable, vote.user)
      end.first

      expect(QuestionAnswerVote.exists?(id: vote.id)).to eq(false)
      expect(vote.votable.qa_vote_count).to eq(0)

      expect(message.data[:id]).to eq(post.id)
      expect(message.data[:upvotes_user_voted_id]).to eq(user.id)
      expect(message.data[:upvotes_vote_count]).to eq(0)
      expect(message.data[:upvotes_user_voted_direction]).to eq(nil)
      expect(message.data[:upvotes_has_votes]).to eq(false)
    end

    it "should remove a user's downvote" do
      vote = Upvotes::VoteManager.vote(post, Fabricate(:user), direction: up)
      vote_2 = Upvotes::VoteManager.vote(post, Fabricate(:user), direction: up)
      vote_3 = Upvotes::VoteManager.vote(post, user, direction: down)

      message = MessageBus.track_publish("/topic/#{post.topic_id}") do
        expect do
          Upvotes::VoteManager.remove_vote(post, user)
        end.to change { vote.votable.reload.qa_vote_count }.from(1).to(2)
      end.first

      expect(QuestionAnswerVote.exists?(id: vote_3.id)).to eq(false)
    end
  end
end
