# frozen_string_literal: true

require 'rails_helper'

describe QuestionAnswerVote do
  fab!(:post) { Fabricate(:post) }
  fab!(:user) { Fabricate(:user) }

  describe '#direction' do
    it 'ensures inclusion of values' do
      qa_vote = QuestionAnswerVote.new(post: post, user: user)

      qa_vote.direction = 'up'

      expect(qa_vote.valid?).to eq(true)

      qa_vote.direction = 'down'

      expect(qa_vote.valid?).to eq(true)

      qa_vote.direction = 'somethingelse'

      expect(qa_vote.valid?).to eq(false)
    end
  end
end
