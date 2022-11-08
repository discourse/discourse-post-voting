# frozen_string_literal: true

require 'rails_helper'

describe ListController do
  fab!(:user) { Fabricate(:user) }
  fab!(:category) { Fabricate(:category) }
  fab!(:post_voting_topic) { Fabricate(:topic, category: category, subtype: Topic::POST_VOTING_SUBTYPE) }
  fab!(:post_voting_topic_post) { Fabricate(:post, topic: post_voting_topic) }
  fab!(:post_voting_topic_answer) { create_post(topic: post_voting_topic, reply_to_post: nil) }
  fab!(:topic) { Fabricate(:topic) }

  before do
    SiteSetting.qa_enabled = true
    sign_in(user)
  end

  it 'should return the right attributes for Post Voting topics' do
    TopicUser.create!(user: user, topic: post_voting_topic, last_read_post_number: 2)
    TopicUser.create!(user: user, topic: topic, last_read_post_number: 2)

    get "/latest.json"

    expect(response.status).to eq(200)

    topics = response.parsed_body["topic_list"]["topics"]
    post_voting = topics.find { |t| t["id"] == post_voting_topic.id }
    non_post_voting = topics.find { |t| t["id"] == topic.id }

    expect(post_voting["is_post_voting"]).to eq(true)
    expect(non_post_voting["is_post_voting"]).to eq(nil)
  end

  it 'should return the right attributes when Post Voting is disabled' do
    SiteSetting.qa_enabled = false

    TopicUser.create!(user: user, topic: post_voting_topic, last_read_post_number: 2)
    TopicUser.create!(user: user, topic: topic, last_read_post_number: 2)

    get "/latest.json"

    expect(response.status).to eq(200)

    topics = response.parsed_body["topic_list"]["topics"]

    post_voting = topics.find { |t| t["id"] == post_voting_topic.id }
    non_post_voting = topics.find { |t| t["id"] == topic.id }

    expect(post_voting["is_post_voting"]).to eq(nil)
    expect(non_post_voting["is_post_voting"]).to eq(nil)
  end
end
