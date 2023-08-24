# frozen_string_literal: true

RSpec.describe "Post voting settings", type: :system do
  fab!(:admin) { Fabricate(:admin) }

  fab!(:category) { Fabricate(:category, name: "votvot", slug: "votvot") }

  let(:site_settings_page) { PageObjects::Pages::AdminSettings.new }
  let(:category_page) { PageObjects::Pages::Category.new }
  let(:composer) { PageObjects::Components::Composer.new }

  it "ensures topic creation is compliant to post voting site setting" do
    SiteSetting.post_voting_enabled = false

    sign_in(admin)

    page.visit("/latest")
    find("#create-topic").click

    composer.open_composer_actions.has_no_css?(composer.action("Toggle Post Voting"))
    composer.close

    site_settings_page.visit_category("plugins").toggle_setting("post_voting_enabled")

    page.visit("/latest")
    find("#create-topic").click

    composer.open_composer_actions.select_action("Toggle Post Voting")
    expect(composer.button_label).to have_content("Create post voting topic")
  end

  it "automatically creates post voting topic for category" do
    SiteSetting.post_voting_enabled = true

    sign_in(admin)

    category_page.visit(category).new_topic_button.click

    expect(composer.button_label).to have_content("Create Topic")
    composer.close

    category_page.visit_settings(category)
    find("#create-as-post-voting-default").click
    category_page.save_settings

    # reload category page to ensure settings are saved
    find("#site-logo").click

    category_page.visit(category).new_topic_button.click

    expect(composer.button_label).to have_content("Create post voting topic")
  end
end
