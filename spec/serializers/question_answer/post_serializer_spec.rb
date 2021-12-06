# frozen_string_literal: true

require 'rails_helper'

describe QuestionAnswer::PostSerializerExtension do
  fab!(:user) { Fabricate(:user) }
  fab!(:category) { Fabricate(:category) }
  fab!(:topic) { Fabricate(:topic, category: category) }
  fab!(:post) { Fabricate(:post, topic: topic) }
  let(:up) { QuestionAnswerVote.directions[:up] }

  let(:guardian) { Guardian.new(user) }
  let(:vote) do
    ->(u) do
      QuestionAnswer::VoteManager.vote(post, u, direction: up)
    end
  end
  let(:undo_vote) do
    ->(u) do
      QuestionAnswer::VoteManager.remove_vote(post, u)
    end
  end
  let(:create_serializer) do
    ->(g = guardian) do
      PostSerializer.new(
        post,
        scope: g,
        root: false
      ).as_json
    end
  end

  let(:dependent_keys) do
    %i[last_answerer last_answered_at answer_count last_answer_post_number]
  end

  context 'qa enabled' do
    before do
      category.custom_fields['qa_enabled'] = true
      category.save!
      category.reload
    end

    it 'should qa_enabled' do
      serializer = create_serializer.call

      expect(serializer[:qa_enabled]).to eq(true)
    end

    it 'should return correct value from post' do
      QuestionAnswer::VoteManager.vote(post, user, direction: up)

      serialized = PostSerializer.new(post, scope: guardian, root: false).as_json

      expect(serialized[:qa_vote_count]).to eq(1)
      expect(serialized[:qa_enabled]).to eq(true)
    end
  end

  context 'qa disabled' do
    it 'should not qa_enabled' do
      serializer = create_serializer.call

      expect(serializer[:qa_enabled]).to eq(false)
    end

    it 'should not include dependent_keys' do
      dependent_keys.each do |k|
        expect(create_serializer.call.has_key?(k)).to eq(false)
      end
    end
  end
end
