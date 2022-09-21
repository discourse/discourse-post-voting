# frozen_string_literal: true

describe PostsController do
  fab!(:user) { Fabricate(:user) }

  describe '#create' do
    before do
      sign_in(user)
      SiteSetting.upvotes_enabled = true
    end

    it "creates a topic with the right subtype when create_as_upvotes param is provided" do
      post "/posts.json", params: {
        raw: 'this is some raw',
        title: 'this is some title',
        create_as_upvotes: true,
      }

      expect(response.status).to eq(200)

      topic = Topic.last

      expect(topic.is_upvotes?).to eq(true)
    end

    it "ignores create_as_upvotes param when trying to create private message" do
      post "/posts.json", params: {
        raw: 'this is some raw',
        title: 'this is some title',
        create_as_upvotes: true,
        archetype: Archetype.private_message,
        target_recipients: user.username
      }

      expect(response.status).to eq(200)

      topic = Topic.last

      expect(topic.is_upvotes?).to eq(false)
    end
  end
end
