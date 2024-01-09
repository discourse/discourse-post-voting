# frozen_string_literal: true

class PostVotingCommentCustomField < ActiveRecord::Base
  belongs_to :post_voting_comment
end

# == Schema Information
#
# Table name: post_voting_comment_custom_fields
#
#  id                        :integer          not null, primary key
#  post_voting_comment_id    :integer          not null
#  name                      :string(256)      not null
#  value                     :text
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
