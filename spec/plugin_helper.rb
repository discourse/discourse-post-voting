# frozen_string_literal: true

RSpec.configure do |config|
  # this is so that fabricators can fabricate
  # since the creation of some models require
  # the plugin to be turned on
  SiteSetting.post_voting_enabled = true

  config.before(:suite) do
    if defined?(migrate_column_to_bigint)
      migrate_column_to_bigint(PostVotingCommentCustomField, :post_voting_comment_id)
      migrate_column_to_bigint(PostVotingVote, :votable_id)
    end
  end
end
