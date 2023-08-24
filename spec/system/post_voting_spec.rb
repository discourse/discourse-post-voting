# frozen_string_literal: true

RSpec.describe "Post voting", type: :system do
  fab!(:admin) { Fabricate(:admin) }
  fab!(:user1) { Fabricate(:user) }
  fab!(:user2) { Fabricate(:user) }

  let(:topic_page) { PageObjects::Pages::PostVotingTopic.new }
  let(:composer) { PageObjects::Components::Composer.new }
  let(:topic_list) { PageObjects::Components::TopicList.new }

  it "allows voting" do
    SiteSetting.post_voting_enabled = true

    sign_in(user1)

    page.visit("/latest")
    find("#create-topic").click

    composer
      .open_composer_actions
      .select_action("Toggle Post Voting")
      .fill_title("The best kitty... in the world")
      .fill_content("I think it is tomtom. But I'm also open to other opinions")
      .create

    # so it seems like topic creation is taking way longer than the
    # default max wait time.
    # it doesn't look to be a performance issue, though

    try_until_success(frequency: 0.1) { expect(topic_page.post_vote_count(1)).to have_content("0") }

    topic_page.click_add_comment(1).fill_comment(1, "who am I kidding lol").click_submit_comment(1)

    expect(topic_page.find_comment(1, 1)).to have_content("who am I kidding lol")

    sign_in(user2)
    page.visit("/latest")
    topic_list.visit_topic_with_title("The best kitty… in the world")

    topic_page.click_footer_reply
    composer.fill_content("I think it is steak. He's the chonkiest boi therefore the best").create

    topic_page.upvote(2)
  end
end
