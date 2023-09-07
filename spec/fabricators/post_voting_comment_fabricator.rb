# frozen_string_literal: true

Fabricator(:post_voting_comment) do
  user
  post
  raw "Hello world"
end
