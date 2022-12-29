# frozen_string_literal: true

Fabricator(:post_voting_vote, class_name: :question_answer_vote) do
  user
  votable(fabricator: :post)
  direction "up"
end
