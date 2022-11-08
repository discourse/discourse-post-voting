# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PostVoting::VotesController do
  fab!(:user) { Fabricate(:user) }
  fab!(:topic) { Fabricate(:topic, subtype: Topic::QA_SUBTYPE) }
  fab!(:topic_post) { Fabricate(:post, topic: topic) }
  fab!(:answer) { Fabricate(:post, topic: topic) }
  fab!(:answer_2) { Fabricate(:post, topic: topic) }
  fab!(:answer_3) { Fabricate(:post, topic: topic, user: user) }

  fab!(:admin) { Fabricate(:admin) }
  fab!(:category) { Fabricate(:category) }

  before do
    SiteSetting.qa_enabled = true
  end

  describe '#create' do
    before { sign_in(user) }

    it 'returns the right response when user does not have access to post' do
      topic.update!(category: category)
      category.update!(read_restricted: true)

      post '/post_voting/vote.json', params: { post_id: answer.id }

      expect(response.status).to eq(403)
    end

    it 'should be successful if post has never been voted' do
      post '/post_voting/vote.json', params: { post_id: answer.id }

      expect(response.status).to eq(200)

      vote = answer.question_answer_votes.first

      expect(vote.votable_type).to eq('Post')
      expect(vote.votable_id).to eq(answer.id)
      expect(vote.user_id).to eq(user.id)
    end

    it 'should error if already voted' do
      post '/post_voting/vote.json', params: { post_id: answer.id }

      expect(response.status).to eq(200)

      post '/post_voting/vote.json', params: { post_id: answer.id }

      expect(response.status).to eq(403)
    end

    it 'should return 403 if user votes on a post by self' do
      post '/post_voting/vote.json', params: { post_id: answer_3.id }

      expect(response.status).to eq(403)
    end

    it 'should return 403 after qa_undo_vote_action_window' do
      SiteSetting.qa_undo_vote_action_window = 1

      post "/post_voting/vote.json", params: { post_id: answer.id }

      expect(response.status).to eq(200)

      freeze_time 2.minutes.from_now do
        post '/post_voting/vote.json', params: { post_id: answer.id, direction: QuestionAnswerVote.directions[:down] }

        expect(response.status).to eq(403)
        expect(JSON.parse(response.body)['errors'][0]).to eq(I18n.t('vote.error.undo_vote_action_window', count: 1))
      end
    end
  end

  describe '#destroy' do
    before { sign_in(user) }

    it 'should success if has voted' do
      post '/post_voting/vote.json', params: { post_id: answer.id }

      expect(response.status).to eq(200)

      vote = answer.question_answer_votes.first

      expect(vote.votable).to eq(answer)
      expect(vote.user_id).to eq(user.id)

      delete '/post_voting/vote.json', params: { post_id: answer.id }

      expect(response.status).to eq(200)
      expect(QuestionAnswerVote.exists?(id: vote.id)).to eq(false)
    end

    it 'should return the right response if user has never voted on post' do
      delete '/post_voting/vote.json', params: { post_id: answer.id }

      expect(response.status).to eq(403)
    end

    it 'should cant undo vote' do
      SiteSetting.qa_undo_vote_action_window = 1

      post "/post_voting/vote.json", params: { post_id: answer.id }

      expect(response.status).to eq(200)

      freeze_time 2.minutes.from_now do
        delete '/post_voting/vote.json', params: { post_id: answer.id }

        expect(response.status).to eq(403)
        expect(JSON.parse(response.body)['errors'][0]).to eq(I18n.t('vote.error.undo_vote_action_window', count: 1))
      end
    end
  end

  describe '#voters' do
    fab!(:user) { Fabricate(:user) }

    it 'should return the right response for an anon user' do
      get '/post_voting/voters.json', params: { post_id: answer.id }

      expect(response.status).to eq(403)
    end

    it 'should return the right response if post does not exist' do
      sign_in(user)

      get '/post_voting/voters.json', params: { post_id: -1 }

      expect(response.status).to eq(404)
    end

    it 'should return correct users respecting limits' do
      sign_in(user)

      user_2 = Fabricate(:user)
      Fabricate(:qa_vote, votable: answer, user: user_2, direction: QuestionAnswerVote.directions[:down])
      Fabricate(:qa_vote, votable: answer, user: user)
      Fabricate(:qa_vote, votable: answer_2, user: user)

      stub_const(PostVoting::VotesController, "VOTERS_LIMIT", 2) do
        get '/post_voting/voters.json', params: { post_id: answer.id }
      end

      expect(response.status).to eq(200)

      parsed = JSON.parse(response.body)
      voters = parsed['voters']

      expect(voters.map { |v| v['id'] }).to contain_exactly(user_2.id, user.id)

      expect(voters[0]['id']).to eq(user.id)
      expect(voters[0]['username']).to eq(user.username)
      expect(voters[0]['name']).to eq(user.name)
      expect(voters[0]['avatar_template']).to eq(user.avatar_template)
      expect(voters[0]['direction']).to eq(QuestionAnswerVote.directions[:up])

      expect(voters[1]['id']).to eq(user_2.id)
      expect(voters[1]['direction']).to eq(QuestionAnswerVote.directions[:down])
    end
  end

  describe '#create_comment_vote' do
    let(:comment) { Fabricate(:qa_comment, post: answer) }
    let(:comment_2) { Fabricate(:qa_comment, post: answer, user: user) }

    it 'should return 403 for an anon user' do
      post '/post_voting/vote/comment.json', params: { comment_id: comment.id }

      expect(response.status).to eq(403)
    end

    it 'should return 404 if comment_id param is not valid' do
      sign_in(user)

      post '/post_voting/vote/comment.json', params: { comment_id: -999 }

      expect(response.status).to eq(404)
    end

    it 'should return 403 if user is not allowed to see comment' do
      sign_in(user)

      topic.update!(category: category)
      category.update!(read_restricted: true)

      post '/post_voting/vote/comment.json', params: { comment_id: comment.id }

      expect(response.status).to eq(403)
    end

    it 'should return 403 if user votes on a comment by self' do
      sign_in(user)

      post '/post_voting/vote/comment.json', params: { comment_id: comment_2.id }

      expect(response.status).to eq(403)
    end

    it 'allows user to vote on a comment' do
      sign_in(user)

      expect do
        post '/post_voting/vote/comment.json', params: { comment_id: comment.id }

        expect(response.status).to eq(200)
      end.to change { comment.reload.votes.length }.from(0).to(1)

      expect(comment.qa_vote_count).to eq(1)
    end
  end

  describe '#destroy_comment_vote' do
    let(:comment) { Fabricate(:qa_comment, post: answer) }

    it 'should return 403 for an anon user' do
      delete '/post_voting/vote/comment.json', params: { comment_id: comment.id }

      expect(response.status).to eq(403)
    end

    it 'should return 404 if comment_id param is not valid' do
      sign_in(user)

      delete '/post_voting/vote/comment.json', params: { comment_id: -999 }

      expect(response.status).to eq(404)
    end

    it 'should return 403 if user has not voted on comment' do
      sign_in(user)

      delete '/post_voting/vote/comment.json', params: { comment_id: comment.id }

      expect(response.status).to eq(403)
    end

    it "should be able to remove a user's vote from a comment" do
      PostVoting::VoteManager.vote(comment, user, direction: QuestionAnswerVote.directions[:up])

      sign_in(user)

      expect do
        delete '/post_voting/vote/comment.json', params: { comment_id: comment.id }

        expect(response.status).to eq(200)
      end.to change { comment.reload.votes.length }.from(1).to(0)
    end
  end
end
