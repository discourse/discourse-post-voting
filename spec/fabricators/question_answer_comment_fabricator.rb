# frozen_string_literal: true

Fabricator(:post_voting_comment, class_name: :question_answer_comment) do
  user
  post
  raw "Hello world"
end
