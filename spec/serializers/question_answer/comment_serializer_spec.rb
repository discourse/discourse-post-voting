# frozen_string_literal: true

require "rails_helper"

describe QuestionAnswerCommentSerializer do
  fab!(:topic) { Fabricate(:topic, subtype: Topic::POST_VOTING_SUBTYPE) }
  fab!(:post) { Fabricate(:post, topic: topic) }
  fab!(:user) { Fabricate(:user) }
  fab!(:comment) { Fabricate(:post_voting_comment, post: post) }

  before do
    SiteSetting.qa_enabled = true
    PostVoting::VoteManager.vote(comment, post.user)
  end

  it "returns the right attributes for an anonymous user" do
    serializer = described_class.new(comment, scope: Guardian.new)
    serilized_comment = serializer.as_json[:question_answer_comment]

    expect(serilized_comment[:id]).to eq(comment.id)
    expect(serilized_comment[:created_at]).to eq_time(comment.created_at)
    expect(serilized_comment[:post_voting_vote_count]).to eq(1)
    expect(serilized_comment[:cooked]).to eq(comment.cooked)
    expect(serilized_comment[:name]).to eq(comment.user.name)
    expect(serilized_comment[:username]).to eq(comment.user.username)
  end

  it "returns the right attributes for logged in user" do
    serializer = described_class.new(comment, scope: Guardian.new(post.user))
    serilized_comment = serializer.as_json[:question_answer_comment]

    expect(serilized_comment[:id]).to eq(comment.id)
    expect(serilized_comment[:created_at]).to eq_time(comment.created_at)
    expect(serilized_comment[:post_voting_vote_count]).to eq(1)
    expect(serilized_comment[:cooked]).to eq(comment.cooked)
    expect(serilized_comment[:name]).to eq(comment.user.name)
    expect(serilized_comment[:username]).to eq(comment.user.username)
    expect(serilized_comment[:user_voted]).to eq(true)
  end
end
