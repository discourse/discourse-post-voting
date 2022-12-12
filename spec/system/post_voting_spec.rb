# frozen_string_literal: true

RSpec.describe 'Post Voting', type: :system, js: true do
  fab!(:user) { Fabricate(:user) }
  fab!(:admin) { Fabricate(:admin) }
  fab!(:category1) { Fabricate(:category) }
  fab!(:category2) { Fabricate(:category) }
  fab!(:topic1) { Fabricate(:topic, category: category1) }
  fab!(:topic2) { Fabricate(:topic, category: category1) }
  fab!(:topic3) { Fabricate(:topic, category: category2) }
  fab!(:post1) { Fabricate(:post, topic: topic1) }
  fab!(:post2) { Fabricate(:post, topic: topic2) }
  fab!(:category_page) { PageObjects::Pages::Category.new }
  fab!(:topic_page) { PageObjects::Pages::Topic.new }
  fab!(:user_page) { PageObjects::Pages::User.new }
  fab!(:admin_page) { PageObjects::Pages::AdminSettings.new }

  fab!(:composer) { PageObjects::Components::Composer.new }
  fab!(:topic_list) { PageObjects::Components::TopicList.new }

  before do
    SiteSetting.qa_enabled = false

    admin.activate
    user.activate

    sign_in(admin)
  end

  it 'enables post voting and creates a post-voting topic' do
    # cannot create post voting topic
    composer
      .open_new_topic
      .open_composer_actions
    expect(composer).to have_no_css(composer.action("Toggle Post Voting"))

    # enable post voting
    admin_page
      .visit_filtered_plugin_setting('plugin%3Adiscourse-post-voting')
      .toggle_setting('qa_enabled', 'Enable Post Voting Plugin')

    # create post voting topic
    composer
      .open_new_topic
      .open_composer_actions
      .select_action("Toggle Post Voting")
    expect(composer.button_label).to have_text("Create post voting topic")
    composer
      .fill_title("The best cat in the world")
      .fill_content("Who's the best cat in the world?")
      .create

    sign_out

    sign_in(user)

    topic_list.visit_topic_with_title("The best cat in the world")

    # formatted as post voting topic
    expect(topic_page).to have_css(".post-voting-topic")
    expect(topic_page).to have_css(".post-menu-area .post-controls button[title='like this post']")
  end
end
