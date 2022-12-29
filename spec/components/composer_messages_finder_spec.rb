# frozen_string_literal: true

require "rails_helper"
require "composer_messages_finder"

describe ComposerMessagesFinder do
  describe ".check_sequential_replies" do
    fab!(:user) { Fabricate(:user) }
    fab!(:topic) { Fabricate(:topic) }
    fab!(:post_voting_topic) { Fabricate(:topic, subtype: Topic::POST_VOTING_SUBTYPE) }

    before do
      SiteSetting.educate_until_posts = 4
      SiteSetting.sequential_replies_threshold = 2

      5.times { Fabricate(:post, topic: topic, user: user) }
    end

    it "notify user about sequential replies for regular topics" do
      finder = ComposerMessagesFinder.new(user, composer_action: "reply", topic_id: topic.id)
      expect(finder.check_sequential_replies).to be_present
    end

    it "doesn't notify user about sequential replies for Post Voting topics" do
      finder =
        ComposerMessagesFinder.new(user, composer_action: "reply", topic_id: post_voting_topic.id)
      expect(finder.check_sequential_replies).to be_blank
    end
  end
end
