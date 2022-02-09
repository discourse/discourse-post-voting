# frozen_string_literal: true

QuestionAnswer::Engine.routes.draw do
  resource :vote
  get 'voters' => 'votes#voters'
  post 'set_as_answer' => 'votes#set_as_answer'
  post 'vote/comment' => 'votes#create_comment_vote'
  delete 'vote/comment' => 'votes#destroy_comment_vote'

  get "comments" => 'comments#load_more_comments'
  post "comments" => 'comments#create'
  delete "comments" => 'comments#destroy'
  put "comments" => 'comments#update'
end

Discourse::Application.routes.append do
  mount ::QuestionAnswer::Engine, at: 'qa'
end
