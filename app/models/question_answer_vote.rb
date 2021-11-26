# frozen_string_literal: true

class QuestionAnswerVote < ActiveRecord::Base
  belongs_to :post
  belongs_to :user

  validates :direction, inclusion: { in: ['up', 'down'] }
  validates :post_id, presence: true
  validates :user_id, presence: true

  def self.directions
    @directions ||= {
      up: 'up',
      down: 'down'
    }
  end
end
