# frozen_string_literal: true

require 'rails_helper'

describe Jobs::UpdateTopicPostOrder do
  fab!(:category) { Fabricate(:category) }
  fab!(:topic) { Fabricate(:topic, category: category) }
  fab!(:post1) { Fabricate(:post, topic: topic, post_number: 1) }
  fab!(:post2) { Fabricate(:post, topic: topic, post_number: 2) }
  fab!(:post3) { Fabricate(:post, topic: topic, post_number: 3) }
  fab!(:post4) { Fabricate(:post, topic: topic, post_number: 4, reply_to_post_number: 2) }

  it "when qa is enabled it sets topics post sort order as qa order" do
    category.custom_fields['qa_enabled'] = true
    category.save_custom_fields(true)

    Jobs::UpdateCategoryPostOrder.new.execute(category_id: category.id)

    expect(post1.reload.sort_order).to eq(1)
    expect(post2.reload.sort_order).to eq(2)
    expect(post3.reload.sort_order).to eq(4)
    expect(post4.reload.sort_order).to eq(3)
  end

  it "when qa is disabled it sets topics post sort order as post number" do
    Jobs::UpdateCategoryPostOrder.new.execute(category_id: category.id)

    expect(post1.reload.sort_order).to eq(1)
    expect(post2.reload.sort_order).to eq(2)
    expect(post3.reload.sort_order).to eq(3)
    expect(post4.reload.sort_order).to eq(4)
  end
end
