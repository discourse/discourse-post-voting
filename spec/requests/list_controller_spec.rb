# frozen_string_literal: true

require 'rails_helper'

describe ListController do
  fab!(:user) { Fabricate(:user) }
  fab!(:category) { Fabricate(:category) }
  fab!(:upvotes_topic) { Fabricate(:topic, category: category, subtype: Topic::UPVOTES_SUBTYPE) }
  fab!(:upvotes_topic_post) { Fabricate(:post, topic: upvotes_topic) }
  fab!(:upvotes_topic_answer) { create_post(topic: upvotes_topic, reply_to_post: nil) }
  fab!(:topic) { Fabricate(:topic) }

  before do
    SiteSetting.upvotes_enabled = true
    sign_in(user)
  end

  it 'should return the right attributes for Q&A topics' do
    TopicUser.create!(user: user, topic: upvotes_topic, last_read_post_number: 2)
    TopicUser.create!(user: user, topic: topic, last_read_post_number: 2)

    get "/latest.json"

    expect(response.status).to eq(200)

    topics = response.parsed_body["topic_list"]["topics"]

    upvotes = topics.find { |t| t["id"] == upvotes_topic.id }
    non_upvotes = topics.find { |t| t["id"] == topic.id }

    expect(upvotes["is_upvotes"]).to eq(true)
    expect(non_upvotes["is_upvotes"]).to eq(nil)
  end

  it 'should return the right attributes when Q&A is disabled' do
    SiteSetting.upvotes_enabled = false

    TopicUser.create!(user: user, topic: upvotes_topic, last_read_post_number: 2)
    TopicUser.create!(user: user, topic: topic, last_read_post_number: 2)

    get "/latest.json"

    expect(response.status).to eq(200)

    topics = response.parsed_body["topic_list"]["topics"]

    upvotes = topics.find { |t| t["id"] == upvotes_topic.id }
    non_upvotes = topics.find { |t| t["id"] == topic.id }

    expect(upvotes["is_upvotes"]).to eq(nil)
    expect(non_upvotes["is_upvotes"]).to eq(nil)
  end
end
