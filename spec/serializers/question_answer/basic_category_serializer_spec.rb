# frozen_string_literal: true

require 'rails_helper'

describe BasicCategorySerializer do
  fab!(:category) { Fabricate(:category) }

  let(:serialized) do
    serializer = BasicCategorySerializer.new(category, root: false)
    serializer.as_json
  end

  before do
    category.custom_fields[QuestionAnswer::CREATE_AS_QA_DEFAULT] = true
    category.save_custom_fields(true)
  end

  context 'qa enabled' do
    before do
      SiteSetting.qa_enabled = true
    end

    it 'should return qa category attributes' do
      expect(serialized[:create_as_qa_default]).to eq(true)
    end
  end

  context 'qa disabled' do
    before do
      SiteSetting.qa_enabled = false
    end

    it 'should not return qa category attributes' do
      expect(serialized.key?(:create_as_qa_default)).to eq(false)
    end
  end
end
