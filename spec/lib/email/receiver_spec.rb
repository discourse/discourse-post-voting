# frozen_string_literal: true

require "email/receiver"

RSpec.describe Email::Receiver do
  before do
    SiteSetting.email_in = true
    SiteSetting.reply_by_email_address = "reply+%{reply_key}@bar.com"
    SiteSetting.alternative_reply_by_email_addresses = "alt+%{reply_key}@bar.com"
  end

  def process(email_name, opts = {})
    Email::Receiver.new(email(email_name), opts).process!
  end

  describe "reply" do
    let(:reply_key) { "4f97315cc828096c9cb34c6f1a0d6fe8" }
    fab!(:category) { Fabricate(:category) }
    fab!(:user) { Fabricate(:user, email: "discourse@bar.com") }
    fab!(:topic) { create_topic(category: category, user: user, subtype: Topic::POST_VOTING_SUBTYPE) }
    fab!(:post) { create_post(topic: topic) }

    before do
      Fabricate(:post_reply_key,
                reply_key: reply_key,
                user: user,
                post: post)
    end

    it "creates a new reply post" do
      handler_calls = 0
      handler = proc { |_| handler_calls += 1 }

      DiscourseEvent.on(:topic_created, &handler)

      expect { process(:html_reply) }.to change { topic.posts.count }
      last_post = topic.posts.last
      expect(last_post.raw).to eq("This is a **HTML** reply ;)")
      expect(last_post.reply_to_post_number).to be_nil

      DiscourseEvent.off(:topic_created, &handler)
      expect(handler_calls).to eq(0)
    end
  end
end
