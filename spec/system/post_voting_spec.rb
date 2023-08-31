# frozen_string_literal: true

RSpec.describe "Post voting", type: :system do
  fab!(:admin) { Fabricate(:admin) }
  fab!(:user1) { Fabricate(:user) }
  fab!(:user2) { Fabricate(:user) }

  let(:topic_page) { PageObjects::Pages::PostVotingTopic.new }

  it "disallows voting on archived or closed topics" do
    SiteSetting.post_voting_enabled = true
    topic = Fabricate(:topic, subtype: Topic::POST_VOTING_SUBTYPE, user: user2, archived: true)
    Fabricate(:post, topic: topic, post_number: 2)
    post = Fabricate(:post, topic: topic, post_number: 3)
    Fabricate(:post_voting_comment, post: post, user: user1)

    sign_in(user1)

    topic_page.visit_topic(topic)

    expect(page).to have_css(PageObjects::Pages::PostVotingTopic::POST_VOTE_BUTTON, count: 4)
    expect(page).to have_css(
      "#{PageObjects::Pages::PostVotingTopic::POST_VOTE_BUTTON}.disabled",
      count: 4,
    )
    expect(page).to have_css("#{PageObjects::Pages::PostVotingTopic::COMMENT_VOTE_BUTTON}.disabled")
  end
end
