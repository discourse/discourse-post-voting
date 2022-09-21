# frozen_string_literal: true

require 'rails_helper'

describe BasicCategorySerializer do
  fab!(:category) { Fabricate(:category) }

  let(:serialized) do
    serializer = BasicCategorySerializer.new(category, root: false)
    serializer.as_json
  end

  before do
    category.custom_fields[Upvotes::CREATE_AS_UPVOTES_DEFAULT] = true
    category.save_custom_fields(true)
  end

  context 'upvotes enabled' do
    before do
      SiteSetting.upvotes_enabled = true
    end

    it 'should return upvotes category attributes' do
      expect(serialized[:create_as_upvotes_default]).to eq(true)
    end
  end

  context 'upvotes disabled' do
    before do
      SiteSetting.upvotes_enabled = false
    end

    it 'should not return upvotes category attributes' do
      expect(serialized.key?(:create_as_upvotes_default)).to eq(false)
    end
  end
end
