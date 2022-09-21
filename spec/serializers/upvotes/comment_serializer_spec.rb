# frozen_string_literal: true

require 'rails_helper'

describe QuestionAnswerCommentSerializer do
  fab!(:topic) { Fabricate(:topic, subtype: Topic::UPVOTES_SUBTYPE) }
  fab!(:post) { Fabricate(:post, topic: topic) }
  fab!(:user) { Fabricate(:user) }
  fab!(:upvotes_comment) { Fabricate(:upvotes_comment, post: post) }

  before do
    SiteSetting.upvotes_enabled = true
    Upvotes::VoteManager.vote(upvotes_comment, post.user)
  end

  it 'returns the right attributes for an anonymous user' do
    serializer = described_class.new(upvotes_comment, scope: Guardian.new)
    serilized_comment = serializer.as_json[:question_answer_comment]

    expect(serilized_comment[:id]).to eq(upvotes_comment.id)
    expect(serilized_comment[:created_at]).to eq_time(upvotes_comment.created_at)
    expect(serilized_comment[:upvotes_vote_count]).to eq(1)
    expect(serilized_comment[:cooked]).to eq(upvotes_comment.cooked)
    expect(serilized_comment[:name]).to eq(upvotes_comment.user.name)
    expect(serilized_comment[:username]).to eq(upvotes_comment.user.username)
  end

  it "returns the right attributes for logged in user" do
    serializer = described_class.new(upvotes_comment, scope: Guardian.new(post.user))
    serilized_comment = serializer.as_json[:question_answer_comment]

    expect(serilized_comment[:id]).to eq(upvotes_comment.id)
    expect(serilized_comment[:created_at]).to eq_time(upvotes_comment.created_at)
    expect(serilized_comment[:upvotes_vote_count]).to eq(1)
    expect(serilized_comment[:cooked]).to eq(upvotes_comment.cooked)
    expect(serilized_comment[:name]).to eq(upvotes_comment.user.name)
    expect(serilized_comment[:username]).to eq(upvotes_comment.user.username)
    expect(serilized_comment[:user_voted]).to eq(true)
  end
end
